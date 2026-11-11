// Uploads tool/seed/seed_data.json to Cloud Firestore.
//
// The catalogue collections (properties, landlords, movers) are read-only
// in the security rules, so they are written here with the Firebase CLI
// login of a project member (IAM credentials bypass security rules).
//
// Usage (from the project root, after `firebase login`):
//   dart run tool/export_seed.dart
//   node tool/seed_firestore.mjs [--project imuka-app]
import { execSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import path from 'node:path';

const args = process.argv.slice(2);
const projectId = args.includes('--project')
  ? args[args.indexOf('--project') + 1]
  : 'imuka-app';

// Reuse the globally installed firebase-tools for authentication.
const require = createRequire(import.meta.url);
const toolsRoot = path.join(
  execSync('npm root -g').toString().trim(),
  'firebase-tools',
);
const { Client } = require(path.join(toolsRoot, 'lib/apiv2'));
const { requireAuth } = require(path.join(toolsRoot, 'lib/requireAuth'));
const { getGlobalDefaultAccount } = require(path.join(toolsRoot, 'lib/auth'));

/** Converts a seed JSON value into a Firestore REST `Value`. */
function toValue(v) {
  if (v === null || v === undefined) return { nullValue: null };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') {
    return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  }
  if (typeof v === 'string') return { stringValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(toValue) } };
  if ('__timestamp' in v) return { timestampValue: v.__timestamp };
  if ('__double' in v) return { doubleValue: v.__double };
  if ('__geo' in v) {
    return { geoPointValue: { latitude: v.__geo[0], longitude: v.__geo[1] } };
  }
  return { mapValue: { fields: toFields(v) } };
}

function toFields(map) {
  return Object.fromEntries(
    Object.entries(map).map(([k, v]) => [k, toValue(v)]),
  );
}

const account = getGlobalDefaultAccount();
if (!account) {
  console.error('Run `firebase login` first.');
  process.exit(1);
}
await requireAuth({ projectId, user: account.user, tokens: account.tokens });

const client = new Client({
  urlPrefix: 'https://firestore.googleapis.com',
  apiVersion: 'v1',
  auth: true,
});
const database = `projects/${projectId}/databases/(default)`;
const seed = JSON.parse(readFileSync('tool/seed/seed_data.json', 'utf8'));

// Each document is fully replaced, so re-running the seed is safe.
const writes = [];
for (const [collection, docs] of Object.entries(seed)) {
  for (const [id, data] of Object.entries(docs)) {
    writes.push({
      update: {
        name: `${database}/documents/${collection}/${id}`,
        fields: toFields(data),
      },
    });
  }
}

// A commit accepts up to 500 writes.
for (let i = 0; i < writes.length; i += 500) {
  await client.post(`/${database}/documents:commit`, {
    writes: writes.slice(i, i + 500),
  });
}
const counts = Object.entries(seed)
  .map(([c, docs]) => `${Object.keys(docs).length} ${c}`)
  .join(', ');
console.log(`Seeded ${projectId}: ${counts}.`);
