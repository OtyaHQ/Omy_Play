# Omy Play staging backend

The product-owned Worker source is in backend/ and is deployed independently from Otya Core. The existing Otya Core Worker, release queue and production download paths remain untouched until cutover is reviewed.

## Resource boundary

- Worker: omy-play-api-staging
- D1: omy-play-staging-db
- R2: omy-play-staging-assets
- Identity: Otya ID service binding for optional signed-in features
- Firebase: omyplay-otya-prod, supporting App Check and FCM only
- AI: disabled by default

## Initial endpoints

- GET /health
- GET /v1/config and compatibility GET /api/app-config
- GET /v1/themes and compatibility GET /api/themes
- GET /v1/releases/latest and compatibility metadata routes
- GET /apk/arm64 and /apk/arm32 from private R2 release objects
- POST /v1/devices/register and compatibility POST /api/device
- POST /v1/crashes and compatibility POST /api/crash-report
- POST /v1/feedback and POST /v1/ratings
- GET /v1/notifications and POST /v1/notifications/:id/read

Optional account identity is verified by Otya ID. Anonymous device registration, crash intake and feedback remain possible. Identity subject is never accepted from the client body. Crash telemetry redacts local app-data paths, email addresses, phone-like values and bearer-like strings before storage.

## Local verification and deploy

    npm --prefix backend run check
    npm --prefix backend test
    npx wrangler deploy --config wrangler.omy-play-staging.toml

The Worker is initially staged and isolated. Production release routes and the Android app's default Worker URL are not changed by this commit. Release downloads require an explicitly published release row and the matching object key releases/{tag}/{abi}.apk in the private staging bucket.

## Deployment verification

- Staging API root: https://omy-play-api-staging.petersmartlink.workers.dev
- Health endpoint: https://omy-play-api-staging.petersmartlink.workers.dev/health
- Isolated D1 database: omy-play-staging-db
- Isolated R2 bucket: omy-play-staging-assets
- Firebase project: omyplay-otya-prod
- AI: disabled by default.

The live staging smoke workflow passed, including D1 readiness, app-config/themes responses and rejection of unauthenticated notification access: https://github.com/OtyaHQ/Omy_Play/actions/runs/43074343957

The reproducible schema-only bootstrap is backend/schema/bootstrap.sql. Its validation is backend/test/verify_schema.py. It contains only DDL and the observed migration ledger. It was exported without device, crash, feedback, release or other application rows. Apply only to a new empty Omy Play D1 database; existing environments require forward-only migrations.
