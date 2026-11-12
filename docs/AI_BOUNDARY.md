# Omy Play AI boundary

**Default:** AI disabled. Omy Play is local-first, and core media behavior must remain independent of cloud services.

Omy Play Assistant may eventually answer app-use questions, help troubleshoot errors and summarize opt-in diagnostics. It must not become a remote media-library scanner.

## Local-data protections

- Playback, scanning, playlists, history, file operations, Private/Vault and local transfer remain on-device.
- No media bytes, thumbnails, file paths, Vault records, playlist content or local media index are sent to AI by default.
- Diagnostic sharing must be explicit, previewable and limited to the specific report the user submits.
- The backend may return app configuration, release information and help content, but it cannot inspect local files.

## Future allowed capability

- Answer Omy Play product and settings questions.
- Explain release/update state using public release metadata.
- Summarize a crash report only after sensitive paths, tokens, emails and phone-like values have been removed.
- Draft feedback text locally for user review; submitting remains a user action.

No AI tool may read Opoint data, shared owner memory or another user's Omy Play account records.

Canonical policy: [Otya End AI product isolation and execution policy](https://github.com/OtyaHQ/OEnd/blob/product-ai-isolation-foundation-2026-11-11/docs/AI_PRODUCT_ISOLATION_AND_EXECUTION_POLICY.md).
