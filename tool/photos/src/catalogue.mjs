import { createHash, randomUUID } from 'node:crypto';
import { mkdir, readFile, writeFile, rename, realpath, stat, copyFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';
import { encode, isBlurhashValid } from 'blurhash';
import YAML from 'yaml';

export const REPO = fileURLToPath(new URL('../../../', import.meta.url));
export const BASE_URL = 'https://media.countdowns.stayte.app/';
export const MUTABLE_CACHE = 'public, max-age=300';
export const IMMUTABLE_CACHE = 'public, max-age=31536000, immutable';
export const MANIFEST_KEY = 'catalog/v1/manifest.json';
const licenses = new Set(['CC0-1.0', 'PDM-1.0', 'owned', 'commissioned']);
const processor = JSON.stringify({ sharp: sharp.versions, thumb: 480, full: 2560, webp: 70, jpeg: 82, blurhash: [4, 3], revision: 1 });
export const digest = bytes => createHash('sha256').update(bytes).digest('hex');
const inside = (parent, child) => child === parent || (!path.relative(parent, child).startsWith('..' + path.sep) && !path.isAbsolute(path.relative(parent, child)) && path.relative(parent, child) !== '..');
const requireValue = (condition, message) => { if (!condition) throw new Error(message); };

export async function atomicWrite(file, content) {
  await mkdir(path.dirname(file), { recursive: true, mode: 0o700 });
  const temp = `${file}.${randomUUID()}.tmp`;
  await writeFile(temp, content, { mode: 0o600, flag: 'wx' });
  await rename(temp, file);
}

export async function mediaRoot(directory, { create = false } = {}) {
  requireValue(directory, 'Set COUNTDOWNS_MEDIA_DIR to a private folder outside the repository.');
  const target = path.resolve(directory);
  requireValue(!inside(await realpath(REPO), target), 'The media folder must be outside the public repository.');
  if (create) await mkdir(target, { recursive: true, mode: 0o700 });
  const resolved = await realpath(target);
  requireValue(!inside(await realpath(REPO), resolved), 'The media folder resolves inside the public repository.');
  return resolved;
}

export async function categoryIds() {
  const source = await readFile(path.join(REPO, 'lib/stock/stock_categories.dart'), 'utf8');
  const ids = [...source.matchAll(/StockCategory\(\s*['"]([^'"]+)['"]/g)].map(m => m[1]);
  requireValue(ids.length > 0 && new Set(ids).size === ids.length, 'Could not read unique category IDs from the app.');
  return ids;
}

export async function initCatalogue(directory) {
  const root = await mediaRoot(directory, { create: true });
  for (const name of ['originals', 'evidence', 'inbox', 'build']) await mkdir(path.join(root, name), { recursive: true, mode: 0o700 });
  const file = path.join(root, 'catalogue.yaml');
  try {
    await writeFile(file, YAML.stringify({ enabled: false, categories: {}, photos: [] }), { flag: 'wx', mode: 0o600 });
  } catch (error) { if (error.code !== 'EEXIST') throw error; }
  return root;
}

export async function loadCatalogue(root) {
  const data = YAML.parse(await readFile(path.join(root, 'catalogue.yaml'), 'utf8'));
  requireValue(data && Array.isArray(data.photos), 'catalogue.yaml must contain a photos list.');
  requireValue(typeof data.enabled === 'boolean', 'catalogue.yaml must explicitly set enabled: true or false.');
  return data;
}

async function privateFile(root, relative, folder) {
  requireValue(typeof relative === 'string' && !path.isAbsolute(relative), `Use a relative ${folder}/ path.`);
  const allowed = await realpath(path.join(root, folder));
  const resolved = await realpath(path.resolve(root, relative));
  requireValue(inside(allowed, resolved) && (await stat(resolved)).isFile(), `File must stay inside ${folder}/.`);
  return resolved;
}

function url(value, label) {
  if (value === '' || value === undefined) return '';
  requireValue(typeof value === 'string', `${label} must be an HTTPS URL or empty.`);
  const parsed = new URL(value);
  requireValue(parsed.protocol === 'https:' && !parsed.username && !parsed.password, `${label} must be an HTTPS URL without credentials.`);
  return value;
}

export function publicPhoto(photo, ids) {
  requireValue(/^p_\d{4,}$/.test(photo.id), 'Photo IDs must look like p_0001.');
  requireValue(licenses.has(photo.license), `${photo.id}: unsupported license.`);
  requireValue(Array.isArray(photo.categories) && photo.categories.length > 0 && photo.categories.every(c => ids.includes(c)), `${photo.id}: unknown or missing category IDs.`);
  requireValue(!photo.tags || (Array.isArray(photo.tags) && photo.tags.every(t => typeof t === 'string')), `${photo.id}: tags must be strings.`);
  requireValue(photo.hidden === undefined || typeof photo.hidden === 'boolean', `${photo.id}: hidden must be a boolean.`);
  requireValue(/^\d{4}-\d{2}-\d{2}$/.test(photo.added) && !Number.isNaN(Date.parse(photo.added)), `${photo.id}: added must be YYYY-MM-DD.`);
  const credit = photo.credit ?? {};
  requireValue(typeof credit === 'object' && !Array.isArray(credit), `${photo.id}: invalid credit.`);
  requireValue(credit.name === undefined || typeof credit.name === 'string', `${photo.id}: invalid credit name.`);
  const result = { id: photo.id, categories: [...new Set(photo.categories)], credit: { name: credit.name ?? '', url: url(credit.url, 'credit.url'), page: url(credit.page, 'credit.page') }, license: photo.license, tags: [...new Set(photo.tags ?? [])], added: photo.added, hidden: photo.hidden ?? false };
  if (photo.focal !== undefined) {
    requireValue(photo.focal && ['x', 'y'].every(k => Number.isFinite(photo.focal[k]) && photo.focal[k] >= 0 && photo.focal[k] <= 1), `${photo.id}: focal coordinates must be between 0 and 1.`);
    result.focal = { x: photo.focal.x, y: photo.focal.y };
  }
  return result;
}

export async function addPhoto(root, file, options) {
  const catalogue = await loadCatalogue(root);
  const ids = await categoryIds();
  const next = Math.max(0, ...catalogue.photos.map(p => Number(/^p_(\d+)$/.exec(p.id)?.[1]) || 0)) + 1;
  const id = `p_${String(next).padStart(4, '0')}`;
  const photo = publicPhoto({ id, categories: options.categories, license: options.license, credit: { name: options.creditName, url: options.creditUrl, page: options.page }, tags: options.tags, added: new Date().toISOString().slice(0, 10), hidden: false }, ids);
  const meta = await sharp(file, { limitInputPixels: 100_000_000 }).metadata();
  requireValue(['jpeg', 'png', 'webp', 'tiff', 'avif', 'heif'].includes(meta.format) && (meta.pages ?? 1) === 1, 'Use a single-frame JPEG, PNG, WebP, TIFF, or AVIF photo.');
  requireValue(options.allowSmall || Math.max(meta.width, meta.height) >= 2560, 'The source must have at least 2560 pixels on its long edge; use --allow-small to make an explicit exception.');
  const evidence = options.evidence;
  requireValue(photo.license === 'owned' || evidence, 'License evidence is required unless the photo is owned. Pass --evidence <file>.');
  const extension = { jpeg: 'jpg', png: 'png', webp: 'webp', tiff: 'tif', avif: 'avif', heif: 'heic' }[meta.format];
  photo.original = `originals/${id}.${extension}`;
  if (evidence) {
    const evidencePath = `evidence/${id}/${path.basename(evidence)}`;
    await mkdir(path.dirname(path.join(root, evidencePath)), { recursive: true, mode: 0o700 });
    await copyFile(evidence, path.join(root, evidencePath));
    photo.evidence = [evidencePath];
  }
  if (options.sourceUrl) photo.sourceUrl = url(options.sourceUrl, 'sourceUrl');
  photo.retrievedAt = new Date().toISOString();
  if (options.allowSmall) photo.allowSmall = true;
  await copyFile(file, path.join(root, photo.original));
  catalogue.photos.push(photo);
  await atomicWrite(path.join(root, 'catalogue.yaml'), YAML.stringify(catalogue));
  return id;
}

async function processedPhoto(root, photo, cache) {
  const original = await privateFile(root, photo.original, 'originals');
  const options = { limitInputPixels: 100_000_000 };
  const meta = await sharp(original, options).metadata();
  requireValue(['jpeg', 'png', 'webp', 'tiff', 'avif', 'heif'].includes(meta.format) && (meta.pages ?? 1) === 1, `${photo.id}: unsupported or animated original.`);
  requireValue(photo.allowSmall === true || Math.max(meta.width, meta.height) >= 2560, `${photo.id}: source is below 2560 pixels; explicitly set allowSmall: true to allow it.`);
  const fingerprint = digest(Buffer.concat([await readFile(original), Buffer.from(processor)]));
  const previous = cache[photo.id];
  if (previous?.fingerprint === fingerprint && isBlurhashValid(previous.blurhash ?? '').result) {
    let valid = true;
    for (const key of Object.values(previous.files)) {
      try { valid &&= digest(await readFile(path.join(root, 'build', key))).startsWith(path.basename(key).split('.')[0]); }
      catch { valid = false; }
    }
    if (valid) return previous;
  }
  const pipeline = size => sharp(original, options).autoOrient().toColourspace('srgb').flatten({ background: '#ffffff' }).resize({ width: size, height: size, fit: 'inside', withoutEnlargement: true });
  const thumb = await pipeline(480).webp({ quality: 70 }).toBuffer();
  const full = await pipeline(2560).jpeg({ quality: 82, progressive: true }).toBuffer({ resolveWithObject: true });
  const files = { thumb: `p/${photo.id}/${digest(thumb).slice(0, 8)}.thumb.webp`, full: `p/${photo.id}/${digest(full.data).slice(0, 8)}.full.jpg` };
  await atomicWrite(path.join(root, 'build', files.thumb), thumb);
  await atomicWrite(path.join(root, 'build', files.full), full.data);
  const { data, info } = await sharp(thumb).resize({ width: 32, height: 32, fit: 'inside' }).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const mean = [0, 0, 0];
  for (let i = 0; i < data.length; i += 4) for (let channel = 0; channel < 3; channel++) mean[channel] += data[i + channel];
  const color = '#' + mean.map(c => Math.round(c / (info.width * info.height)).toString(16).padStart(2, '0')).join('').toUpperCase();
  const blurhash = encode(new Uint8ClampedArray(data), info.width, info.height, 4, 3);
  return { fingerprint, files, w: full.info.width, h: full.info.height, color, blurhash };
}

const escapeHtml = text => String(text).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);

export async function buildCatalogue(root) {
  const catalogue = await loadCatalogue(root);
  const ids = await categoryIds();
  const seen = new Set();
  const photos = [];
  let previous = {};
  try { previous = JSON.parse(await readFile(path.join(root, 'build', '.cache.json'), 'utf8')); } catch (e) { if (e.code !== 'ENOENT' && !(e instanceof SyntaxError)) throw e; }
  const cache = {};
  for (const photo of catalogue.photos) {
    const publicFields = publicPhoto(photo, ids);
    requireValue(!seen.has(photo.id), `Duplicate photo ID ${photo.id}.`);
    seen.add(photo.id);
    if (photo.license !== 'owned') {
      requireValue(Array.isArray(photo.evidence) && photo.evidence.length > 0, `${photo.id}: license evidence is required.`);
      for (const evidence of photo.evidence) await privateFile(root, evidence, 'evidence');
    }
    cache[photo.id] = await processedPhoto(root, photo, previous);
    const processed = cache[photo.id];
    photos.push({ ...publicFields, files: { thumb: processed.files.thumb, full: processed.files.full }, w: processed.w, h: processed.h, color: processed.color, blurhash: processed.blurhash });
  }
  const categories = {};
  for (const [id, value] of Object.entries(catalogue.categories ?? {})) {
    requireValue(ids.includes(id) && typeof value.cover === 'string' && photos.some(p => p.id === value.cover && !p.hidden && p.categories.includes(id)), `Invalid category cover for ${id}.`);
    categories[id] = { cover: value.cover };
  }
  const manifest = { schema: 1, version: 0, generatedAt: new Date().toISOString(), baseUrl: BASE_URL, enabled: catalogue.enabled, categories, photos };
  await atomicWrite(path.join(root, 'build', '.cache.json'), JSON.stringify(cache, null, 2) + '\n');
  await atomicWrite(path.join(root, 'build', 'manifest.json'), JSON.stringify(manifest, null, 2) + '\n');
  const sections = ids.map(id => {
    const entries = photos.filter(p => !p.hidden && p.categories.includes(id));
    if (!entries.length) return '';
    return `<section><h2>${escapeHtml(id)}</h2><div class="grid">${entries.map(p => `<figure><img src="${escapeHtml(p.files.thumb)}" style="background:${p.color}" alt="${escapeHtml(p.tags.join(', '))}"><figcaption>${escapeHtml(p.id)} · ${escapeHtml(p.credit.name)}<br>${escapeHtml(p.license)} · ${p.w} × ${p.h}<br><code>${escapeHtml(p.blurhash)}</code></figcaption></figure>`).join('')}</div></section>`;
  }).join('');
  await atomicWrite(path.join(root, 'build', 'contact-sheet.html'), `<!doctype html><html lang="en"><meta charset="utf-8"><title>Countdowns photo review</title><style>body{font:16px system-ui;margin:32px;background:#faf8f2;color:#222}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:16px}figure{margin:0}img{width:100%;height:220px;object-fit:cover;border-radius:12px}figcaption{padding:8px;font-size:13px}code{overflow-wrap:anywhere}</style><h1>Countdowns photo review</h1><p>${photos.filter(p => !p.hidden).length} visible photos. Catalog enabled: ${catalogue.enabled}. Review credits, categories and crops before publishing.</p>${sections}</html>`);
  return manifest;
}
