#!/usr/bin/env python3
"""ai_trends.py — pain-velocity radar for AI x security themes (lens #1).

Scans raw_posts for emerging AI-security themes, buckets mentions by month, and
ranks themes by ACCELERATION (recent 90d vs prior 90d) x recent volume — i.e.
which pains are heating up *now*. Output feeds Phase 2.6 of the pipeline, which
turns rising themes into investment theses (validated against capital signals).

  python scripts/ai_trends.py            # human table + writes data/ai_trends.json
  python scripts/ai_trends.py --json     # machine JSON only (for the agent)

Pure stdlib. Idempotent (read-only on the DB).
"""
import argparse, json, sqlite3, re, sys, datetime as dt
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DB = ROOT / "data" / "painpoints.db"
OUT = ROOT / "data" / "ai_trends.json"

# AI x security themes -> keyword set (lowercased, substring match on title+body+tags).
THEMES = {
    "Prompt injection & jailbreaks":      ["prompt injection", "jailbreak", "indirect prompt", "system prompt leak", "prompt leak"],
    "MCP / tool security":                ["mcp server", "model context protocol", "tool poisoning", "mcp security", "tool calling"],
    "Agentic / agent runtime security":   ["agent guardrail", "agentic security", "autonomous agent", "agent runtime", "ai agent security", "agent security"],
    "RAG & context data leakage":         ["retrieval augmented", " rag ", "context leakage", "embedding leak", "vector store"],
    "Shadow AI & AI governance":          ["shadow ai", "ai governance", "ai bom", "ai inventory", "unsanctioned ai", "ai usage policy"],
    "Model supply chain":                 ["model supply chain", "model provenance", "malicious model", "huggingface malware", "pickle exploit", "model poisoning"],
    "LLM red-teaming & eval":             ["llm red team", "red teaming", "ai pentest", "model evaluation", "llm security testing"],
    "Deepfake & AI-enabled fraud":        ["deepfake", "voice clone", "synthetic identity", "ai phishing", "ai-generated fraud"],
    "Non-human / agent identity":         ["non-human identity", " nhi ", "machine identity", "agent identity", "secret sprawl", "workload identity"],
    "AI-generated code security":         ["ai generated code", "copilot security", "vibe coding", "insecure ai code", "ai code review"],
    "LLM data privacy & DLP":             ["llm dlp", "ai data privacy", "training data leakage", "pii in prompts", "prompt dlp"],
}

WINDOW = 90  # days per comparison window

def parse_date(ts):
    if not ts:
        return None
    try:
        return dt.datetime.fromisoformat(str(ts).replace("Z", "").split("+")[0])
    except Exception:
        return None

def matches(text, kws):
    t = " " + (text or "").lower() + " "
    return any(k in t for k in kws)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", action="store_true", help="emit JSON only")
    args = ap.parse_args()
    if not DB.exists():
        sys.exit("DB not found. Run scripts/scrape.py first.")
    con = sqlite3.connect(DB); con.row_factory = sqlite3.Row
    rows = con.execute("SELECT url, source, title, body, tags, posted_at FROM raw_posts").fetchall()
    con.close()

    now = dt.datetime.utcnow()
    recent_cut = now - dt.timedelta(days=WINDOW)
    prior_cut = now - dt.timedelta(days=2 * WINDOW)

    results = []
    for theme, kws in THEMES.items():
        recent = prior = older = 0
        months = {}
        samples = []
        for r in rows:
            blob = f"{r['title']} {r['body']} {r['tags']}"
            if not matches(blob, kws):
                continue
            d = parse_date(r["posted_at"])
            if d:
                mk = d.strftime("%Y-%m")
                months[mk] = months.get(mk, 0) + 1
                if d >= recent_cut:
                    recent += 1
                    if len(samples) < 5:
                        samples.append({"url": r["url"], "source": r["source"], "title": (r["title"] or "")[:120]})
                elif d >= prior_cut:
                    prior += 1
                else:
                    older += 1
            else:
                older += 1
        total = recent + prior + older
        if total == 0:
            continue
        # acceleration: recent 90d vs prior 90d (smoothed); volume weight via log.
        accel = (recent + 1) / (prior + 1)
        import math
        heat = round(accel * math.log10(recent + prior + 10), 2)
        results.append({
            "theme": theme,
            "heat": heat,                 # ranking key: acceleration x recent volume
            "acceleration": round(accel, 2),
            "recent_90d": recent,
            "prior_90d": prior,
            "older": older,
            "total": total,
            "monthly": dict(sorted(months.items())),
            "samples": samples,
        })

    results.sort(key=lambda x: x["heat"], reverse=True)
    OUT.write_text(json.dumps(results, indent=2), encoding="utf-8")

    if args.json:
        print(json.dumps(results))
        return
    print(f"AI x Security pain-velocity radar  ({len(rows)} posts scanned, {WINDOW}d windows)\n")
    print(f"{'theme':<34}{'heat':>6}{'accel':>7}{'90d':>6}{'prev':>6}{'total':>7}")
    print("-" * 66)
    for r in results:
        print(f"{r['theme']:<34}{r['heat']:>6}{r['acceleration']:>7}{r['recent_90d']:>6}{r['prior_90d']:>6}{r['total']:>7}")
    print(f"\nWrote {OUT}")

if __name__ == "__main__":
    main()
