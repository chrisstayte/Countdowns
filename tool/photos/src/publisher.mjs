import { readFile, open, unlink } from 'node:fs/promises';
import path from 'node:path';
import { randomUUID } from 'node:crypto';
import { S3Client, GetObjectCommand, HeadObjectCommand, PutObjectCommand, ListObjectsV2Command, DeleteObjectCommand } from '@aws-sdk/client-s3';
import { BASE_URL, MANIFEST_KEY, MUTABLE_CACHE, IMMUTABLE_CACHE, atomicWrite, digest } from './catalogue.mjs';
import { isBlurhashValid } from 'blurhash';

const missing = error => error.name === 'NoSuchKey' || error.name === 'NotFound' || error.$metadata?.httpStatusCode === 404;
const conflict = error => error.name === 'PreconditionFailed' || error.$metadata?.httpStatusCode === 412;
const bodyBytes = async body => Buffer.from(await body.transformToByteArray());

export function remoteStore(env = process.env) {
  for (const name of ['R2_ENDPOINT', 'R2_ACCESS_KEY_ID', 'R2_SECRET_ACCESS_KEY', 'CF_API_TOKEN', 'CF_ZONE_ID']) {
    if (!env[name]) throw new Error(`Missing ${name}. Configure the private publisher environment file.`);
  }
  if (!/^https:\/\/[a-f0-9]{32}(?:\.(?:eu|us))?\.r2\.cloudflarestorage\.com\/?$/.test(env.R2_ENDPOINT)) throw new Error('R2_ENDPOINT must be an HTTPS Cloudflare R2 S3 endpoint.');
  if (!/^[a-f0-9]{32}$/.test(env.CF_ZONE_ID)) throw new Error('CF_ZONE_ID must be a Cloudflare zone ID.');
  const client = new S3Client({ region: 'auto', endpoint: env.R2_ENDPOINT, credentials: { accessKeyId: env.R2_ACCESS_KEY_ID, secretAccessKey: env.R2_SECRET_ACCESS_KEY }, requestChecksumCalculation: 'WHEN_REQUIRED', responseChecksumValidation: 'WHEN_REQUIRED' });
  const Bucket = 'countdowns-media';
  return {
    async get(key) {
      try { const result = await client.send(new GetObjectCommand({ Bucket, Key: key })); return { body: await bodyBytes(result.Body), etag: result.ETag }; }
      catch (error) { if (missing(error)) return null; throw error; }
    },
    async head(key) {
      try { return await client.send(new HeadObjectCommand({ Bucket, Key: key })); }
      catch (error) { if (missing(error)) return null; throw error; }
    },
    async put(key, body, { contentType, cacheControl, ifMatch, ifNoneMatch } = {}) {
      return client.send(new PutObjectCommand({ Bucket, Key: key, Body: body, ContentType: contentType, CacheControl: cacheControl, Metadata: { sha256: digest(body) }, ...(ifMatch ? { IfMatch: ifMatch } : {}), ...(ifNoneMatch ? { IfNoneMatch: ifNoneMatch } : {}) }));
    },
    async list(prefix) {
      const keys = [];
      let continuation;
      do {
        const result = await client.send(new ListObjectsV2Command({ Bucket, Prefix: prefix, ContinuationToken: continuation }));
        keys.push(...(result.Contents ?? []).map(o => o.Key));
        continuation = result.IsTruncated ? result.NextContinuationToken : undefined;
        if (result.IsTruncated && !continuation) throw new Error('R2 returned an incomplete object listing without a cursor.');
      } while (continuation);
      return keys;
    },
    async remove(key) { return client.send(new DeleteObjectCommand({ Bucket, Key: key })); },
    async purge(keys = [MANIFEST_KEY]) {
      if (keys.some(key => !/^(catalog|p)\/[a-zA-Z0-9_./-]+$/.test(key) || key.includes('..'))) throw new Error('Refusing to purge an unexpected object path.');
      const response = await fetch(`https://api.cloudflare.com/client/v4/zones/${env.CF_ZONE_ID}/purge_cache`, { method: 'POST', headers: { Authorization: `Bearer ${env.CF_API_TOKEN}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ files: keys.map(key => BASE_URL + key) }), signal: AbortSignal.timeout(30_000) });
      const data = await response.json();
      if (!response.ok || !data.success) throw new Error(`Cache purge failed (HTTP ${response.status}). Run photos purge after fixing purge credentials.`);
    },
  };
}

export function validateManifest(manifest) {
  if (manifest?.schema !== 1 || manifest.baseUrl !== BASE_URL || !Number.isInteger(manifest.version) || manifest.version < 0 || typeof manifest.enabled !== 'boolean' || !Array.isArray(manifest.photos)) throw new Error('Invalid schema-1 manifest.');
  const ids = new Set();
  for (const photo of manifest.photos) {
    if (!/^p_\d{4,}$/.test(photo.id) || ids.has(photo.id)) throw new Error('Invalid or duplicate photo ID in manifest.');
    ids.add(photo.id);
    if (![photo.w, photo.h].every(v => Number.isInteger(v) && v > 0 && v <= 2560)) throw new Error(`${photo.id}: invalid output dimensions.`);
    if (!/^#[a-fA-F0-9]{6}$/.test(photo.color) || !isBlurhashValid(photo.blurhash ?? '').result) throw new Error(`${photo.id}: missing valid color or BlurHash.`);
    if (Object.keys(photo.files ?? {}).sort().join(',') !== 'full,thumb') throw new Error(`${photo.id}: unexpected file variants.`);
    for (const [variant, extension] of [['thumb', 'thumb.webp'], ['full', 'full.jpg']]) {
      const key = photo.files?.[variant];
      if (typeof key !== 'string' || !new RegExp(`^p/${photo.id}/[a-f0-9]{8}\\.${extension.replaceAll('.', '\\.')}$`).test(key)) throw new Error(`${photo.id}: invalid ${variant} path.`);
    }
  }
  return manifest;
}

async function currentManifest(store) {
  const current = await store.get(MANIFEST_KEY);
  if (!current) return { manifest: null, etag: null };
  const manifest = JSON.parse(current.body.toString());
  if (manifest.schema !== 1 || !Number.isInteger(manifest.version) || !current.etag) throw new Error('The remote manifest is invalid; refusing to overwrite it.');
  return { manifest, etag: current.etag };
}

async function nextVersion(store, current) {
  const snapshots = await store.list('catalog/v1/manifest-');
  const versions = snapshots.map(key => Number(/^catalog\/v1\/manifest-(\d+)\.json$/.exec(key)?.[1]) || 0);
  const version = versions.reduce((max, value) => Math.max(max, value), current?.version ?? 0) + 1;
  if (!Number.isSafeInteger(version)) throw new Error('Catalog version exceeds the safe integer range.');
  return version;
}

async function withLock(root, action) {
  const file = path.join(root, '.publish.lock');
  let handle;
  try { handle = await open(file, 'wx', 0o600); }
  catch (error) { if (error.code === 'EEXIST') throw new Error('Another publish is running. If a prior process crashed, confirm it stopped before removing .publish.lock from the private media folder.'); throw error; }
  try { await handle.writeFile(JSON.stringify({ pid: process.pid, startedAt: new Date().toISOString() })); return await action(); }
  finally { await handle.close(); await unlink(file); }
}

export async function publish(root, manifest, store, { dryRun = false, log = console.log } = {}) {
  validateManifest(manifest);
  if (manifest.enabled && !manifest.photos.some(p => !p.hidden)) throw new Error('An enabled catalog must have a visible photo. Set enabled: false for an empty catalog.');
  const action = async () => {
    const current = await currentManifest(store);
    const version = await nextVersion(store, current.manifest);
    const candidate = { ...manifest, version, generatedAt: new Date().toISOString() };
    const files = [];
    for (const photo of candidate.photos) for (const [variant, key] of Object.entries(photo.files)) {
      const body = await readFile(path.join(root, 'build', key));
      if (!digest(body).startsWith(path.basename(key).split('.')[0])) throw new Error(`Output file changed after build: ${key}. Rebuild first.`);
      const contentType = variant === 'thumb' ? 'image/webp' : 'image/jpeg';
      const existing = await store.head(key);
      if (existing) {
        if (existing.ContentLength !== body.length) throw new Error(`Immutable object collision: ${key}.`);
        const remoteDigest = existing.Metadata?.sha256 ?? digest((await store.get(key)).body);
        if (remoteDigest !== digest(body) || existing.CacheControl !== IMMUTABLE_CACHE || existing.ContentType !== contentType) throw new Error(`Existing immutable object differs: ${key}.`);
      } else files.push({ key, body, contentType });
    }
    log(`${dryRun ? 'DRY RUN: ' : ''}version ${version}: ${files.length} new files, ${candidate.photos.length} photos; publish snapshot, update manifest, purge manifest URL.`);
    if (dryRun) return candidate;
    for (const file of files) {
      try { await store.put(file.key, file.body, { contentType: file.contentType, cacheControl: IMMUTABLE_CACHE, ifNoneMatch: '*' }); }
      catch (error) { if (conflict(error)) throw new Error(`A concurrent uploader created ${file.key}; rerun publish to verify it.`); throw error; }
    }
    const body = Buffer.from(JSON.stringify(candidate, null, 2) + '\n');
    try {
      await store.put(`catalog/v1/manifest-${version}.json`, body, { contentType: 'application/json; charset=utf-8', cacheControl: IMMUTABLE_CACHE, ifNoneMatch: '*' });
      await store.put(MANIFEST_KEY, body, { contentType: 'application/json; charset=utf-8', cacheControl: MUTABLE_CACHE, ...(current.etag ? { ifMatch: current.etag } : { ifNoneMatch: '*' }) });
    } catch (error) { if (conflict(error)) throw new Error('A concurrent publish won. Reserved snapshots stay in place; rerun publish.'); throw error; }
    await atomicWrite(path.join(root, 'build', 'last-published.json'), body);
    try { await store.purge(); }
    catch { throw new Error(`Version ${version} is uploaded, but cache purge failed. Run photos purge; do not roll back just to retry the purge.`); }
    log(`Published version ${version}.`);
    return candidate;
  };
  return dryRun ? action() : withLock(root, action);
}

export async function rollback(root, version, store, { dryRun = false, log = console.log } = {}) {
  if (!Number.isSafeInteger(version) || version < 1) throw new Error('Choose a positive snapshot version.');
  const action = async () => {
    const snapshot = await store.get(`catalog/v1/manifest-${version}.json`);
    if (!snapshot) throw new Error(`Snapshot ${version} does not exist.`);
    const manifest = validateManifest(JSON.parse(snapshot.body.toString()));
    if (manifest.version !== version) throw new Error('Snapshot version does not match its filename.');
    for (const photo of manifest.photos) for (const key of Object.values(photo.files)) if (!(await store.head(key))) throw new Error(`Snapshot references missing file: ${key}.`);
    const current = await currentManifest(store);
    log(`${dryRun ? 'DRY RUN: ' : ''}restore snapshot ${version}, then purge the manifest URL.`);
    if (dryRun) return manifest;
    try { await store.put(MANIFEST_KEY, snapshot.body, { contentType: 'application/json; charset=utf-8', cacheControl: MUTABLE_CACHE, ...(current.etag ? { ifMatch: current.etag } : { ifNoneMatch: '*' }) }); }
    catch (error) { if (conflict(error)) throw new Error('The live manifest changed during rollback; review it and retry.'); throw error; }
    await atomicWrite(path.join(root, 'build', 'last-published.json'), snapshot.body);
    try { await store.purge(); } catch { throw new Error(`Snapshot ${version} was restored, but cache purge failed. Run photos purge.`); }
    return manifest;
  };
  return dryRun ? action() : withLock(root, action);
}

export async function verifyUpload(store) {
  const key = `catalog/_infra-check/credentials-${randomUUID()}.json`;
  const body = Buffer.from(JSON.stringify({ purpose: 'temporary publisher credential test' }));
  let created = false;
  try {
    await store.put(key, body, { contentType: 'application/json; charset=utf-8', cacheControl: MUTABLE_CACHE, ifNoneMatch: '*' });
    created = true;
    const uploaded = await store.get(key);
    if (!uploaded?.body.equals(body)) throw new Error('R2 read-back did not match the upload.');
    const metadata = await store.head(key);
    if (metadata.CacheControl !== MUTABLE_CACHE || metadata.ContentType !== 'application/json; charset=utf-8') throw new Error('R2 did not preserve object delivery metadata.');
    let duplicateRejected = false;
    try { await store.put(key, body, { contentType: 'application/json; charset=utf-8', cacheControl: MUTABLE_CACHE, ifNoneMatch: '*' }); }
    catch (error) { if (!conflict(error)) throw error; duplicateRejected = true; }
    if (!duplicateRejected) throw new Error('R2 did not enforce conditional object creation.');
    await store.put(key, body, { contentType: 'application/json; charset=utf-8', cacheControl: MUTABLE_CACHE, ifMatch: uploaded.etag });
  } finally {
    if (created) { await store.remove(key); await store.purge([key]); }
  }
}
