#!/usr/bin/env node
import { parseArgs } from 'node:util';
import { homedir } from 'node:os';
import path from 'node:path';
import { access, stat } from 'node:fs/promises';
import { categoryIds, initCatalogue, mediaRoot, addPhoto, buildCatalogue } from './catalogue.mjs';
import { publish, rollback, remoteStore, verifyUpload } from './publisher.mjs';

const help = `Countdowns photo publisher (Node 22.16+)

  photos init
  photos categories
  photos add <file> --categories christmas,winter --license CC0-1.0
    --evidence <file> [--credit-name <name>] [--credit-url <https-url>]
    [--page <https-url>] [--source-url <https-url>] [--tags lights,snow]
    [--allow-small]
  photos build
  photos publish [--dry-run]
  photos rollback <version> [--dry-run]
  photos purge
  photos doctor [--remote] [--upload-test]

Set COUNTDOWNS_MEDIA_DIR outside the public repository.
Credentials load from ~/.config/countdowns-media/publisher.env (mode 600)
or COUNTDOWNS_PHOTOS_ENV. Existing environment variables take precedence.
No credential values are printed. No photos are fetched automatically.
`;

async function main() {
  const envFile = process.env.COUNTDOWNS_PHOTOS_ENV ?? path.join(homedir(), '.config/countdowns-media/publisher.env');
  try {
    await access(envFile);
    const permissions = await stat(envFile);
    if ((permissions.mode & 0o077) !== 0) throw new Error('The private credentials file must have mode 600.');
    process.loadEnvFile(envFile);
  } catch (error) { if (error.code !== 'ENOENT') throw error; }
  const { values, positionals } = parseArgs({ allowPositionals: true, options: { categories: { type: 'string' }, license: { type: 'string' }, evidence: { type: 'string' }, 'credit-name': { type: 'string' }, 'credit-url': { type: 'string' }, page: { type: 'string' }, 'source-url': { type: 'string' }, tags: { type: 'string' }, 'allow-small': { type: 'boolean' }, 'dry-run': { type: 'boolean' }, remote: { type: 'boolean' }, 'upload-test': { type: 'boolean' }, help: { type: 'boolean', short: 'h' } } });
  const [command, argument] = positionals;
  if (!command || values.help) { console.log(help); return; }
  if (command === 'categories') { console.log(JSON.stringify(await categoryIds(), null, 2)); return; }
  if (command === 'init') { console.log(`Initialized private media folder: ${await initCatalogue(process.env.COUNTDOWNS_MEDIA_DIR)}`); return; }
  if (command === 'doctor') {
    for (const key of ['COUNTDOWNS_MEDIA_DIR', 'R2_ENDPOINT', 'R2_ACCESS_KEY_ID', 'R2_SECRET_ACCESS_KEY', 'CF_API_TOKEN', 'CF_ZONE_ID']) console.log(`${key}: ${process.env[key] ? 'configured' : 'missing'}`);
    if (process.env.COUNTDOWNS_MEDIA_DIR) await mediaRoot(process.env.COUNTDOWNS_MEDIA_DIR);
    if (values.remote || values['upload-test']) {
      const store = remoteStore();
      await store.list('catalog/v1/');
      console.log('R2 authentication and bucket listing: passed.');
      if (values['upload-test']) { await verifyUpload(store); console.log('R2 upload/read/delete and scoped cache purge: passed; temporary object removed.'); }
    }
    return;
  }
  if (command === 'purge') { await remoteStore().purge(); console.log('Purged only the catalog manifest URL.'); return; }
  const root = await mediaRoot(process.env.COUNTDOWNS_MEDIA_DIR);
  if (command === 'add') {
    if (!argument) throw new Error('Pass an input photo path.');
    const id = await addPhoto(root, argument, { categories: values.categories?.split(',').filter(Boolean), license: values.license, evidence: values.evidence, creditName: values['credit-name'], creditUrl: values['credit-url'], page: values.page, sourceUrl: values['source-url'], tags: values.tags?.split(',').filter(Boolean), allowSmall: values['allow-small'] });
    console.log(`Added ${id} to the private catalog. Run photos build, then review the contact sheet.`);
  } else if (command === 'build') {
    const manifest = await buildCatalogue(root);
    console.log(`Built ${manifest.photos.length} photos with BlurHash placeholders. Review ${path.join(root, 'build/contact-sheet.html')}`);
  } else if (command === 'publish') {
    const manifest = await buildCatalogue(root);
    if (values['dry-run'] && !process.env.R2_ACCESS_KEY_ID) { console.log(`DRY RUN (offline): ${manifest.photos.length} photos; upload new variants and a versioned snapshot, update manifest, then purge its exact URL. No remote changes.`); return; }
    await publish(root, manifest, remoteStore(), { dryRun: values['dry-run'] });
  } else if (command === 'rollback') {
    await rollback(root, Number(argument), remoteStore(), { dryRun: values['dry-run'] });
  } else throw new Error(`Unknown command ${command}. Run photos --help.`);
}

main().catch(error => {
  let message = error.message ?? String(error);
  for (const key of ['R2_ACCESS_KEY_ID', 'R2_SECRET_ACCESS_KEY', 'CF_API_TOKEN']) if (process.env[key]) message = message.split(process.env[key]).join('[redacted]');
  console.error(`photos: ${message}`);
  process.exitCode = 1;
});
