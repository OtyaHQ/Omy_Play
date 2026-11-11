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
