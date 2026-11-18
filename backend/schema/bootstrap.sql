-- Omy Play schema-only bootstrap snapshot exported from its isolated staging D1 database on 2026-11-11.
-- Contains DDL only. No application rows, customer data, payments, media metadata or secrets are included.
-- Cloudflare-managed _cf_KV is intentionally excluded. Apply only to a brand-new empty product D1 database.
PRAGMA foreign_keys = ON;

-- table: app_config
CREATE TABLE app_config (
  config_id TEXT PRIMARY KEY CHECK (config_id = 'default'),
  revision INTEGER NOT NULL CHECK (revision > 0),
  config_json TEXT NOT NULL,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- table: crash_reports
CREATE TABLE crash_reports (
  id TEXT PRIMARY KEY,
  group_id TEXT NOT NULL,
  device_id TEXT,
  user_id TEXT,
  app_version TEXT,
  version_code INTEGER CHECK (version_code IS NULL OR version_code >= 0),
  error_type TEXT,
  description TEXT,
  stack_trace TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- table: devices
CREATE TABLE devices (
  device_id TEXT PRIMARY KEY,
  user_id TEXT,
  fcm_token TEXT,
  fcm_token_hash TEXT,
  app_version TEXT NOT NULL DEFAULT '0.0.0',
  version_code INTEGER NOT NULL DEFAULT 0 CHECK (version_code >= 0),
  abi TEXT NOT NULL DEFAULT 'unknown',
  platform TEXT NOT NULL DEFAULT 'android',
  model TEXT,
  android_version TEXT,
  locale TEXT,
  registered_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_seen_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  disabled_at TEXT
);

-- table: download_events
CREATE TABLE download_events (
  id TEXT PRIMARY KEY,
  abi TEXT NOT NULL CHECK (abi IN ('arm64','arm32')),
  release_tag TEXT,
  ip_hash TEXT,
  user_agent_hash TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- table: feedback
CREATE TABLE feedback (
  id TEXT PRIMARY KEY,
  device_id TEXT,
  user_id TEXT,
  app_version TEXT,
  version_code INTEGER CHECK (version_code IS NULL OR version_code >= 0),
  category TEXT NOT NULL DEFAULT 'other',
  description TEXT NOT NULL,
  user_email TEXT,
  status TEXT NOT NULL DEFAULT 'NEW' CHECK (status IN ('NEW','IN_REVIEW','RESOLVED','CLOSED')),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- table: omy_schema_migrations
CREATE TABLE omy_schema_migrations (
  version TEXT PRIMARY KEY,
  checksum_sha256 TEXT NOT NULL,
  applied_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- table: rate_limits
CREATE TABLE rate_limits (
  scope_key TEXT PRIMARY KEY,
  window_start INTEGER NOT NULL,
  request_count INTEGER NOT NULL CHECK (request_count >= 0)
);

-- table: ratings
CREATE TABLE ratings (
  id TEXT PRIMARY KEY,
  device_id TEXT,
  user_id TEXT,
  app_version TEXT,
  version_code INTEGER CHECK (version_code IS NULL OR version_code >= 0),
  stars INTEGER NOT NULL CHECK (stars BETWEEN 1 AND 5),
  comment TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- table: releases
CREATE TABLE releases (
  tag TEXT PRIMARY KEY,
  version TEXT NOT NULL,
  version_code INTEGER NOT NULL CHECK (version_code > 0),
  release_notes TEXT NOT NULL DEFAULT '',
  min_sdk INTEGER NOT NULL DEFAULT 24 CHECK (min_sdk >= 21),
  target_sdk INTEGER NOT NULL DEFAULT 36 CHECK (target_sdk >= min_sdk),
  status TEXT NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT','PUBLISHED','REVOKED')),
  published_at TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(version, version_code)
);

-- table: theme_catalog
CREATE TABLE theme_catalog (
  theme_id TEXT PRIMARY KEY,
  position INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','INACTIVE')),
  theme_json TEXT NOT NULL,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- table: together_rooms
CREATE TABLE together_rooms (
  room_id TEXT PRIMARY KEY,
  status TEXT NOT NULL DEFAULT 'waiting' CHECK (status IN ('waiting','connected','closed')),
  host_user_id TEXT NOT NULL,
  guest_user_id TEXT,
  host_identity_json TEXT NOT NULL,
  guest_identity_json TEXT NOT NULL,
  guest_username TEXT NOT NULL,
  invite_token_hash TEXT NOT NULL,
  created_at TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- table: together_signals
CREATE TABLE together_signals (
  signal_id TEXT PRIMARY KEY,
  room_id TEXT NOT NULL REFERENCES together_rooms(room_id) ON DELETE CASCADE,
  recipient_user_id TEXT NOT NULL,
  sender_role TEXT NOT NULL CHECK (sender_role IN ('host','guest')),
  signal_type TEXT NOT NULL CHECK (signal_type IN ('offer','answer','ice','bye')),
  payload_json TEXT,
  created_at TEXT NOT NULL,
  expires_at TEXT NOT NULL
);

-- table: user_notifications
CREATE TABLE user_notifications (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  category TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data_json TEXT,
  read_at TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at TEXT
);

-- index: idx_omy_crash_dedupe
CREATE INDEX idx_omy_crash_dedupe ON crash_reports(group_id, device_id, created_at DESC);

-- index: idx_omy_devices_fcm
CREATE INDEX idx_omy_devices_fcm ON devices(fcm_token_hash) WHERE fcm_token_hash IS NOT NULL;

-- index: idx_omy_devices_user
CREATE INDEX idx_omy_devices_user ON devices(user_id, last_seen_at DESC);

-- index: idx_omy_downloads_created
CREATE INDEX idx_omy_downloads_created ON download_events(created_at DESC);

-- index: idx_omy_feedback_status
CREATE INDEX idx_omy_feedback_status ON feedback(status, created_at DESC);

-- index: idx_omy_notifications_user
CREATE INDEX idx_omy_notifications_user ON user_notifications(user_id, created_at DESC);

-- index: idx_omy_ratings_created
CREATE INDEX idx_omy_ratings_created ON ratings(created_at DESC);

-- index: idx_omy_releases_published
CREATE INDEX idx_omy_releases_published ON releases(status, published_at DESC);

-- index: idx_omy_themes_status_position
CREATE INDEX idx_omy_themes_status_position ON theme_catalog(status, position);

-- index: idx_omy_together_expiry
CREATE INDEX idx_omy_together_expiry ON together_rooms(expires_at);

-- index: idx_omy_together_guest_invites
CREATE INDEX idx_omy_together_guest_invites ON together_rooms(guest_username, status, created_at DESC);

-- index: idx_omy_together_signals_expiry
CREATE INDEX idx_omy_together_signals_expiry ON together_signals(expires_at);

-- index: idx_omy_together_signals_recipient
CREATE INDEX idx_omy_together_signals_recipient ON together_signals(room_id, recipient_user_id, signal_id);

-- Preserve the exact schema migration history observed in the source staging database.
INSERT INTO omy_schema_migrations (version, checksum_sha256, applied_at) VALUES ('0001_omy_play_core', '7ae6b01c8f18db8860a23b2e405a529fadba9cc9bbc265d39e929efc13cd82bd', '2026-11-11 16:29:04');
