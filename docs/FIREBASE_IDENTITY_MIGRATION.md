# Omy Play Firebase identity and Android package decision

## Canonical Omy Play identity

The current Omy Play rebuild uses:

- Android namespace: `com.otya.omyplay`
- Android application ID: `com.otya.omyplay`
- Firebase project ID: `omyplay-otya-prod`
- Firebase project number / sender ID: `181484175543`
- Firebase Android App ID: `1:181484175543:android:b7eae0234df6eb7e370d32`

The Firebase registration and Android application ID match. The new Omy Play release workflow must verify the packaged APK application ID before publishing either ABI.

## Legacy Otya Player compatibility

Older Otya Player test artifacts used `com.otyaplayer.app` and were published under legacy Otya release names. They are not Omy Play release artifacts.

- Do not rename, relabel or overwrite old Otya Player APKs as Omy Play.
- Do not publish old Otya Player objects through the canonical Omy Play download endpoints.
- Keep legacy downloads and metadata separate until the owner deliberately retires those URLs.
- An Android application ID change creates a distinct app identity; it is not an in-place update for an existing installation.

The Omy Play rebuild is intentionally being treated as a new product identity under the owner's direction that prior ecosystem data and usage were testing-only. Before the first public Omy Play release, verify in the relevant distribution console that `com.otya.omyplay` is available for the intended release channel and confirm the signing/distribution plan. Do not claim an existing store listing or upgrade path unless it is independently verified.

## Firebase boundaries

Firebase is limited to Omy Play's mobile platform needs:

- Firebase Cloud Messaging
- App Check / Play Integrity
- Crashlytics
- Performance Monitoring

Cloudflare remains the Omy Play backend and data authority. D1/R2 own connected product data and assets. Firestore and Firebase Storage are not required as parallel product databases. Local media, Private/Vault media and media indexes remain on-device by default.

The Omy Play release workflow must use only Omy Play-specific Firebase project settings and a separately provisioned Omy Play service-account credential. It must never reuse the legacy Otya Player Firebase service account.

Never commit service-account JSON, signing keystores, private keys or production tokens. Keep client configuration in the approved private build-configuration process and verify its `project_id`, `project_number`, `mobilesdk_app_id` and `package_name` before a release.
