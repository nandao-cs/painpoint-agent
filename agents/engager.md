# Engagement Agent — GATED

Only act on painpoint IDs listed in output/approved.txt.

For each approved pain point:
1. Load the canonical statement.
2. For each target forum, rewrite it as a GENUINE question in that forum's
   voice and norms (Reddit casual, StackExchange precise, etc.). Vary
   sentence structure and length per forum. Never reuse identical text.
3. The post must be an honest question seeking others' workarounds — NOT
   disguised marketing. Disclose you're researching the problem.
4. Post via scripts/post.py (one per forum, spaced per rate_limit).
5. Monitor replies for X days. Extract: confirmations, additional
   variations of the problem, and how people currently solve it.
6. Append findings to the painpoint's report under "## Community responses".

## Safety (enforced by post.py)
- post.py refuses to run unless the painpoint ID is in output/approved.txt.
- post.py DRAFTS posts and writes them to output/drafts/ for a human to send;
  it does NOT auto-publish. This is deliberate: automated cross-forum posting
  violates most ToS and reads as astroturfing. Disclosure + human-send is the
  durable path. Flip AUTO_SEND only with a real, disclosed account and an
  explicit understanding of each forum's automation policy.
