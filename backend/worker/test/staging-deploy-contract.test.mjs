import test from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

const read = path => readFileSync(new URL('../' + path, import.meta.url), 'utf8')
const readRoot = path => readFileSync(new URL('../../../' + path, import.meta.url), 'utf8')
const manifest = read('wrangler.toml')
const workflow = readRoot('.github/workflows/deploy-omy-play-staging.yml')

test('Omy Play staging is private and uses its own package and storage resources', () => {
  assert.match(manifest, /^name = "omy-play-api-staging"$/m)
  assert.match(manifest, /^workers_dev = false$/m)
  assert.match(manifest, /^keep_vars = true$/m)
  assert.match(manifest, /APP_PACKAGE_ID = "com\.otya\.omyplay"/)
  assert.match(manifest, /database_name = "omy-play-staging-db"/)
  assert.match(manifest, /database_id = "006b1ac1-0e92-4480-b07e-4232724710e8"/)
  assert.match(manifest, /bucket_name = "omy-play-staging-assets"/)
  assert.match(manifest, /binding = "OTYA_ID"[\s\S]*?service = "otya-id-staging"/)
  assert.doesNotMatch(manifest, /service = "otya-auth"/)
})

test('Omy Play staging redeploy is manual and waits for isolated Otya ID', () => {
  assert.match(workflow, /workflow_dispatch:/)
  assert.match(workflow, /github\.ref == 'refs\/heads\/omy-play-backend-foundation'/)
  assert.match(workflow, /DEPLOY-STAGING/)
  assert.match(workflow, /CLOUDFLARE_API_TOKEN_STAGING/)
  assert.match(workflow, /workers\/scripts\/otya-id-staging\/settings/)
  assert.match(workflow, /wrangler@4\.159\.0 deploy --config wrangler\.toml/)
  assert.match(workflow, /binding\.service !== 'otya-id-staging'/)
  assert.match(workflow, /FCM_TOKEN_ENCRYPTION_KEY/)
  assert.doesNotMatch(workflow, /service = "otya-auth"/)
})
