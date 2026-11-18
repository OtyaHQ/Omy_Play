# Omy Play backend completion status

**Environment:** isolated Cloudflare staging  
**Release state:** backend foundation; Android and production release gates remain open  
**AI:** disabled  
**Local media/Vault cloud sync:** disabled by default

## Verified foundation

- Product-owned Worker: `omy-play-api-staging`.
- Product-owned D1: `omy-play-staging-db`.
- Product-owned R2: `omy-play-staging-assets`.
- D1 catalogue: 13 application tables and 13 indexes; one schema migration record; four default themes and one default app-config record.
- Foreign-key check: no violations. No registered devices, crash reports, downloads, feedback, ratings, releases or notifications at the 2026-11-11 verification.
- Omy Play backend CI: 8/8 contract tests pass on the current rebuild branch after correcting the FCM ciphertext version assertion.
- The staging API health and smoke checks have passed previously. Re-run them after each Worker or schema change.

## Current API surface

- Health, app configuration, theme catalogue and latest-release metadata.
- Private R2 release download routes for supported Android ABIs.
- Device registration, crash intake with PII/path redaction, feedback and ratings.
- Authenticated notifications and read receipts.
- Together room and realtime signalling routes with identity verification.

## Remaining backend work

1. Complete identity binding migration from the legacy `otya-auth` service to the reviewed Otya ID contract.
2. Add FCM delivery through a product-owned outbox/Queue consumer. Device tokens are encrypted at rest; no FCM Admin credential is stored in the repository. Provision a dedicated secret before enabling push.
3. Complete release publishing: signed build artifact, checksum, ABI metadata, private R2 upload, release row publication, revocation and rollback tests.
4. Finish Together session authorization, invite expiry, replay prevention, payload limits, abuse controls and retention cleanup.
5. Add device registration lifecycle, invalid-token cleanup, privacy retention and account deletion behavior.
6. Run Android integration tests against the staging API and Firebase project; verify network-offline playback and local Vault behavior.
7. Add production monitoring, backups/restore rehearsal, incident runbook and final privacy/security review.

## Android / Firebase identity

The rebuild branch aligns Android `namespace`, `applicationId` and package paths with `com.otya.omyplay`, matching the dedicated Firebase app registration. Keep Omy Play's Firebase project separate from Opoint's.

The Firebase Android App ID is not a signing certificate fingerprint. SHA-1/SHA-256 must come from the actual debug/upload/Play App Signing certificate. Never substitute a generated temporary key or use Opoint's key. The release SHA should be taken from Play Console once Play App Signing is configured; the upload key remains separately labelled.

Keep `google-services.json`, service-account credentials, signing keystores and passwords out of this public repository. Firebase is limited to FCM, App Check/Play Integrity, Crashlytics and Performance Monitoring; D1/R2 remain authoritative.

## Hard release gates

- No upload of local media/Vault content without explicit product design, user consent and privacy review.
- Push notification contents carry no sensitive account or transaction information; the app fetches authoritative state from the API.
- AI is disabled by default and cannot access local files, Vault or Opoint.
- Do not publish a production APK/AAB until package ID, Play listing, signing identity, Firebase App Check and upgrade behavior have passed on signed builds.

Canonical platform contract: [Otya End product backend and identity boundaries](https://github.com/OtyaHQ/OEnd/blob/product-ai-isolation-foundation-2026-11-11/docs/PRODUCT_BACKEND_AND_IDENTITY_BOUNDARIES.md).
