# Otya Media — Ecosystem Integration Boundaries

Otya Media is the local-first media product in the Otya family. This contract coordinates integrations without allowing shared infrastructure or AI to break core playback.

## Local-first guarantee

- Browsing and playing local audio/video, playlists, captions, playback controls and supported local tools must not require Cloudflare, Otya End, Leo, Resend or an AI provider.
- Authentication is required only for features that need an account or shared service.
- Network loss, expired account session, unavailable AI, backend outage or provider timeout must not block the local media library.
- Never upload a user's raw media library, Private media, or local search queries for unrelated purposes.

## Shared-service boundaries

- **Otya End:** account/session and explicitly enabled shared APIs; no general access to local/private media.
- **Leo / Otya Next:** owner-only operational AI; consumer Otya Media does not inherit owner permissions or tools.
- **OtyaPoint:** separate shop/agency data domain; no access to personal media or media account secrets.
- **OtyaHub:** public docs and release information only; no internal credentials, private logs or private infrastructure inventories.
- **Resend:** transactional notifications only where a user action or service policy requires them; never send private media details by default.

## Hybrid operation

The app may use local/device capabilities plus optional Cloudflare services. Network-backed features must declare required identity/permissions; data sent and retention; timeout/retry behavior; offline/degraded behavior; account/feature fallback; and explicit user consent where data leaves the device.

The Android UI must distinguish local success from remote completion. A local file transfer prepared on-device is not reported as received by the peer until the receiving side confirms it.

## Releases and reliability

- Keep release artifacts signed and checksummed.
- Do not bundle server credentials or owner tokens into the APK.
- Preserve app IDs, package names, release channels and public links until a reviewed compatibility migration is approved.
- Validate cold start, resume, audio focus, playback service registration, storage permissions, Private/Vault lock state, Send peer verification and Together-session failure paths.
- A successful GitHub workflow is necessary but not sufficient; release acceptance includes exact artifact identity and physical-device tests.
- AI/provider failures must never block playback or be required for core media controls.

## Cross-ecosystem incident reporting

When an issue spans services, create one parent issue/incident and link affected repository issues. Each product retains a bounded remediation task, and Leo summarizes dependencies, evidence, decisions and verification without duplicating underlying business data.
