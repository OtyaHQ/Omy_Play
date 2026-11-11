# Omy Play D1 schema snapshot

This snapshot is exported from the isolated Omy Play staging database on 2026-11-11.

- Product D1 ID: 006b1ac1-0e92-4480-b07e-4232724710e8
- Application-controlled tables including migration ledger: 13
- Views: 0
- Explicit indexes: 13
- Triggers: 0
- Migration history: 0001_omy_play_core (7ae6b01c8f18db8860a23b2e405a529fadba9cc9bbc265d39e929efc13cd82bd)

The SQL contains DDL and migration-history rows only. It excludes Cloudflare's internal _cf_KV table and contains no application records or secrets.

**Use:** This is a one-time bootstrap for a brand-new empty Omy Play database. Do not apply it to the existing staging database. Existing environments must be changed only through new forward-only migration files. Review any bootstrap target and take a backup before execution.
