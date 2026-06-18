#!/usr/bin/env python3
"""scrape.py — pull raw posts from Reddit / Hacker News / StackExchange into
data/painpoints.db (raw_posts) and cache raw JSON under data/raw/.

Idempotent: raw_posts.url is UNIQUE, so re-runs never duplicate.

  python scripts/scrape.py                 # all enabled sources
  python scripts/scrape.py --source hackernews
  python scripts/scrape.py --source stackexchange --limit 30
"""
import argparse, json, os, sqlite3, sys, time, datetime as dt
from pathlib import Path

try:
    import requests, yaml
except ImportError:
    sys.exit("Missing deps. Run: pip install -r requirements.txt")

ROOT = Path(__file__).resolve().parent.parent
DB = ROOT / "data" / "painpoints.db"
RAW = ROOT / "data" / "raw"
CFG = ROOT / "config" / "sources.yaml"
UA = "painpoint-agent/0.1 (research; contact via .env)"

def load_env():
    env = {}
    p = ROOT / ".env"
    if p.exists():
        for line in p.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                env[k.strip()] = v.strip()
    return env

def db():
    con = sqlite3.connect(DB)
    con.execute("PRAGMA journal_mode=WAL")
    return con

def upsert_post(con, source, url, author, posted_at, title, body, score, ncomments, tags):
    try:
        cur = con.execute(
            """INSERT OR IGNORE INTO raw_posts
               (source,url,author,posted_at,title,body,score,num_comments,tags,scraped_at)
               VALUES (?,?,?,?,?,?,?,?,?,?)""",
            (source, url, author, posted_at, title, (body or "")[:8000], score,
             ncomments, ",".join(tags or []), dt.datetime.now(dt.UTC).isoformat()),
        )
        return cur.rowcount  # 1 if newly inserted, 0 if duplicate (idempotent)
    except sqlite3.Error as e:
        print(f"  ! db error for {url}: {e}")
        return 0

def cache(source, name, payload):
    RAW.mkdir(parents=True, exist_ok=True)
    (RAW / f"{source}_{name}.json").write_text(json.dumps(payload)[:5_000_000], encoding="utf-8")

# ---------------- Hacker News (Algolia, public) ----------------
def scrape_hn(con, cfg):
    n = 0
    for q in cfg.get("queries", []):
        for tag in ("story", "comment"):
            try:
                r = requests.get("https://hn.algolia.com/api/v1/search_by_date",
                                 params={"query": q, "tags": tag,
                                         "hitsPerPage": cfg.get("hits_per_query", 50)},
                                 headers={"User-Agent": UA}, timeout=30)
                r.raise_for_status()
                data = r.json()
            except Exception as e:
                print(f"  ! HN '{q}'/{tag}: {e}"); continue
            cache("hackernews", f"{q[:20]}_{tag}".replace(" ", "_"), data)
            for h in data.get("hits", []):
                oid = h.get("objectID")
                url = f"https://news.ycombinator.com/item?id={oid}"
                title = h.get("title") or h.get("story_title") or ""
                body = h.get("comment_text") or h.get("story_text") or title
                n += upsert_post(con, "hackernews", url, h.get("author"),
                                 h.get("created_at"), title, body,
                                 h.get("points") or 0, h.get("num_comments") or 0, ["hn", q])
            time.sleep(0.4)
    con.commit(); print(f"  hackernews: +{n} new posts")

# ---------------- StackExchange (public; key optional) ----------------
def scrape_se(con, cfg, env):
    n = 0; key = env.get("STACKEXCHANGE_KEY")
    per = cfg.get("questions_per_site", 80)
    tags = cfg.get("tags") or []
    for site in cfg.get("sites", []):
        # one no-tag top-voted pull + one pull per individual tag (OR semantics)
        queries = [None] + [t for t in tags]
        for tag in queries:
            params = {"site": site, "order": "desc", "sort": "votes",
                      "pagesize": min(per, 100), "filter": "withbody"}
            if tag:
                params["tagged"] = tag          # SINGLE tag, not AND-joined
            if key:
                params["key"] = key
            try:
                r = requests.get("https://api.stackexchange.com/2.3/questions",
                                 params=params, headers={"User-Agent": UA}, timeout=30)
                r.raise_for_status(); data = r.json()
            except Exception as e:
                print(f"  ! SE {site}/{tag}: {e}"); continue
            cache("stackexchange", f"{site}_{tag or 'top'}", data)
            for q in data.get("items", []):
                posted = dt.datetime.utcfromtimestamp(q.get("creation_date", 0)).isoformat()
                n += upsert_post(con, "stackexchange", q.get("link"),
                                 (q.get("owner") or {}).get("display_name"), posted,
                                 q.get("title", ""), q.get("body", ""),
                                 q.get("score", 0), q.get("answer_count", 0),
                                 ["se", site] + (q.get("tags") or []))
            if data.get("backoff"):
                time.sleep(data["backoff"])
            time.sleep(0.4)
    con.commit(); print(f"  stackexchange: +{n} new posts")

# ---------------- Reddit (PRAW; needs creds) ----------------
def scrape_reddit(con, cfg, env):
    cid, sec = env.get("REDDIT_CLIENT_ID"), env.get("REDDIT_CLIENT_SECRET")
    if not (cid and sec):
        print("  reddit: SKIPPED (set REDDIT_CLIENT_ID / REDDIT_CLIENT_SECRET in .env)")
        return
    try:
        import praw
    except ImportError:
        print("  reddit: SKIPPED (pip install praw)"); return
    reddit = praw.Reddit(client_id=cid, client_secret=sec,
                         user_agent=env.get("REDDIT_USER_AGENT", UA))
    reddit.read_only = True
    n = 0
    for sub in cfg.get("subreddits", []):
        try:
            for post in reddit.subreddit(sub).top(time_filter="year",
                                                  limit=cfg.get("posts_per_subreddit", 80)):
                url = f"https://reddit.com{post.permalink}"
                posted = dt.datetime.utcfromtimestamp(post.created_utc).isoformat()
                body = post.selftext or post.title
                n += upsert_post(con, "reddit", url, str(post.author), posted,
                                 post.title, body, post.score, post.num_comments, ["reddit", sub])
        except Exception as e:
            print(f"  ! reddit r/{sub}: {e}")
        time.sleep(1)
    con.commit(); print(f"  reddit: +{n} new posts")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--source", help="reddit|hackernews|stackexchange (default: all enabled)")
    ap.add_argument("--limit", type=int, help="override per-source fetch size")
    args = ap.parse_args()
    if not DB.exists():
        sys.exit("DB not found. Run: python scripts/init_db.py first.")
    cfg = yaml.safe_load(CFG.read_text(encoding="utf-8"))
    env = load_env()
    con = db()
    handlers = {"hackernews": scrape_hn, "stackexchange": scrape_se, "reddit": scrape_reddit}
    for s in cfg["sources"]:
        name = s["name"]
        if args.source and name != args.source:
            continue
        if not args.source and not s.get("enabled"):
            continue
        if name not in handlers:
            print(f"  {name}: no handler (method={s.get('method')})"); continue
        if args.limit:
            for k in ("hits_per_query", "questions_per_site", "posts_per_subreddit"):
                if k in s: s[k] = args.limit
        print(f"[{name}]")
        if name == "stackexchange":
            scrape_se(con, s, env)
        elif name == "reddit":
            scrape_reddit(con, s, env)
        else:
            scrape_hn(con, s)
    total = con.execute("SELECT COUNT(*) FROM raw_posts").fetchone()[0]
    print(f"\nraw_posts total: {total}")
    con.close()

if __name__ == "__main__":
    main()
