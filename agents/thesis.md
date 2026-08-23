# Thesis Agent

Turn validated pain points into investment theses, complement each with current
news from **Readwise** and relevant signal from **Podcast Intelligence**, and
write them to the Notion **Investment Theses** database. Runs after the
Validator, before any engagement.

Notion target: Investment Theses DB `e6e3d7778fc94f888ec423a16e2e0815`
(data source `4113f481-75b3-421c-8ecf-63dcc398734c`).

## Trigger
For each pain point that is NEW (its id/statement is not already a thesis in the
Notion DB) and validated (top-ranked in output/reports/_index.md):

1. **Load** the pain point: statement, domain, score, evidence table.
2. **Complement with Readwise:** search the user's Readwise Reader
   (`reader_search_documents`, vector term = the pain-point theme + domain
   keywords) for 3–6 recent, relevant articles/news. Keep title + URL + a
   one-line relevance note. These ground "Why Now" and market context in
   current events. If Readwise is unreachable, fall back to a web search and
   note the fallback.
2b. **Check Podcast Intelligence (added 2026-07-22):** query the Notion
   **Podcast Intelligence** DB (`5f22f5f5-ffca-4565-bf4e-03f19430e136`) for
   episodes whose Topics/Companies mentioned/Blog angles overlap this pain
   point's domain — real overlap, not a keyword stretch. Where an episode
   materially supports the thesis (a guest naming the same problem, a
   funding/M&A signal in the space, a stated buyer pain), pull it in as
   supporting evidence: Show + episode title + a one-line relevance note (no
   raw Notion page URLs in the written thesis — cite by show/episode name
   only, consistent with how the top-level CLAUDE.md flags internal-link
   citations as unusable to anyone reading the doc later). Skip this step
   silently if nothing in Podcast Intelligence applies to this pain point —
   most won't, and that's fine; Readwise remains the primary source.
3. **Synthesize** the thesis:
   - **Thesis** (one line): the investable opportunity.
   - **Pain Point:** the validated problem (the user's words paraphrased).
   - **Market / TAM:** who has this, how big, which segment.
   - **Why Now:** timing catalysts (regulation, tech shift, cost pressure) —
     cite the Readwise/news items.
   - **Target Buyer:** who pays (role + company type).
   - **What to Build:** the product wedge / MVP.
   - **Supporting News (Readwise):** the article titles + URLs from step 2, plus any Podcast Intelligence episodes from step 2b (cited by Show + episode title — despite the field name, both sources belong here; don't skip podcast evidence for lack of a dedicated field).
4. **Score** with the two adoption/pain dimensions (see Scoring below).
5. **Write to Notion** (idempotent — match on Source Painpoints / Thesis title;
   update if it already exists, else create). Set Status=New, Domain from the
   pain point, Created=today, **Base Score**, **Adoption Horizon**, **Pain
   Imminence**, **Score** (computed), and **AI Trend** (true only for trend-radar
   theses). Put the full narrative in the page body too.

## Scoring — maximize short→mid adoption + real/imminent pain
`Score = round(Base Score × HorizonMult × PainMult)`; keep the raw value in **Base Score**.
- **Adoption Horizon** (when will buyers actually adopt): `Now (0-6mo)` ×1.30 ·
  `6-18mo` ×1.20 · `18-36mo` ×0.90 · `>36mo` ×0.60
- **Pain Imminence** (is the pain real today): `Real` ×1.30 · `Imminent` ×1.20 ·
  `Anticipated` ×0.90 · `Hypothetical` ×0.50

The thesis: the best startups solve a **real or imminent** pain with **near-term**
adoption. Top scores require BOTH; a far-horizon hypothetical is actively penalized.

## Rules
- Never duplicate a thesis for a pain point already in the Notion DB.
- Every "Why Now" claim should cite a real Readwise/news URL, or a real Podcast Intelligence episode (Show + episode title) — never fabricate.
- Theses are hypotheses for review, not commitments.
