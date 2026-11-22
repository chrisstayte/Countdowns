import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, writeFile, stat, rm, symlink } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import sharp from 'sharp';
import YAML from 'yaml';
import { decode, isBlurhashValid } from 'blurhash';
import { REPO, BASE_URL, MANIFEST_KEY, MUTABLE_CACHE, IMMUTABLE_CACHE, initCatalogue, addPhoto, buildCatalogue, categoryIds, mediaRoot, digest } from '../src/catalogue.mjs';
import { publish, rollback, validateManifest, verifyUpload } from '../src/publisher.mjs';

async function fixture(t, { large = false, orientation = 1 } = {}) {
  const directory = await mkdtemp(path.join(tmpdir(), 'countdowns-publisher-'));
  t.after(() => rm(directory, { recursive: true, force: true }));
  const root = await initCatalogue(path.join(directory, 'private'));
  const input = path.join(directory, 'input.jpg');
  await sharp({ create: { width: large ? 3200 : 120, height: large ? 2000 : 80, channels: 3, background: '#956d46' } }).withMetadata({ orientation }).jpeg().toFile(input);
  return { directory, root, input };
}

async function catalogFixture(t) {
  const f = await fixture(t);
  await addPhoto(f.root, f.input, { categories: ['christmas'], license: 'owned', allowSmall: true });
  const file = path.join(f.root, 'catalogue.yaml');
  const data = YAML.parse(await readFile(file, 'utf8'));
  data.enabled = true;
  await writeFile(file, YAML.stringify(data));
  return { ...f, manifest: await buildCatalogue(f.root) };
}

class MemoryStore {
  objects = new Map();
  events = [];
  sequence = 0;
  failPurge = false;
  conflictLive = false;
  async get(key) { const value = this.objects.get(key); return value ? { body: value.body, etag: value.etag } : null; }
  async head(key) { const v = this.objects.get(key); return v ? { ContentLength: v.body.length, Metadata: { sha256: digest(v.body) }, CacheControl: v.cacheControl, ContentType: v.contentType } : null; }
  async list(prefix) { return [...this.objects.keys()].filter(key => key.startsWith(prefix)); }
  async put(key, body, options) {
    if (this.conflictLive && key === MANIFEST_KEY) {
      this.objects.set(key, { body: Buffer.from(JSON.stringify({ schema: 1, version: 99 })), etag: 'other-writer' });
      throw Object.assign(new Error('concurrent update'), { name: 'PreconditionFailed' });
    }
    const current = this.objects.get(key);
    if ((options.ifNoneMatch === '*' && current) || (options.ifMatch && current?.etag !== options.ifMatch)) throw Object.assign(new Error('precondition'), { name: 'PreconditionFailed' });
    this.events.push(`put:${key}`);
    this.objects.set(key, { body: Buffer.from(body), etag: `etag-${++this.sequence}`, ...options });
  }
  async purge() { this.events.push('purge'); if (this.failPurge) throw new Error('purge outage'); }
  async remove(key) { this.events.push(`delete:${key}`); this.objects.delete(key); }
}

test('credential verification checks conditional writes, preserves metadata, and removes its temporary object', async () => {
  const store = new MemoryStore();
  await verifyUpload(store);
  assert.equal(store.objects.size, 0);
  assert.match(store.events.at(-2), /^delete:catalog\/_infra-check\/credentials-/);
  assert.equal(store.events.at(-1), 'purge');
});

test('build produces oriented, metadata-free variants with a decodable BlurHash and public fields only', async t => {
  const { root, input } = await fixture(t, { large: true, orientation: 6 });
  assert.ok((await sharp(input).metadata()).exif);
  await addPhoto(root, input, { categories: ['christmas', 'winter'], license: 'owned', creditName: '<script>private-note</script>' });
  const file = path.join(root, 'catalogue.yaml');
  const data = YAML.parse(await readFile(file, 'utf8'));
  data.photos[0].notes = 'PRIVATE_SENTINEL';
  data.photos[0].sourceUrl = 'https://private.example/source';
  await writeFile(file, YAML.stringify(data));
  const manifest = await buildCatalogue(root);
  const photo = manifest.photos[0];
  assert.equal(photo.w, 1600);
  assert.equal(photo.h, 2560);
  assert.equal(photo.blurhash.length, 28);
  assert.equal(isBlurhashValid(photo.blurhash).result, true);
  assert.equal(decode(photo.blurhash, 32, 32).length, 32 * 32 * 4);
  assert.match(photo.color, /^#[A-F0-9]{6}$/);
  for (const [variant, expected] of [['thumb', 480], ['full', 2560]]) {
    const meta = await sharp(path.join(root, 'build', photo.files[variant])).metadata();
    assert.equal(Math.max(meta.width, meta.height), expected);
    assert.equal(meta.exif, undefined);
    assert.equal(meta.icc, undefined);
    assert.equal(meta.orientation, undefined);
    if (variant === 'full') assert.equal(meta.isProgressive, true);
  }
  const json = JSON.stringify(manifest);
  assert.ok(!json.includes('PRIVATE_SENTINEL'));
  assert.ok(!json.includes('originals/'));
  assert.ok(!json.includes('sourceUrl'));
  assert.ok(!json.includes('retrievedAt'));
  const html = await readFile(path.join(root, 'build/contact-sheet.html'), 'utf8');
  assert.ok(!html.includes('<script>'));
  assert.ok(html.includes('&lt;script&gt;'));
  validateManifest(manifest);
});

test('rejects unknown categories, missing evidence, small originals, and media under the repository', async t => {
  const { root, input } = await fixture(t);
  await assert.rejects(() => addPhoto(root, input, { categories: ['holidays'], license: 'owned', allowSmall: true }), /category/);
  await assert.rejects(() => addPhoto(root, input, { categories: ['christmas'], license: 'CC0-1.0', allowSmall: true }), /evidence/);
  await assert.rejects(() => addPhoto(root, input, { categories: ['christmas'], license: 'owned' }), /2560/);
  await assert.rejects(() => mediaRoot(path.join(REPO, 'private-media'), { create: true }), /outside/);
  const ids = await categoryIds();
  assert.ok(ids.includes('christmas'));
  assert.ok(!ids.includes('holidays'));
});

test('small-file exception never upscales; cache verifies bytes and requires the exception on every build', async t => {
  const { root, manifest } = await catalogFixture(t);
  const photo = manifest.photos[0];
  assert.equal(photo.w, 120);
  assert.equal(photo.h, 80);
  const thumb = path.join(root, 'build', photo.files.thumb);
  const before = await stat(thumb);
  const cacheFile = path.join(root, 'build/.cache.json');
  const cached = JSON.parse(await readFile(cacheFile, 'utf8'));
  cached[photo.id].privateDebugPath = 'PRIVATE_CACHE_SENTINEL';
  await writeFile(cacheFile, JSON.stringify(cached));
  const again = await buildCatalogue(root);
  assert.equal(again.photos[0].blurhash, photo.blurhash);
  assert.ok(!JSON.stringify(again).includes('PRIVATE_CACHE_SENTINEL'));
  assert.equal((await stat(thumb)).mtimeMs, before.mtimeMs);
  await writeFile(thumb, 'corrupted');
  await buildCatalogue(root);
  assert.equal((await sharp(thumb).metadata()).format, 'webp');
  const file = path.join(root, 'catalogue.yaml');
  const data = YAML.parse(await readFile(file, 'utf8'));
  delete data.photos[0].allowSmall;
  await writeFile(file, YAML.stringify(data));
  await assert.rejects(() => buildCatalogue(root), /2560/);
});

test('rechecks evidence and rejects symlinks to originals outside the private folder', async t => {
  const { root, input, directory } = await fixture(t);
  const evidence = path.join(directory, 'license.txt');
  await writeFile(evidence, 'test evidence');
  await addPhoto(root, input, { categories: ['christmas'], license: 'CC0-1.0', evidence, allowSmall: true });
  await buildCatalogue(root);
  const file = path.join(root, 'catalogue.yaml');
  const data = YAML.parse(await readFile(file, 'utf8'));
  await rm(path.join(root, data.photos[0].evidence[0]));
  await assert.rejects(() => buildCatalogue(root), /ENOENT/);
  data.photos[0].license = 'owned';
  await symlink(input, path.join(root, 'originals/link.jpg'));
  data.photos[0].original = 'originals/link.jpg';
  await writeFile(file, YAML.stringify(data));
  await assert.rejects(() => buildCatalogue(root), /inside originals/);
});

test('dry run has no remote writes; publish uploads images before reserving snapshot and replacing live manifest', async t => {
  const { root, manifest } = await catalogFixture(t);
  const store = new MemoryStore();
  await publish(root, manifest, store, { dryRun: true, log() {} });
  assert.equal(store.objects.size, 0);
  assert.deepEqual(store.events, []);
  const result = await publish(root, manifest, store, { log() {} });
  assert.equal(result.version, 1);
  assert.equal(store.objects.get(MANIFEST_KEY).cacheControl, MUTABLE_CACHE);
  assert.equal(store.objects.get('catalog/v1/manifest-1.json').cacheControl, IMMUTABLE_CACHE);
  assert.deepEqual(store.events.slice(-3), ['put:catalog/v1/manifest-1.json', `put:${MANIFEST_KEY}`, 'purge']);
  for (const key of Object.values(manifest.photos[0].files)) assert.equal(store.objects.get(key).cacheControl, IMMUTABLE_CACHE);
  const second = await publish(root, manifest, store, { log() {} });
  assert.equal(second.version, 2);
  assert.equal(store.events.filter(e => e.startsWith('put:p/')).length, 2);
});

test('rollback preserves snapshots; future publishes do not reuse old or reserved versions', async t => {
  const { root, manifest } = await catalogFixture(t);
  const store = new MemoryStore();
  await publish(root, manifest, store, { log() {} });
  await publish(root, manifest, store, { log() {} });
  const before = store.events.length;
  await rollback(root, 1, store, { dryRun: true, log() {} });
  assert.equal(store.events.length, before);
  await rollback(root, 1, store, { log() {} });
  assert.equal(JSON.parse(store.objects.get(MANIFEST_KEY).body).version, 1);
  assert.ok(store.objects.has('catalog/v1/manifest-2.json'));
  store.objects.set('catalog/v1/manifest-8.json', { body: Buffer.from('{}'), etag: 'reserved' });
  const next = await publish(root, manifest, store, { log() {} });
  assert.equal(next.version, 9);
});

test('purge failure reports that upload succeeded and leaves the live manifest recoverable', async t => {
  const { root, manifest } = await catalogFixture(t);
  const store = new MemoryStore();
  store.failPurge = true;
  await assert.rejects(() => publish(root, manifest, store, { log() {} }), /uploaded.*photos purge/);
  assert.equal(JSON.parse(store.objects.get(MANIFEST_KEY).body).version, 1);
  store.failPurge = false;
  assert.equal((await publish(root, manifest, store, { log() {} })).version, 2);
});

test('concurrent live update is not overwritten; reserved snapshot stays available', async t => {
  const { root, manifest } = await catalogFixture(t);
  const store = new MemoryStore();
  store.conflictLive = true;
  await assert.rejects(() => publish(root, manifest, store, { log() {} }), /concurrent publish/);
  assert.equal(JSON.parse(store.objects.get(MANIFEST_KEY).body).version, 99);
  assert.ok(store.objects.has('catalog/v1/manifest-1.json'));
  assert.ok(!store.events.includes('purge'));
});

test('refuses modified immutable objects and output path traversal', async t => {
  const { root, manifest } = await catalogFixture(t);
  const store = new MemoryStore();
  await publish(root, manifest, store, { log() {} });
  store.objects.get(manifest.photos[0].files.full).cacheControl = 'no-store';
  await assert.rejects(() => publish(root, manifest, store, { log() {} }), /immutable object differs/);
  const changed = structuredClone(manifest);
  changed.photos[0].files.full = '../private-file.jpg';
  assert.throws(() => validateManifest(changed), /invalid full path/);
});

test('CLI supports an offline dry run before credentials exist', async t => {
  const { root } = await catalogFixture(t);
  const result = spawnSync(process.execPath, [path.join(REPO, 'tool/photos/src/cli.mjs'), 'publish', '--dry-run'], { encoding: 'utf8', env: { PATH: process.env.PATH, COUNTDOWNS_MEDIA_DIR: root, COUNTDOWNS_PHOTOS_ENV: path.join(root, 'absent.env') } });
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /DRY RUN \(offline\)/);
});
