# Omy Play backend

Independent backend for the Omy Play Android product. It is deployed separately from Opoint and Otya End.

## Runtime boundary

- Worker: `omy-play-api-staging`
- D1: `omy-play-staging-db`
- R2: `omy-play-staging-assets`
- Firebase: `omyplay-otya-prod`
- Android application ID: `com.otya.omyplay`
- Product: `OMY_PLAY`; environment: `staging`
- `AI_ENABLED=false`: local playback never depends on AI/cloud availability.
- Identity currently uses `otya-auth`; replace with isolated `otya-id-staging` before external tester onboarding.

## Responsibilities

App configuration, version/update metadata, release metadata, device registration, crash intake, feedback, ratings, theme catalog, notifications and Together signaling. It does not store users' local media libraries, music/video files, Vault content or raw playback history.

Compatibility routes include `/api/app-config`, `/api/crash-report`, `/api/device`, `/api/feedback`, `/api/themes`, `/api/version`, `/apk/arm32`, `/apk/arm64`, `/check-update`, `/latest`, and the corresponding `/v1/*` endpoints for config, crashes, device registration, feedback, notifications, ratings, releases and themes.

## Security

- Crash messages are sanitized before persistence.
- FCM registration tokens are encrypted at rest using AES-256-GCM; missing key fails closed.
- Push messages are hints only; clients fetch authoritative state from the API.
- FCM sending remains disabled pending product-specific admin credentials, queue retry/DLQ handling and delivery tests.
- Omy Play must not share Opoint's D1, R2, Firebase service account or operational keys.
- Local playback, scan, folders, search, transfer and Vault must work offline.

## Files

- `worker/src/index.mjs`: exact single-module source deployed to staging on 2026-11-11.
- `worker/snapshots/2026-11-11-current.sql`: schema-only snapshot of 13 app tables plus migration history, without device/activity rows.
- `worker/wrangler.toml`: staging bindings only.
- `worker/test/contract.test.mjs`: pure helper tests.

Run tests with `cd backend/worker && npm test`. Production still requires secret review, signed device App Check/FCM tests, backup/restore validation, privacy review and explicit approval.
