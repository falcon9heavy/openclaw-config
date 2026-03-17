# Investment Agent — Requirements & Architecture Brainstorm

**Status:** In Progress (Interview Phase)
**Last Updated:** March 12, 2026
**Session:** Architecture brainstorm — defining use cases before building

---

## 1. Project Philosophy

> Define the user stories first, not the agent architecture. Agents and skills fall out of concrete scenarios naturally. Don't over-specify the architecture on day one — build one scenario end-to-end, learn what's hard, then layer on the next.

The system's value is in **surfacing opportunities and enforcing discipline**, not guaranteeing returns. Ambitious return targets should be held with appropriate skepticism.

---

## 2. Proposed Agent Framework

Agents are organized around **jobs** (self-contained responsibilities), not build phases. Each agent has clear inputs, outputs, and a reason to exist independently.

### Portfolio Agent
- **Job:** Source of truth for holdings, prices, P&L, allocations
- **Answers:** "What do I own, what's it worth, how is it allocated?"
- **Does not** make decisions — only provides data

### Watchdog Agent
- **Job:** Monitor for events — earnings dates, price swings, unusual volume, news
- **Behavior:** Notices things and raises flags. Does not analyze.
- **Output:** "Hey, look at this"

### Analyst Agent
- **Job:** Deep research on a specific ticker (on demand, triggered by user or another agent)
- **Capabilities:** Fundamentals, earnings transcripts, peer comparison, thesis evaluation
- **Output:** Structured opinion / brief

### Strategist Agent
- **Job:** Portfolio-level thinking — allocation, exposure, cash deployment, rebalancing
- **Thinks about** the portfolio holistically, not individual stocks
- **Output:** Recommendations tied to current allocation and conviction levels

### Open Design Questions
- **Trigger model:** Does Watchdog ping user, who then asks Analyst? Or does Watchdog auto-hand-off to Analyst and deliver a finished briefing?
- **Shared state:** Do agents share memory of past analyses? If Analyst looked at NVDA last week, should Strategist know?
- **Runtime:** All OpenClaw agents on the mini-PC? Cron jobs? Telegram commands? Mix?

---

## 3. Interview Responses (Raw Input)

### Q1-Q2: Current daily routine & frustrations

**What Chris does today:**
- Opens stocks app, looks at if positions went up or down
- Acknowledges this is surface-level and wants to evolve

**What Chris wants to evolve to:**
- Search for news or earnings that could impact a position
- Determine if news **breaks the thesis** (e.g., lost its moat) vs. **presents an opportunity** (e.g., dumb analyst downgrade = buying opportunity to accumulate)
- Agent should know holdings, know allocation (over/under weight), know if price is ridiculous → encourage sell or buy
- Track smart money moves: e.g., "Chris Holm bought 1M shares of something I was watching — maybe time to jump in for 100 shares"

**Key insight:** Chris doesn't just want a price ticker. He wants **context around moves** — the "why" and the "so what." The system should connect: news → thesis → allocation → action.

### Q3-Q4: Thesis tracking & allocation approach

**How Chris tracks investment theses today:**
Theses are conviction-based but informal — held in his head, not formalized. Typical thesis structure:
1. Widely recognized key holding in financial media (e.g., Mag7)
2. Has worked for years, so why sell?
3. Business moat / quasi-monopoly
4. Strong cash flows + value/growth metrics

**Implication for the agent:** One of the early jobs is helping Chris **articulate and store theses** in a structured format the system can evaluate against incoming news.

**Allocation philosophy:**
- Not a stickler for rigid allocation percentages
- Has done well with outsized positions historically
- Would likely say >10% in a single name is too much *only after* doing poorly with one
- Open to data-driven allocation guidance based on what top investors actually do

**Research finding — What the best investors do:**
- Buffett/Munger: Operated with ~5 core positions, up to 25% in highest conviction name
- Munger personally: Only 3 stocks in later years (Berkshire, Costco, Daily Journal)
- Phil Fisher: >20 stocks = incompetence
- Walter Schloss (same tradition): 100+ stocks, also successful
- Practical sweet spot for serious concentrated investors: **10-20 positions**, top 5 = bulk of portfolio
- CFA practitioner guideline: ~5% at cost, ~10% at market per position max
- **Key insight for agent:** Don't enforce rigid percentages. Track **conviction vs. actual sizing** and flag mismatches. 12% in a "meh" hold = problem. 15% in highest conviction = maybe intentional.

---

## 4. Scenario Backlog (To Be Completed)

These are the "day in the life" scenarios that will drive skill extraction and agent design. Items marked ✅ have been discussed; ❓ are still needed.

- ❓ Monday morning summary (what moved, what to watch this week)
- ❓ Significant intraday drop response (NVDA drops 8% — why, thesis check, exposure calc)
- ❓ Cash deployment recommendation ($50k to deploy — where, based on current allocation)
- ❓ Earnings season calendar + pre-earnings briefs
- ❓ Smart money tracking (major investor buys something on watchlist)
- ❓ New position discovery workflow (how Chris finds ideas, what the agent could do)
- ❓ Significant drop reaction (panic check vs. buy more vs. hold — what triggers what)
- ❓ Thesis creation & storage (formalizing why you own something)
- ❓ Rebalancing nudges (allocation drift detection)
- ❓ Weekend/weekly portfolio health check

---

## 5. Skills Inventory (To Be Extracted from Scenarios)

*Will be populated after scenarios are complete. Each scenario gets decomposed into discrete skills, which then cluster naturally into agents.*

Preliminary skills identified so far:
- **Market data fetch** — live prices, volume, fundamentals via yfinance
- **News search** — financial news retrieval and relevance filtering
- **Thesis storage & retrieval** — structured format for investment theses
- **Thesis evaluation** — compare incoming news/data against stored thesis
- **Portfolio math** — P&L, allocation %, sector exposure, benchmark comparison
- **Smart money tracking** — monitor institutional/notable investor filings (13F, etc.)
- **Earnings calendar** — track upcoming report dates for held positions
- **Alert composition & delivery** — format findings and send via Telegram
- **Conviction scoring** — rank positions by conviction to inform sizing decisions

---

## 6. Technical Foundation (Already Built)

- **Mini-PC:** Ubuntu 24.04, static IP 192.168.86.38, headless
- **OpenClaw gateway:** Running, auto-starts on boot, port 18789
- **Telegram bot:** Higgens / @MaresiasWaveBot, operational
- **Portfolio engine (Phase 1, Task 1.1):** `holdings.json` + `portfolio_engine.py` + `README.md` — built, not yet deployed to mini-PC
- **Data layer:** Yahoo Finance (daily brokerage sync), `yfinance` Python library
- **Benchmarks:** SPY / QQQ / IWM
- **Tracking repo:** `github.com/falcon9heavy/openclaw-config`

---

## 7. Next Steps

1. **Resume interview** — cover remaining scenarios (Q5+: new position discovery, drop reactions, proactive alerts, weekly rhythms)
2. **Extract skills from completed scenarios** — map each scenario to discrete capabilities
3. **Cluster skills into agents** — finalize agent boundaries based on natural groupings
4. **Define shared state model** — what's shared, what's per-agent, where does it live
5. **Build first scenario end-to-end** — pick the highest-value scenario and wire it up
6. **Deploy portfolio engine to mini-PC** — prerequisite for any agent work
