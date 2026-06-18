#!/usr/bin/env python3
"""post.py — GATED engagement. By default it DRAFTS forum posts for a human to
send; it never auto-publishes. Automated cross-forum posting violates most
forum ToS and reads as astroturfing — disclosure + human-send is the durable path.

Gate: a painpoint id must be present in output/approved.txt or this refuses.

  python scripts/post.py --id <painpoint_id>     # write drafts to output/drafts/

To actually publish you must (a) understand each forum's automation policy,
(b) use a real disclosed account, and (c) set AUTO_SEND=True deliberately.
"""
import argparse, sqlite3, sys, datetime as dt
from pathlib import Path

AUTO_SEND = False  # leave False. Auto-posting is ToS-risky / astroturfing.

ROOT = Path(__file__).resolve().parent.parent
DB = ROOT / "data" / "painpoints.db"
APPROVED = ROOT / "output" / "approved.txt"
DRAFTS = ROOT / "output" / "drafts"

DISCLOSURE = ("(I'm researching this problem to understand how people handle it "
              "— not selling anything. Genuinely curious how you solve this today.)")

FORUM_VOICE = {
    "reddit": "Casual, first-person, short. A real question a sysadmin would ask.",
    "stackexchange": "Precise, specific, scoped to a concrete technical question.",
    "hackernews": "Concise, substantive, no fluff.",
}

def approved_ids():
    if not APPROVED.exists():
        return set()
    return {l.strip() for l in APPROVED.read_text(encoding="utf-8").splitlines()
            if l.strip() and not l.startswith("#")}

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--id", required=True, help="painpoint id (must be in output/approved.txt)")
    args = ap.parse_args()

    if args.id not in approved_ids():
        sys.exit(f"REFUSED: '{args.id}' is not in {APPROVED}. Add it there to approve Phase 3.")
    if AUTO_SEND:
        sys.exit("AUTO_SEND is enabled but no publisher is implemented — that is intentional. "
                 "Review each forum's automation policy and implement a disclosed, rate-limited "
                 "publisher yourself before flipping this on.")

    con = sqlite3.connect(DB); con.row_factory = sqlite3.Row
    pp = con.execute("SELECT * FROM painpoints WHERE id=?", (args.id,)).fetchone()
    if not pp:
        sys.exit(f"No painpoint '{args.id}' in DB.")
    DRAFTS.mkdir(parents=True, exist_ok=True)
    for forum, voice in FORUM_VOICE.items():
        draft = (f"# DRAFT for {forum} — painpoint {args.id}\n"
                 f"# voice: {voice}\n"
                 f"# Problem: {pp['statement']}\n\n"
                 f"[Validator/Engager agent: write a genuine, forum-native question here that "
                 f"asks how people currently handle this problem. Vary phrasing per forum. "
                 f"End with the disclosure below.]\n\n"
                 f"{DISCLOSURE}\n")
        (DRAFTS / f"{args.id}_{forum}.md").write_text(draft, encoding="utf-8")
    print(f"Wrote {len(FORUM_VOICE)} drafts to {DRAFTS}. Review + send manually. Nothing published.")
    con.close()

if __name__ == "__main__":
    main()
