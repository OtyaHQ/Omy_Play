import test from "node:test";
import assert from "node:assert/strict";
import worker, { sanitizeCrashText, validAbi, encryptFcmToken, decryptFcmToken, REQUIRED_TABLES, REQUIRED_MIGRATIONS } from "../src/index.mjs";

test("Omy Play ABI contract accepts only supported release splits", () => {
  assert.equal(validAbi("arm64"), true);
  assert.equal(validAbi("arm32"), true);
  assert.equal(validAbi("x86_64"), false);
  assert.equal(validAbi("../arm64"), false);
});

test("crash text redacts application data paths, emails, phones and bearer-like tokens", () => {
  const value = sanitizeCrashText("open /data/user/0/com.otya.omyplay/files/private.mp4 peter@example.com +256 700 123456 Bearer abcdefghijklmnop");
  assert.doesNotMatch(value, /\/data\/user\/0/);
  assert.doesNotMatch(value, /peter@example.com/);
  assert.doesNotMatch(value, /\+256 700 123456/);
  assert.doesNotMatch(value, /abcdefghijklmnop/);
  assert.match(value, /<app-data>/);
  assert.match(value, /<email>/);
  assert.match(value, /<phone>/);
});

test("Omy Play readiness contract contains only media-product schema", () => {
  assert.ok(REQUIRED_TABLES.includes("theme_catalog"));
  assert.ok(REQUIRED_TABLES.includes("together_rooms"));
  assert.ok(!REQUIRED_TABLES.includes("companies"));
  assert.deepEqual(REQUIRED_MIGRATIONS, ["0001_omy_play_core"]);
});

test("protected notifications reject missing bearer tokens", async () => {
  let queried = false;
  const env = { DB: { prepare() { queried = true; throw new Error("unexpected database read"); } } };
  const response = await worker.fetch(new Request("https://omy-play-staging.invalid/v1/notifications"), env);
  assert.equal(response.status, 401);
  assert.equal(queried, false);
});

test("health reports unavailable if the dedicated database is not bound", async () => {
  const response = await worker.fetch(new Request("https://omy-play-staging.invalid/health"), {});
  assert.equal(response.status, 503);
});

test("FCM tokens are encrypted at rest and can be decrypted by the server worker", async () => {
  const secret = Buffer.from(Array.from({ length: 32 }, (_, index) => index + 1)).toString("base64");
  const token = "fcm-registration-token-0123456789abcdef";
  const encrypted = await encryptFcmToken(token, secret);
  assert.equal(encrypted.ok, true);
  assert.notEqual(encrypted.value, token);
  assert.match(encrypted.value, /^v1\./);
  const decrypted = await decryptFcmToken(encrypted.value, secret);
  assert.deepEqual(decrypted, { ok: true, value: token });
});

test("FCM token encryption fails closed when the encryption key is absent or malformed", async () => {
  const token = "fcm-registration-token-0123456789abcdef";
  assert.equal((await encryptFcmToken(token, undefined)).error, "fcm_token_encryption_not_configured");
  assert.equal((await encryptFcmToken(token, "not-a-valid-32-byte-key")).error, "fcm_token_encryption_not_configured");
});

test("FCM ciphertext cannot be decrypted with a different key", async () => {
  const keyA = Buffer.alloc(32, 1).toString("base64");
  const keyB = Buffer.alloc(32, 2).toString("base64");
  const encrypted = await encryptFcmToken("fcm-registration-token-0123456789abcdef", keyA);
  const decrypted = await decryptFcmToken(encrypted.value, keyB);
  assert.equal(decrypted.ok, false);
  assert.equal(decrypted.error, "fcm_token_decryption_failed");
});
