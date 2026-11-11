# Omy Play Firebase identity and Android package migration

## Verified identifiers

The Android application ID currently present on the compatibility/rebrand branch is `com.otyaplayer.app` (Gradle namespace, applicationId and manifest package). The Firebase Android App ID previously supplied for Omy Play is:

- Firebase project ID: `omyplay-otya-prod`
- Project number / sender ID: `181484175543`
- Firebase Android App ID: `1:181484175543:android:b7eae0234df6eb7e370d32`
- Package associated with that registration: `com.otya.omyplay`

These package identifiers do not match. A Firebase Android App registration is package-specific. Do not copy a `google-services.json` for `com.otya.omyplay` into a build whose application ID is `com.otyaplayer.app`.

## Safe default

Preserve `com.otyaplayer.app` on the compatibility/rebrand branch until the Play Console listing, prior release artifacts and signing identity are checked. The display name can become Omy Play without changing the Android package.

If preserving the existing package, register an additional Android app in the dedicated `omyplay-otya-prod` Firebase project using package `com.otyaplayer.app`, download its own `google-services.json`, and verify its project ID, sender ID, app ID and package before building. Keep the existing `com.otya.omyplay` registration intact; do not overwrite or delete it.

## Optional clean package migration

Only use `com.otya.omyplay` as the release application ID if the owner confirms that no public Play listing or installed production users need upgrade continuity, and the signing/distribution plan explicitly accepts a new app identity. A package-ID change is not an in-place Android app update. Before that decision, run the complete Android package/path, deep-link, notification, OAuth, Firebase, crash telemetry and release-artifact checks.

## Firebase service boundaries

Firebase is limited to FCM, App Check / Play Integrity, Crashlytics and Performance Monitoring. Omy Play's Cloudflare backend and D1/R2 remain authoritative. Do not use Firestore or Firebase Storage as a parallel product database. Private/Vault media and local media indexes remain on-device by default.

Never commit service-account JSON, signing keystores or private keys. The client `google-services.json` must be private build configuration if repository visibility is public.
