import test from "node:test";
import assert from "node:assert/strict";
import { validAbi, sanitizeCrashText, encryptFcmToken, decryptFcmToken } from "../src/index.mjs";

const TEST_KEY = "AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8=";
const TEST_ENV = { FCM_TOKEN_ENCRYPTION_KEY: TEST_KEY };

test("accepts only supported Android ABIs", () => {
  assert.equal(validAbi("arm64"), true);
  assert.equal(validAbi("ARM32"), true);
  assert.equal(validAbi("x86"), false);
  assert.equal(validAbi(""), false);
});

test("sanitizes full crash paths, email, phone and credentials", () => {
  const raw = [
    "Email peter@example.com",
    "Bearer abcdefghijklmnopqrstuvwxyz",
    "/data/user/0/com.otya.omyplay/files/private.db",
    "/storage/emulated/0/Music/song.mp3",
    "+256 772 123 456",
  ].join(" ");
  const safe = sanitizeCrashText(raw);
  assert.match(safe, /<email>/);
  assert.match(safe, /<redacted-token>/);
  assert.match(safe, /<app-data>/);
  assert.match(safe, /<device-storage>/);
  assert.match(safe, /<phone>/);
  assert.doesNotMatch(safe, /peter@example\.com|abcdefghijklmnopqrstuvwxyz|private\.db|song\.mp3/);
});

test("encrypts FCM tokens with a random IV and authenticated decryption", async () => {
  const token = "fcm-device-token-test-value-123456789";
  const first = await encryptFcmToken(token, TEST_ENV);
  const second = await encryptFcmToken(token, TEST_ENV);
  assert.match(first, /^v1:[A-Za-z0-9_-]+:[A-Za-z0-9_-]+$/);
  assert.notEqual(first, second);
  assert.equal(first.includes(token), false);
  assert.equal(await decryptFcmToken(first, TEST_ENV), token);
});

test("fails closed when the FCM encryption key is absent or malformed", async () => {
  await assert.rejects(() => encryptFcmToken("fcm-device-token-test-value-123456", {}));
  await assert.rejects(() => encryptFcmToken("fcm-device-token-test-value-123456", { FCM_TOKEN_ENCRYPTION_KEY: "not-a-valid-key" }));
});
