#!/usr/bin/env python3
"""report.py — generate output/reports/<id>.md briefs + _index.md from the DB.

Produces the data-driven skeleton (statement, score, evidence table, auto
'why it's strong' bullets). The Validator agent enriches the narrative
sections (entrepreneurial fit, risks) for the top candidates.

  python scripts/report.py
"""
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DB = ROOT / "data" / "painpoints.db"
OUT = ROOT / "output" / "reports"

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    con = sqlite3.connect(DB); con.row_factory = sqlite3.Row
    pps = con.execute(
        "SELECT * FROM painpoints ORDER BY final_score DESC NULLS LAST").fetchall()
    if not pps:
        print("No painpoints to report."); return

    # _index.md
    idx = ["# Pain Point Index", "",
           "| Rank | ID | Score | Domain | Sources | Status | Statement |",
           "|---|---|---|---|---|---|---|"]
    for i, p in enumerate(pps, 1):
        idx.append(f"| {i} | `{p['id']}` | **{p['final_score'] or 0}** | {p['domain'] or '-'} "
                   f"| {p['source_count'] or 0} | {p['status']} | {p['statement']} |")
    idx += ["", "_Generated from data/painpoints.db. Top candidates have enriched "
            "briefs in this folder. Populate output/approved.txt to gate Phase 3._"]
    (OUT / "_index.md").write_text("\n".join(idx), encoding="utf-8")

    # per-painpoint brief
    for p in pps:
        ev = con.execute(
            "SELECT source,posted_at,url,quote,signal_type FROM evidence "
            "WHERE painpoint_id=? ORDER BY posted_at DESC", (p["id"],)).fetchall()
        sig = {}
        for e in ev:
            for s in (e["signal_type"] or "").split(","):
                s = s.strip()
                if s: sig[s] = sig.get(s, 0) + 1
        lines = [
            f"# {p['statement']}", "",
            f"**Score:** {p['final_score'] or 0}/100  |  **Domain:** {p['domain'] or '-'}  "
            f"|  **Sources:** {p['source_count'] or 0}  |  **Evidence:** {len(ev)}", "",
            "## Why it's strong",
            f"- Breadth: {p['source_count'] or 0} independent sources, {len(ev)} evidence items",
            f"- Signal mix: " + (", ".join(f"{k} ×{v}" for k, v in sig.items()) or "n/a"),
            "",
            "## Entrepreneurial fit",
            "_[Validator: TAM signal, who would buy, why now]_", "",
            "## Evidence table", "",
            "| Source | Date | URL | Signal | Quote |",
            "|--------|------|-----|--------|-------|",
        ]
        for e in ev:
            q = (e["quote"] or "").replace("|", "\\|")[:120]
            lines.append(f"| {e['source']} | {(e['posted_at'] or '')[:10]} | {e['url']} "
                         f"| {e['signal_type'] or ''} | {q} |")
        lines += ["", "## Risks / why it might NOT be solvable",
                  "_[Validator: incumbents, regulation, why nobody's done it yet]_", ""]
        (OUT / f"{p['id']}.md").write_text("\n".join(lines), encoding="utf-8")

    print(f"Wrote {len(pps)} briefs + _index.md to {OUT}")
    con.close()

if __name__ == "__main__":
    main()
