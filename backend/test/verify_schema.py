from pathlib import Path
import sqlite3

ROOT = Path(__file__).resolve().parents[1]
SQL = (ROOT / "schema" / "bootstrap.sql").read_text(encoding="utf-8")
db = sqlite3.connect(":memory:")
db.execute("PRAGMA foreign_keys = ON")
db.executescript(SQL)

objects = db.execute(
    "SELECT type, COUNT(*) FROM sqlite_master WHERE name NOT LIKE 'sqlite_%' GROUP BY type"
).fetchall()
counts = dict(objects)
assert counts.get("table", 0) == 13, counts
assert counts.get("view", 0) == 0, counts
assert counts.get("index", 0) == 13, counts
assert counts.get("trigger", 0) == 0, counts
assert db.execute("PRAGMA integrity_check").fetchone()[0] == "ok"
assert db.execute("PRAGMA foreign_key_check").fetchall() == []
expected = {"0001_omy_play_core": "7ae6b01c8f18db8860a23b2e405a529fadba9cc9bbc265d39e929efc13cd82bd"}
actual = dict(db.execute("SELECT version, checksum_sha256 FROM omy_schema_migrations"))
assert actual == expected, actual
for table in ("devices", "crash_reports", "feedback", "ratings", "releases", "together_rooms"):
    assert db.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0] == 0, table
assert db.execute("SELECT 1 FROM sqlite_master WHERE type='table' AND name='companies'").fetchone() is None
print("PASS: Omy Play snapshot creates its isolated 13-table schema; integrity/FK checks and migration hash match.")
