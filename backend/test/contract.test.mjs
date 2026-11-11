import test from "node:test";
import assert from "node:assert/strict";
import worker, { sanitizeCrashText, validAbi, REQUIRED_TABLES, REQUIRED_MIGRATIONS } from "../src/index.mjs";

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
