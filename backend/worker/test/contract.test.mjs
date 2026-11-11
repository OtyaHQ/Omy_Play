import test from "node:test";
import assert from "node:assert/strict";
import { validAbi, sanitizeCrashText } from "../src/index.mjs";

test("accepts only supported Android ABIs", () => {
  assert.equal(validAbi("arm64"), true);
  assert.equal(validAbi("ARM32"), true);
  assert.equal(validAbi("x86"), false);
  assert.equal(validAbi(""), false);
});

test("sanitizes crash paths, email, phone and credentials", () => {
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
