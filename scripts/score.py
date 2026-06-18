#!/usr/bin/env python3
"""score.py — rank painpoint candidates using config/scoring.yaml.

Reads painpoints + their evidence, computes a 0-1 score per weighted signal,
combines into final_score 0-100, and writes it back (status -> 'validated').
Evidence signal_type (set by the discovery agent) drives the signal scores;
quote text is keyword-scanned as a fallback.

  python scripts/score.py
"""
import sqlite3, sys, datetime as dt
from pathlib import Path
try:
    import yaml
except ImportError:
    sys.exit("Missing deps. Run: pip install -r requirements.txt")

ROOT = Path(__file__).resolve().parent.parent
DB = ROOT / "data" / "painpoints.db"
CFG = yaml.safe_load((ROOT / "config" / "scoring.yaml").read_text(encoding="utf-8"))
W = CFG["weights"]
MIN_SOURCES = CFG.get("min_sources", 8)
LOOKBACK = CFG.get("lookback_days", 365)
KW = CFG.get("keyword_signals", {})

def has_kw(text, words):
    t = (text or "").lower()
    return any(w in t for w in words)

def age_days(ts):
    if not ts:
        return LOOKBACK
    try:
        d = dt.datetime.fromisoformat(str(ts).replace("Z", "").split("+")[0])
        return max(0, (dt.datetime.utcnow() - d).days)
    except Exception:
        return LOOKBACK

def score_painpoint(rows):
    """rows: list of evidence dicts for one painpoint."""
    n = len(rows)
    sources = {r["source"] for r in rows}
    # breadth
    s_count = min(len(sources_or_rows(sources, n)) / MIN_SOURCES, 1.0)
    # recency: newest evidence
    newest = min((age_days(r["posted_at"]) for r in rows), default=LOOKBACK)
    s_recency = max(0.0, 1.0 - newest / LOOKBACK)
    # signal fractions (signal_type first, keyword fallback)
    def frac(signal, kw_key):
        hits = 0
        for r in rows:
            st = (r.get("signal_type") or "").lower()
            if signal in st or (kw_key in KW and has_kw(r.get("quote"), KW[kw_key])):
                hits += 1
        return min(hits / max(n, 1), 1.0)
    s_unmet = frac("unmet", "unmet_need")
    s_wtp = frac("wtp", "wtp")
    s_sent = frac("frustration", "frustration")
    final = 100 * (
        W["source_count"] * s_count + W["recency"] * s_recency +
        W["sentiment_intensity"] * s_sent + W["unmet_need"] * s_unmet +
        W["willingness_to_pay"] * s_wtp)
    return round(final, 1), len(sources)

def sources_or_rows(sources, n):
    # if all evidence is from a single source, fall back to row count for breadth
    return sources if len(sources) > 1 else range(n)

def main():
    con = sqlite3.connect(DB); con.row_factory = sqlite3.Row
    pps = con.execute("SELECT id, statement FROM painpoints").fetchall()
    if not pps:
        print("No painpoints yet. Run the Discovery agent to populate them."); return
    updated = 0
    for pp in pps:
        ev = [dict(r) for r in con.execute(
            "SELECT * FROM evidence WHERE painpoint_id=?", (pp["id"],)).fetchall()]
        if not ev:
            continue
        final, src = score_painpoint(ev)
        con.execute("UPDATE painpoints SET final_score=?, source_count=?, status='validated' WHERE id=?",
                    (final, src, pp["id"]))
        updated += 1
        print(f"  {pp['id']:<24} {final:>5}/100  ({src} sources, {len(ev)} evidence)")
    con.commit()
    print(f"\nScored {updated} painpoints.")
    con.close()

if __name__ == "__main__":
    main()
