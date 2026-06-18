CREATE TABLE IF NOT EXISTS painpoints (
  id TEXT PRIMARY KEY,
  statement TEXT NOT NULL,
  domain TEXT,
  source_count INTEGER,
  final_score REAL,
  status TEXT DEFAULT 'candidate',  -- candidate|validated|approved|engaged
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS evidence (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  painpoint_id TEXT REFERENCES painpoints(id),
  source TEXT, url TEXT, author TEXT, posted_at TIMESTAMP,
  quote TEXT, signal_type TEXT, scraped_at TIMESTAMP,
  UNIQUE(painpoint_id, url)
);
CREATE TABLE IF NOT EXISTS engagements (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  painpoint_id TEXT, forum TEXT, post_url TEXT, posted_text TEXT,
  posted_at TIMESTAMP, response_summary TEXT
);

-- Raw scraped posts (the discovery agent reads from here; idempotent on url).
CREATE TABLE IF NOT EXISTS raw_posts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  source TEXT, url TEXT UNIQUE, author TEXT, posted_at TIMESTAMP,
  title TEXT, body TEXT, score INTEGER, num_comments INTEGER,
  tags TEXT, scraped_at TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_raw_source ON raw_posts(source);
CREATE INDEX IF NOT EXISTS idx_evidence_pp ON evidence(painpoint_id);
