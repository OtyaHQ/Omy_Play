# Omy Play backend architecture

**Product:** Omy Play  
**Runtime:** Cloudflare Worker (staging service: `omy-play-api-staging`)  
**Source package:** `backend/`  
**Data store:** dedicated Omy Play D1 staging database  
**Assets:** dedicated private R2 staging bucket  
**Cache:** dedicated KV namespace  
**Identity:** Otya ID through a service binding

## Purpose

Omy Play's backend is an optional companion to the local-first Android application. It does not own playback or the user's local media library. Playback, search, file scanning, local tools and the Private area must continue when every network service is unavailable.

## Product-owned API capabilities

The backend package currently covers:
- health and schema readiness;
- remote app configuration and theme catalog;
- device registration and FCM token lifecycle;
- privacy-conscious crash/diagnostic intake;
- feedback and ratings;
- release metadata and compatibility download routes;
- notification inbox and push delivery integration points;
- Together room membership and short-lived signaling/control metadata.

It does not implement Opoint or financial records. It does not ingest raw local-media or Private/Vault files. AI is disabled by default.

## Resource boundaries

Omy Play owns its database, R2 staging bucket, KV cache, Worker identity, Firebase project, package identity and release workflow. Otya ID remains the shared identity source; the service verifies tokens server-side. A shared identity does not grant Omy Play access to Opoint data.

## Firebase

- Project: `omyplay-otya-prod`
- Android package: `com.otya.omyplay`
- App Check: Play Integrity, initially monitor mode
- FCM: notification transport only

Never use Firebase Storage or Firestore as the playback library or media backup. Never put service-account credentials in the Android bundle or Git repository.

## Status and gates

The staging D1 schema has been applied and checked: 13 product tables, 4 active theme seeds, 1 default configuration record, no device records and no foreign-key violations. The backend source package has unit/contract tests and schema tests.

**This repository branch still needs the backend package to be checked into Git, then deployed and smoke-tested against the staging Worker before the backend can be marked integrated.** The existing shared production Worker and old release paths remain untouched until the new Worker is validated and a cutover is separately approved.

## Latest validation — 11 November 2026

- JavaScript syntax validation: passed.
- Worker contract tests: 8/8 passed.
- Schema verifier: passed (13 product tables, default config, four active themes, foreign keys).
- Dedicated Firebase registration: `omyplay-otya-prod`, app ID `1:181484175543:android:b7eae0234df6eb7e370d32`, package `com.otya.omyplay`.
- Backend source package artifact: isolated under `backend/` in the downloadable foundation archive. It is not yet copied into this GitHub branch or deployed as a Cloudflare Worker.

A test found and fixed an application-identity privacy regression: the crash telemetry scrubber previously redacted only the retired package path. It now redacts app-data paths generically, and regression coverage checks both new and legacy package names.
