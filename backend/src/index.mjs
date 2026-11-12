const REQUIRED_TABLES = [
  "app_config", "devices", "crash_reports", "download_events", "feedback",
  "omy_schema_migrations", "rate_limits", "ratings", "releases",
  "theme_catalog", "together_rooms", "together_signals", "user_notifications",
];
const REQUIRED_MIGRATIONS = ["0001_omy_play_core"];
const ALLOWED_ABIS = new Set(["arm64", "arm32"]);

const json = (body, status = 200, requestId = undefined) => new Response(JSON.stringify(body), {
  status,
  headers: {
    "content-type": "application/json; charset=utf-8",
    "cache-control": "private, no-store",
    "x-content-type-options": "nosniff",
    "referrer-policy": "no-referrer",
    "permissions-policy": "camera=(), microphone=(), geolocation=()",
    "content-security-policy": "default-src 'none'; frame-ancestors 'none'",
    ...(requestId ? { "x-request-id": requestId } : {}),
  },
});

const clean = (value, max = 240) => typeof value === "string"
  ? value.replace(/[\u0000-\u001f\u007f]/g, " ").trim().slice(0, max)
  : "";

function decodeBase64(value) {
  const normalized = value.replace(/-/g, "+").replace(/_/g, "/");
  const binary = atob(normalized.padEnd(Math.ceil(normalized.length / 4) * 4, "="));
  return Uint8Array.from(binary, character => character.charCodeAt(0));
}

function encodeBase64(bytes) {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary);
}

async function importFcmEncryptionKey(secret, usage) {
  if (typeof secret !== "string" || !secret.trim()) return null;
  try {
    const raw = decodeBase64(secret.trim());
    if (raw.byteLength !== 32) return null;
    return await crypto.subtle.importKey("raw", raw, { name: "AES-GCM" }, false, [usage]);
  } catch {
    return null;
  }
}

export async function encryptFcmToken(token, secret) {
  if (typeof token !== "string" || token.length < 20 || token.length > 4096) {
    return { ok: false, error: "invalid_fcm_token" };
  }
  const key = await importFcmEncryptionKey(secret, "encrypt");
  if (!key) return { ok: false, error: "fcm_token_encryption_not_configured" };
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const encrypted = new Uint8Array(await crypto.subtle.encrypt(
    { name: "AES-GCM", iv },
    key,
    new TextEncoder().encode(token),
  ));
  return { ok: true, value: "v1." + encodeBase64(iv) + "." + encodeBase64(encrypted) };
}

export async function decryptFcmToken(value, secret) {
  if (typeof value !== "string") return { ok: false, error: "invalid_ciphertext" };
  const parts = value.split(".");
  if (parts.length !== 3 || parts[0] !== "v1") return { ok: false, error: "unsupported_ciphertext_version" };
  const key = await importFcmEncryptionKey(secret, "decrypt");
  if (!key) return { ok: false, error: "fcm_token_encryption_not_configured" };
  try {
    const decrypted = await crypto.subtle.decrypt(
      { name: "AES-GCM", iv: decodeBase64(parts[1]) },
      key,
      decodeBase64(parts[2]),
    );
    return { ok: true, value: new TextDecoder().decode(decrypted) };
  } catch {
    return { ok: false, error: "fcm_token_decryption_failed" };
  }
}

export function validAbi(value) {
  return ALLOWED_ABIS.has(String(value || "").toLowerCase());
}

export function sanitizeCrashText(value, max = 4000) {
  return clean(value, max)
    .replace(/(?:\/data\/user\/\d+\/[^/\s]+|\/data\/data\/[^/\s]+)/gi, "<app-data>")
    .replace(/\/storage\/emulated\/\d+/gi, "<device-storage>")
    .replace(/[A-Z]:\\Users\\[^\\\s]+/gi, "<user-path>")
    .replace(/\/home\/[^/\s]+/gi, "<user-path>")
    .replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, "<email>")
    .replace(/\+?[0-9][0-9 ()-]{7,}[0-9]/g, "<phone>")
    .replace(/\b(?:bearer|token|authorization)\s*[:=]?\s*[A-Za-z0-9._~-]{12,}/gi, "<redacted-token>")
    .slice(0, max);
}

async function sha256(value) {
  const digest = new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(String(value))));
  return Array.from(digest, byte => byte.toString(16).padStart(2, "0")).join("");
}

async function readJson(request, maxBytes = 16_384) {
  const text = await request.text();
  if (new TextEncoder().encode(text).byteLength > maxBytes) return { error: "request_too_large", status: 413 };
  try {
    const value = JSON.parse(text);
    if (!value || typeof value !== "object" || Array.isArray(value)) return { error: "invalid_json_object", status: 400 };
    return { value };
  } catch {
    return { error: "invalid_json", status: 400 };
  }
}

async function verifyIdentity(request, env, optional = false) {
  const authorization = request.headers.get("authorization") || "";
  if (!authorization) return optional ? { identity: null } : { response: json({ error: "unauthorized" }, 401) };
  if (!authorization.startsWith("Bearer ") || authorization.length > 8192) return { response: json({ error: "unauthorized" }, 401) };
  if (!env.OTYA_ID?.fetch) return { response: json({ error: "identity_service_unavailable" }, 503) };
  try {
    const response = await env.OTYA_ID.fetch(new Request("https://auth/auth/verify", {
      method: "GET",
      headers: { authorization, accept: "application/json" },
      signal: AbortSignal.timeout(8000),
    }));
    if (!response.ok) return { response: json({ error: "unauthorized" }, 401) };
    const data = await response.json();
    if (data?.ok !== true || typeof data.user_id !== "string" || !data.user_id.trim()) {
      return { response: json({ error: "unauthorized" }, 401) };
    }
    return { identity: { userId: data.user_id, email: typeof data.email === "string" ? data.email.toLowerCase() : null } };
  } catch {
    return { response: json({ error: "identity_service_unavailable" }, 503) };
  }
}

async function rateAllowed(request, env, scope, limit) {
  const ip = request.headers.get("cf-connecting-ip") || "unknown";
  const scopeKey = scope + ":" + await sha256(ip);
  const now = Math.floor(Date.now() / 1000);
  const windowStart = Math.floor(now / 60) * 60;
  await env.DB.prepare(
    "INSERT INTO rate_limits (scope_key,window_start,request_count) VALUES (?1,?2,1) ON CONFLICT(scope_key) DO UPDATE SET window_start=CASE WHEN rate_limits.window_start < excluded.window_start THEN excluded.window_start ELSE rate_limits.window_start END, request_count=CASE WHEN rate_limits.window_start < excluded.window_start THEN 1 ELSE rate_limits.request_count+1 END"
  ).bind(scopeKey, windowStart).run();
  const row = await env.DB.prepare("SELECT request_count FROM rate_limits WHERE scope_key=?1 LIMIT 1").bind(scopeKey).first();
  return Number(row?.request_count || 0) <= limit;
}

async function handleConfig(env, requestId) {
  const row = await env.DB.prepare("SELECT revision,config_json,updated_at FROM app_config WHERE config_id='default' LIMIT 1").first();
  if (!row) return json({ error: "configuration_unavailable", requestId }, 503, requestId);
  try {
    return json({ data: JSON.parse(row.config_json), revision: row.revision, updatedAt: row.updated_at, requestId }, 200, requestId);
  } catch {
    return json({ error: "configuration_invalid", requestId }, 503, requestId);
  }
}

async function handleThemes(env, requestId) {
  const result = await env.DB.prepare("SELECT theme_id,position,theme_json,updated_at FROM theme_catalog WHERE status='ACTIVE' ORDER BY position,theme_id").all();
  const themes = [];
  for (const row of result.results || []) {
    try { themes.push({ id: row.theme_id, ...JSON.parse(row.theme_json) }); } catch { /* Skip invalid catalogue row; report remaining valid entries. */ }
  }
  return json({ data: themes, requestId }, 200, requestId);
}

async function registerDevice(request, env, identity, body, requestId) {
  const deviceId = clean(body.deviceId ?? body.device_id, 128);
  const appVersion = clean(body.appVersion ?? body.app_version ?? "0.0.0", 32) || "0.0.0";
  const versionCode = body.versionCode ?? body.version_code ?? 0;
  const abi = clean(body.abi ?? "unknown", 24).toLowerCase();
  const platform = clean(body.platform ?? "android", 24).toLowerCase();
  const model = clean(body.model, 120) || null;
  const androidVersion = clean(body.androidVersion ?? body.android_version, 48) || null;
  const locale = clean(body.locale, 24) || null;
  const token = clean(body.fcmToken ?? body.fcm_token, 4096);
  if (!/^[A-Za-z0-9._:-]{8,128}$/.test(deviceId)) return json({ error: "invalid_device_id", requestId }, 400, requestId);
  if (!Number.isSafeInteger(versionCode) || versionCode < 0) return json({ error: "invalid_version_code", requestId }, 400, requestId);
  if (!["arm64", "arm32", "x86", "x86_64", "unknown"].includes(abi)) return json({ error: "invalid_abi", requestId }, 400, requestId);
  if (platform !== "android") return json({ error: "unsupported_platform", requestId }, 400, requestId);
  if (body.fcmToken != null || body.fcm_token != null) {
    if (token.length < 20) return json({ error: "invalid_fcm_token", requestId }, 400, requestId);
  }
  const tokenHash = token ? await sha256(token) : null;
  let storedToken = null;
  if (token) {
    const encrypted = await encryptFcmToken(token, env.FCM_TOKEN_ENCRYPTION_KEY);
    if (!encrypted.ok) return json({ error: encrypted.error, requestId }, 503, requestId);
    storedToken = encrypted.value;
  }
  await env.DB.prepare(
    "INSERT INTO devices (device_id,user_id,fcm_token,fcm_token_hash,app_version,version_code,abi,platform,model,android_version,locale,registered_at,last_seen_at,disabled_at) VALUES (?1,?2,?3,?4,?5,?6,?7,?8,?9,?10,?11,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,NULL) ON CONFLICT(device_id) DO UPDATE SET user_id=excluded.user_id,fcm_token=COALESCE(excluded.fcm_token,devices.fcm_token),fcm_token_hash=COALESCE(excluded.fcm_token_hash,devices.fcm_token_hash),app_version=excluded.app_version,version_code=excluded.version_code,abi=excluded.abi,platform=excluded.platform,model=excluded.model,android_version=excluded.android_version,locale=excluded.locale,last_seen_at=CURRENT_TIMESTAMP,disabled_at=NULL"
  ).bind(deviceId, identity?.userId || null, storedToken, tokenHash, appVersion, versionCode, abi, platform, model, androidVersion, locale).run();
  return json({ data: { deviceId, registered: true }, requestId }, 200, requestId);
}

async function createCrash(request, env, identity, body, requestId) {
  const errorType = sanitizeCrashText(body.errorType ?? body.error_type ?? "Error", 160) || "Error";
  const description = sanitizeCrashText(body.description ?? body.message ?? "", 1400);
  const stackTrace = sanitizeCrashText(body.stackTrace ?? body.stack_trace ?? "", 6000);
  if (!description && !stackTrace) return json({ error: "crash_details_required", requestId }, 400, requestId);
  const deviceId = clean(body.deviceId ?? body.device_id, 128) || null;
  const appVersion = clean(body.appVersion ?? body.app_version, 32) || null;
  const versionCode = Number.isSafeInteger(body.versionCode ?? body.version_code) && Number(body.versionCode ?? body.version_code) >= 0
    ? Number(body.versionCode ?? body.version_code) : null;
  const groupId = "crash-" + (await sha256((errorType + "\n" + description + "\n" + stackTrace).toLowerCase())).slice(0, 32);
  await env.DB.prepare(
    "INSERT INTO crash_reports (id,group_id,device_id,user_id,app_version,version_code,error_type,description,stack_trace) VALUES (?1,?2,?3,?4,?5,?6,?7,?8,?9)"
  ).bind(crypto.randomUUID(), groupId, deviceId, identity?.userId || null, appVersion, versionCode, errorType, description, stackTrace).run();
  return json({ data: { accepted: true, groupId }, requestId }, 202, requestId);
}

async function createFeedback(request, env, identity, body, requestId) {
  const description = clean(body.description, 3000);
  const category = clean(body.category || "other", 32).toLowerCase();
  const allowed = new Set(["bug", "feature_request", "complaint", "praise", "other"]);
  if (description.length < 5) return json({ error: "feedback_required", requestId }, 400, requestId);
  if (!allowed.has(category)) return json({ error: "invalid_feedback_category", requestId }, 400, requestId);
  const email = clean(body.email ?? body.userEmail, 254).toLowerCase() || null;
  if (email && !/^[^\s@<>]+@[^\s@<>]+\.[^\s@<>]+$/.test(email)) return json({ error: "invalid_email", requestId }, 400, requestId);
  const id = crypto.randomUUID();
  await env.DB.prepare(
    "INSERT INTO feedback (id,device_id,user_id,app_version,version_code,category,description,user_email) VALUES (?1,?2,?3,?4,?5,?6,?7,?8)"
  ).bind(id, clean(body.deviceId ?? body.device_id, 128) || null, identity?.userId || null, clean(body.appVersion ?? body.app_version, 32) || null, Number.isSafeInteger(body.versionCode ?? body.version_code) ? Number(body.versionCode ?? body.version_code) : null, category, description, email).run();
  return json({ data: { id, status: "NEW" }, requestId }, 202, requestId);
}

async function createRating(request, env, identity, body, requestId) {
  const stars = body.stars;
  if (!Number.isInteger(stars) || stars < 1 || stars > 5) return json({ error: "stars_must_be_1_to_5", requestId }, 400, requestId);
  const id = crypto.randomUUID();
  await env.DB.prepare(
    "INSERT INTO ratings (id,device_id,user_id,app_version,version_code,stars,comment) VALUES (?1,?2,?3,?4,?5,?6,?7)"
  ).bind(id, clean(body.deviceId ?? body.device_id, 128) || null, identity?.userId || null, clean(body.appVersion ?? body.app_version, 32) || null, Number.isSafeInteger(body.versionCode ?? body.version_code) ? Number(body.versionCode ?? body.version_code) : null, stars, clean(body.comment, 600) || null).run();
  return json({ data: { id, accepted: true }, requestId }, 202, requestId);
}

async function latestRelease(env, abi, requestId) {
  const row = await env.DB.prepare(
    "SELECT tag,version,version_code,release_notes,min_sdk,target_sdk,published_at FROM releases WHERE status='PUBLISHED' ORDER BY version_code DESC LIMIT 1"
  ).first();
  if (!row) return json({ data: { available: false, reason: "no_published_release" }, requestId }, 200, requestId);
  return json({
    data: {
      available: true,
      tag: row.tag,
      version: row.version,
      versionCode: row.version_code,
      releaseNotes: row.release_notes,
      minSdk: row.min_sdk,
      targetSdk: row.target_sdk,
      publishedAt: row.published_at,
      abi: validAbi(abi) ? abi : null,
      downloadPaths: { arm64: "/apk/arm64", arm32: "/apk/arm32" },
    },
    requestId,
  }, 200, requestId);
}

async function downloadRelease(request, env, abi, requestId) {
  if (!validAbi(abi)) return json({ error: "unsupported_abi", requestId }, 400, requestId);
  if (!env.ASSETS?.get) return json({ error: "release_storage_unavailable", requestId }, 503, requestId);
  const row = await env.DB.prepare(
    "SELECT tag,version FROM releases WHERE status='PUBLISHED' ORDER BY version_code DESC LIMIT 1"
  ).first();
  if (!row) return json({ error: "no_published_release", requestId }, 404, requestId);
  const key = "releases/" + row.tag + "/" + abi + ".apk";
  const object = await env.ASSETS.get(key);
  if (!object) return json({ error: "release_asset_not_found", requestId }, 404, requestId);
  return new Response(object.body, {
    status: 200,
    headers: {
      "content-type": "application/vnd.android.package-archive",
      "content-disposition": 'attachment; filename="omy-play-' + row.tag + "-" + abi + '.apk"',
      "cache-control": "public, max-age=300",
      "x-content-type-options": "nosniff",
      ...(object.size ? { "content-length": String(object.size) } : {}),
      ...(object.httpEtag ? { etag: object.httpEtag } : {}),
      "x-request-id": requestId,
    },
  });
}

async function handle(request, env) {
  const url = new URL(request.url);
  const requestId = request.headers.get("cf-ray") || crypto.randomUUID();

  if (request.method === "GET" && url.pathname === "/health") {
    try {
      const [objects, migrations] = await Promise.all([
        env.DB.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'").all(),
        env.DB.prepare("SELECT version FROM omy_schema_migrations ORDER BY version").all(),
      ]);
      const tables = new Set((objects.results || []).map(row => row.name));
      const versions = new Set((migrations.results || []).map(row => row.version));
      const missingTables = REQUIRED_TABLES.filter(name => !tables.has(name));
      const missingMigrations = REQUIRED_MIGRATIONS.filter(name => !versions.has(name));
      const ready = missingTables.length === 0 && missingMigrations.length === 0;
      return json({ service: "omy-play-api-staging", status: ready ? "ready" : "schema_not_ready", schemaReady: ready, aiEnabled: false, requestId }, ready ? 200 : 503, requestId);
    } catch {
      return json({ service: "omy-play-api-staging", status: "database_unavailable", requestId }, 503, requestId);
    }
  }

  if (request.method === "OPTIONS") return json({ error: "method_not_allowed", requestId }, 405, requestId);

  if (request.method === "GET" && ["/v1/config", "/api/app-config"].includes(url.pathname)) return handleConfig(env, requestId);
  if (request.method === "GET" && ["/v1/themes", "/api/themes"].includes(url.pathname)) return handleThemes(env, requestId);
  if (request.method === "GET" && ["/v1/releases/latest", "/latest", "/check-update", "/api/version"].includes(url.pathname)) {
    return latestRelease(env, url.searchParams.get("abi") || url.searchParams.get("arch"), requestId);
  }
  const downloadMatch = url.pathname.match(/^\/apk\/(arm64|arm32)$/);
  if (request.method === "GET" && downloadMatch) return downloadRelease(request, env, downloadMatch[1], requestId);

  const postRoutes = new Map([
    ["/v1/devices/register", "device"],
    ["/api/device", "device"],
    ["/v1/crashes", "crash"],
    ["/api/crash-report", "crash"],
    ["/v1/feedback", "feedback"],
    ["/api/feedback", "feedback"],
    ["/v1/ratings", "rating"],
  ]);
  const routeType = postRoutes.get(url.pathname);
  if (request.method === "POST" && routeType) {
    if (!await rateAllowed(request, env, routeType, routeType === "crash" ? 12 : 20)) {
      return json({ error: "rate_limit_exceeded", requestId }, 429, requestId);
    }
    const verified = await verifyIdentity(request, env, true);
    if (verified.response) return verified.response;
    const parsed = await readJson(request);
    if (parsed.error) return json({ error: parsed.error, requestId }, parsed.status, requestId);
    if (routeType === "device") return registerDevice(request, env, verified.identity, parsed.value, requestId);
    if (routeType === "crash") return createCrash(request, env, verified.identity, parsed.value, requestId);
    if (routeType === "feedback") return createFeedback(request, env, verified.identity, parsed.value, requestId);
    return createRating(request, env, verified.identity, parsed.value, requestId);
  }

  if (request.method === "GET" && url.pathname === "/v1/notifications") {
    const verified = await verifyIdentity(request, env, false);
    if (verified.response) return verified.response;
    const limit = Math.min(50, Math.max(1, Number(url.searchParams.get("limit") || 20) || 20));
    const rows = await env.DB.prepare(
      "SELECT id,category,title,body,data_json,read_at,created_at,expires_at FROM user_notifications WHERE user_id=?1 AND (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP) ORDER BY created_at DESC LIMIT ?2"
    ).bind(verified.identity.userId, limit).all();
    return json({ data: rows.results || [], requestId }, 200, requestId);
  }

  const readMatch = url.pathname.match(/^\/v1\/notifications\/([A-Za-z0-9-]{8,64})\/read$/);
  if (request.method === "POST" && readMatch) {
    const verified = await verifyIdentity(request, env, false);
    if (verified.response) return verified.response;
    const result = await env.DB.prepare(
      "UPDATE user_notifications SET read_at=CURRENT_TIMESTAMP WHERE id=?1 AND user_id=?2 AND read_at IS NULL"
    ).bind(readMatch[1], verified.identity.userId).run();
    return json({ data: { markedRead: Number(result.meta?.changes || 0) > 0 }, requestId }, 200, requestId);
  }

  return json({ error: "not_found", requestId }, 404, requestId);
}

export default {
  async fetch(request, env) {
    try {
      return await handle(request, env);
    } catch (error) {
      const requestId = request.headers.get("cf-ray") || crypto.randomUUID();
      console.error("[omy-play] unhandled request error", { type: error?.name || "Error" });
      return json({ error: "internal_error", requestId }, 500, requestId);
    }
  },
};

export { REQUIRED_TABLES, REQUIRED_MIGRATIONS };
