# Omy Play Firebase setup

**Product:** Omy Play  
**Environment:** dedicated product project  
**Status:** Android app registration verified; release attestation and server push credentials remain pending

## Verified Firebase identity

| Field | Value |
|---|---|
| Firebase project ID | omyplay-otya-prod |
| Project number / sender ID | 181484175543 |
| Firebase Android App ID | 1:181484175543:android:b7eae0234df6eb7e370d32 |
| Android application ID | com.otya.omyplay |

The Android Gradle applicationId, namespace, Android manifest and Firebase google-services.json must all resolve to this same Android package. Opoint must use its own separate Firebase project and package.

## Allowed Firebase services

- **Firebase Cloud Messaging:** delivery of non-sensitive notification hints. A push message never proves a payment, entitlement, account state or release integrity; the app must fetch authoritative state from the Omy Play API.
- **App Check:** Play Integrity for released Android builds. Keep enforcement in monitoring mode while signing and distribution are validated; then enable enforcement after device coverage is confirmed.
- **Crashlytics:** crash diagnostics, with paths and personally identifying data removed before upload.
- **Performance Monitoring:** app startup, network and rendering performance.
- **Analytics:** only with a documented consent and data-minimization policy.

## Services not required

Do not enable Firestore or Firebase Storage as a second source of truth for product data. The Omy Play backend uses its own Cloudflare D1 and R2 resources. Private/Vault media and the user's local media index remain on-device and must not be uploaded to Firebase or Otya AI by default.

## Client and server credentials

- The Android google-services.json file is public client configuration, not a server private key. Restrict the Firebase API key to the APIs and Android package that the app needs.
- FCM Admin credentials belong only in the Omy Play Cloudflare secret store. Do not commit service-account JSON, private keys or OAuth client secrets to GitHub or the mobile app.
- Omy Play must not reuse Opoint's Firebase service account or its old Otya Player credentials.
- The staging Worker identifies the Firebase project as omyplay-otya-prod; it currently stores device tokens but does not yet send FCM messages.

## Signing certificate fingerprints (SHA-1 / SHA-256)

Firebase App IDs do not contain signing certificate fingerprints. Obtain fingerprints from the actual debug, upload or Play App Signing certificate:

    cd android
    ./gradlew signingReport

For a keystore file:

    keytool -list -v -keystore <keystore-file> -alias <key-alias>

Use separate upload keys for Omy Play and Opoint. Keep the keystore and passwords in an appropriate password manager/secure backup, not in the repository. Add only the required SHA fingerprints to Firebase. The Play App Signing certificate is the relevant production identity when Google Play App Signing is enabled.

## Release gates

Before production release:
1. Verify applicationId and google-services.json package match com.otya.omyplay.
2. Record the actual release/upload SHA-1 and SHA-256 fingerprints.
3. Configure App Check Play Integrity and test a signed release build.
4. Configure Crashlytics and Performance Monitoring.
5. Store a dedicated Omy Play FCM service credential in Cloudflare Secrets Store, then add an outbox/queue consumer with retry and dead-letter handling.
6. Verify no local media, Private/Vault content or media identifiers are sent to cloud services by default.
7. Confirm the app can still play and manage local media with network and AI unavailable.

## FCM token storage hardening

The staging Worker now encrypts FCM registration tokens with AES-256-GCM before writing them to the existing D1 `devices.fcm_token` field. The corresponding SHA-256 token hash remains available for deduplication. The Worker fails closed with `fcm_token_encryption_not_configured` when a token is submitted without a valid key; it never falls back to plaintext storage.

Before testing device registration, create a random 32-byte encryption key, base64-encode it, and store it as the Worker secret `FCM_TOKEN_ENCRYPTION_KEY` for the Omy Play staging Worker only. Do not commit the key or send it in chat. Production must use a separately generated key and documented rotation procedure. Key rotation must support decrypting existing ciphertext during a migration window or re-encrypting all stored tokens before the old key is retired.

FCM sending remains disabled until the Admin credential is configured, token decryption is tested, Queue retry/dead-letter behavior is implemented, and the app verifies authoritative state from the API after every push.
