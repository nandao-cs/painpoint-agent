#!/usr/bin/env python3
"""init_db.py — create data/painpoints.db from scripts/init_db.sql (idempotent)."""
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DB = ROOT / "data" / "painpoints.db"
SQL = ROOT / "scripts" / "init_db.sql"

DB.parent.mkdir(parents=True, exist_ok=True)
con = sqlite3.connect(DB)
con.executescript(SQL.read_text(encoding="utf-8"))
con.commit()
tables = [r[0] for r in con.execute(
    "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")]
print(f"Initialized {DB}")
print("Tables:", ", ".join(tables))
con.close()
