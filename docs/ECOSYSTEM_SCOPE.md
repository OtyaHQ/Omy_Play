# Otya Media ecosystem scope

Otya Media is the offline-first media product operated by Otya Hold Ltd.

- Local playback, library, playlists, Private/Vault and local Send remain the app's responsibility.
- Core playback and local library access must work without Otya Server, Cloudflare, identity or AI.
- Local media remains on-device by default.
- Otya Server may provide account/session contracts for connected features.
- OtyaHub publishes public documentation and safe release information only.
- Next owner permissions do not transfer to the consumer media app.
- Release signing material and provider credentials belong in protected server/release infrastructure, never in the APK or source.

This document defines boundaries, not deployment status. Each connected feature requires its own security and release validation.
