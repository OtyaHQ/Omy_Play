# Omy Play backend

The dedicated product backend for **Omy Play**. It owns only connected-service data; local media, playback, folders and Private/Vault content remain on the device.

## Production runtime

| Component | Production resource |
|---|---|
| Cloudflare Worker | `omy-play` |
| Public API base | `https://api.otya.site/omy-play` |
| Worker access | Private Worker reached through the OEnd API route; no `workers.dev` endpoint |
| D1 | `omy-play-prod-db` |
| R2 | `omy-play-prod-assets` |
| Shared identity | OID through OEnd's production identity service |
| Firebase project | `omyplay-otya-prod` |
| Android package | `com.otya.omyplay` |

The production D1 schema and migration ledger are applied. The production database contains the real app configuration and four existing Omy Play theme definitions transferred from the previous service store. It has no registered devices, crash reports, ratings, feedback, Together sessions, notifications or releases.

## Responsibilities

App configuration, version/update metadata, release metadata, device registration, crash intake, feedback, ratings, theme catalogue, notifications and Together signaling. It does not store users' local media libraries, music/video files, Vault content or raw playback history.

Routes are served under the single product prefix `/omy-play`, including `/api/app-config`, `/api/themes`, `/api/device`, `/api/feedback`, `/api/crash-report`, `/api/version`, `/latest`, `/apk/arm32`, `/apk/arm64` and their versioned `/v1/*` counterparts.

The configuration response exposes `config` for the Android remote-control client and retains `data` as a documented API alias. Theme responses expose `themes` and the `data` alias.

## Security and operating rules

- The Worker is not exposed on `workers.dev`; Cloudflare observability is enabled and query strings are redacted.
- OID is the sole identity provider. Omy Play does not own or duplicate an identity database.
- FCM registration tokens are encrypted at rest with a unique production AES-256-GCM Worker secret. The secret is not stored in Git.
- FCM sending remains disabled until the production sender credential, retry/DLQ handling and real device delivery checks are completed.
- AI is disabled for this backend. Omy Play core playback remains local-first and independent of Cloudflare, Firebase and AI.
- The R2 bucket is private. Published APKs must be signed, immutable, checksum-verified and linked to a real production release record.
- Do not insert placeholder devices, accounts, releases, feedback or ratings to make dashboards appear populated.

## Source and deployment

- Canonical Worker source: `backend/src/index.mjs`.
- Schema-only bootstrap: `backend/schema/bootstrap.sql`.
- Production Worker configuration: `wrangler.omy-play-production.toml`.
- Backend validation: `npm --prefix backend run check`, `npm --prefix backend test` and `npm --prefix backend run verify:schema`.
- Production deployment uses the dedicated manual workflow and must pass live health, configuration, theme and unauthenticated-access smoke checks.

A healthy API schema is not proof of a signed app release, device delivery or store publication. Publish those only after the real signing and device acceptance checks pass.
