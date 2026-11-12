<div align="center">

<img src="assets/branding/otya_app_icon.webp" alt="Otya" width="112" height="112" />

# Omy Play

**Private. Powerful. Offline-first media.**

Omy Play is the local-first media application in the Otya ecosystem. Its Android application ID is `com.otya.omyplay` and its dedicated Firebase project is `omyplay-otya-prod`.

Omy Play combines local video and music playback, nearby Send, Private media, practical media tools and optional connected Together/account services without making core playback depend on the cloud.

[Otya](https://otya.site) · [Omy Play source](https://github.com/OtyaHQ/Omy_Play) · [Security](SECURITY.md)

</div>

---

## Product boundaries

- **OPoint** owns business, retail, inventory and financial operations. It has no access to Omy Play's private media.
- **OEnd** provides shared identity and approved backend services. Omy Play still owns its product API, database, storage and release workflow.
- **O** is the separate private owner-AI application. It does not receive local media, Private/Vault files or playback history.
- **OHub** is the public developer and partner documentation surface. Private credentials and internal operations do not belong there.
- **Otya ID** provides shared account identity and OTP. Telegram is never a sign-in provider; a linked Telegram bot may only deliver a code after the email identity has been established.

## Product surfaces

| Experience | Highlights |
|---|---|
| **Video** | Local video library, folders, playback, subtitles, PiP, gestures, aspect/orientation, queue and trim/extract |
| **Music** | Local songs, albums, artists, folders, playlists, search and background playback |
| **Me** | Send, Files, Private, playlists, history, tools, personalization, storage, account and settings |
| **Audio Player** | Queue, shuffle/repeat, speed, EQ, lyrics, sleep timer, background playback and media controls |
| **Send** | Authenticated same-Wi-Fi/hotspot media transfer without a cloud relay |
| **Private** | App-private media protection with device authentication/biometrics and secure PIN fallback |
| **Together** | Optional invited shared-watch sessions with host-controlled playback, temporary conversation, Moments and reactions |
| **Account** | Otya ID, email OTP, account recovery and explicitly linked delivery options |

## Offline-first guarantee

Local playback, media scanning, local search, folders, playlists, Send and Private must continue to work when the network, OEnd, Firebase or AI is unavailable.

Omy Play's music experience is based on media already on the device. The app does not require an online catalog to search or play local music. Removed provider integrations must not be re-enabled through stale remote configuration.

## Privacy and security

- Core media playback does not depend on Cloudflare, Firebase or AI.
- The app never uploads a user's local media library or Private/Vault content by default.
- Recovery is explicit and user-initiated; raw media files are not included in account recovery.
- Production secrets are never committed or bundled into Flutter.
- The Omy Play backend stores only the connected-service data it owns: app configuration, minimal device registrations, diagnostics, feedback, release metadata and Together control-plane data.
- FCM messages are notification hints only. The app fetches authoritative state from the Omy Play API.
- Internet-facing services use HTTPS. Cleartext HTTP is limited to authenticated same-LAN Send/Together links on private/local addresses.
- Production releases must be signed and fail closed when signing credentials are missing.

## Backend ownership

| Capability | Owner |
|---|---|
| Android media, playback, storage and Private | Omy Play app |
| Connected app configuration, diagnostics, release metadata and Together signaling | Omy Play backend |
| Shared account identity and OTP | Otya ID through OEnd |
| Push delivery and mobile integrity | Omy Play's dedicated Firebase project |
| Product data and private assets | Omy Play's dedicated Cloudflare D1 and R2 |
| Source control and release gates | OtyaHQ GitHub organization |

Firebase is a supporting mobile platform, not a second product database. Firestore and Firebase Storage are not required for Omy Play's initial backend.

## Release validation

A release is valid only when its exact immutable build tag and source commit agree, strict Flutter analysis and tests pass, publication-equivalent Android release binaries are verified, signing is proven, and release metadata points to those exact artifacts.

The public domain is being aligned to **otya.site**. Keep compatibility endpoints in code until their replacement routes are verified; do not publish unverified download or support URLs.

Do not publish source archives, internal deployment instructions, backend credentials, signing material, private endpoints or infrastructure inventories as customer documentation.

---

<div align="center">

**Omy Play · Otya**

</div>
