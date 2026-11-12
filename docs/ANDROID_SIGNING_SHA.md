# Android signing fingerprints (SHA-1 / SHA-256)

This document explains how to obtain the certificate fingerprints used by Firebase, Google OAuth and Play Integrity. A Firebase `google-services.json` file does **not** contain the app signing certificate SHA fingerprints.

## Omy Play identity

- Firebase project: `omyplay-otya-prod`
- Firebase project number: `181484175543`
- Firebase Android App ID: `1:181484175543:android:b7eae0234df6eb7e370d32`
- Android application ID: `com.otya.omyplay`

## Which SHA do we need?

There may be more than one certificate in the app lifecycle:

1. **Debug certificate** — signs local debug builds. Useful for debug-only Google OAuth/App Check testing.
2. **Upload certificate** — signs the AAB before uploading to Google Play. It proves the uploader's identity.
3. **Google Play app-signing certificate(s)** — sign the APKs delivered to devices when Play App Signing is used. These are the important production fingerprints for app recognition and third-party app identity.

Do not confuse the upload key with the Google Play app-signing key. If Play Console reports multiple signing certificates because key upgrade / quantum-ready signing is enabled, register each fingerprint required for the distribution path and API provider. Use the current certificates shown in Play Console, not an old screenshot or a debug keystore.

## Get the local debug SHA fingerprints

From a development computer with the Android Gradle project and JDK installed:

```bash
cd android
./gradlew signingReport
```

The task prints the SHA-1 and SHA-256 for each Gradle variant. The debug result is for local development only; do not use it as the production signing certificate.

To inspect a specific APK or certificate:

```bash
keytool -printcert -jarfile path/to/app.apk
keytool -printcert -file path/to/certificate.der
```

For a local keystore that you own, inspect its public certificate without exposing the private key:

```bash
keytool -list -v -keystore /secure/path/upload-keystore.jks -alias YOUR_ALIAS
```

Enter the keystore password locally when prompted. Never paste the password, private key or keystore file into GitHub, an issue, chat, a build log or a public repository.

## Get production fingerprints from Google Play

When the Omy Play app is created in Google Play Console and Play App Signing is configured:

1. Open the Omy Play app in Play Console.
2. Open **Test and release / Setup → App integrity** (the exact menu can vary as Play Console changes).
3. Open the **App signing key certificate** section.
4. Copy the SHA-256 and SHA-1 fingerprints for the app-signing certificate(s).
5. Keep the separate **Upload key certificate** fingerprints labelled as upload-only.
6. Register the Google Play app-signing SHA-256 in Firebase Project Settings → General → Your apps → SHA certificate fingerprints.
7. Also register the same SHA-256 with Firebase App Check → Apps → Omy Play Android app → Play Integrity provider.
8. In Google Cloud / Play Console, link Play Integrity to the same Google Cloud project backing `omyplay-otya-prod`.

For production API identities such as Google Sign-In, register the Play app-signing SHA-1 where the provider requires SHA-1. Do not replace the existing server OAuth client ID with a Firebase project number or app ID; they are different identifiers.

## App Check rollout

- Keep App Check in **monitor** mode while testing.
- Validate real installs from each intended distribution channel.
- Review App Check metrics and confirm all legitimate builds are recognized.
- Move to enforcement only after the test matrix passes and the owner approves the change.
- Debug provider tokens are for controlled developer builds only.

## Can Otya create the SHA for you?

A SHA fingerprint is derived from the actual signing certificate. It cannot be safely or correctly inferred from a Firebase project number, package name, app ID or API key.

The current development environment does not contain the Omy Play release keystore, Android Gradle/Flutter toolchain or Google Play app-signing certificate. Creating a throwaway key here would produce a fingerprint that would not match your final Play-distributed app. We will not generate a fake production fingerprint.

The production SHA becomes available from Play Console after the app is set up with Play App Signing. The local debug SHA can be generated on a development computer with `./gradlew signingReport`.

## Official references

- Firebase App Check / Play Integrity setup: https://firebase.google.com/docs/app-check/android/play-integrity-provider
- Google Play App Signing: https://support.google.com/googleplay/android-developer/answer/9842756
- Android client authentication and `signingReport`: https://developers.google.com/android/guides/client-auth
