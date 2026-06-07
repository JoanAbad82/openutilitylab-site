# OPENUTILITYLAB_BTC_15M_ARENA_PRODUCT_SPEC_AND_STATIC_INTEGRATION_DECISION_V1

Date: 2026-06-07  
Type: Product specification and static integration decision  
Mode: Docs-only  
Repository: `C:\openutilitylab-site`  
Baseline branch: `main`  
Baseline commit: `81a82f7`  
Runtime scope: none  
Implementation scope: none  

## 1. Purpose

This document opens the first formal product specification phase for **BTC 15m Arena**, a proposed Open Utility Lab tool for simulation, replay, and bot-training research around Bitcoin "Up or Down" 15-minute markets.

The product is not a trading bot in its initial scope. It is a controlled simulator and research surface for understanding whether position-management strategies can be measured, compared, and falsified before any real automation is considered.

The core strategic question is:

> How many cheap binary-market positions reach a transformation point before they die?

The product must therefore focus less on directional prediction and more on execution-aware position management.

## 2. Product framing

Working product name:

- BTC 15m Arena

Internal phase/product identifier:

- `OPENUTILITYLAB_BTC_15M_ARENA`

Public route candidate:

- `/btc-15m-arena/`

Future static route path:

- `btc-15m-arena/index.html`

Positioning:

- simulation-only;
- paper-trading;
- bot comparison lab;
- replay/backtesting environment;
- execution-risk education;
- no real-money execution;
- no prediction guarantee;
- no financial advice.

The product should be presented as an analytical lab, not as a gambling product, prediction surface, profit engine, or trading automation system.

## 3. Permanent guardrails

The following guardrails are permanent unless a future phase explicitly changes them with a written risk decision:

- no wallet;
- no private keys;
- no authenticated trading API;
- no real orders;
- no real-money execution;
- no trading automation in MVP;
- no financial advice;
- no predictions as guarantees;
- no claims of profitability;
- no datasets uploaded blindly to the repository;
- no live-data capture until simulation and fixtures exist;
- no large JSONL snapshot archives committed to the repo;
- no toolchain introduction without a separate architecture phase.

If any later feature conflicts with these guardrails, the guardrail wins unless a separate decision document authorizes the change.

## 4. Strategic hypothesis

The hypothesis to test is:

> Buying small, convex, cheap-side positions in a short binary market may be useful if the position can be transformed before resolution into capital recovery, free-roll, partial hedge, locked profit, controlled exit, or a clear no-additional-risk decision.

This is only a hypothesis. It may be false.

The tool must not assume profitability. It must measure the hypothesis against realistic execution constraints:

- visible price versus executable price;
- spread;
- order book depth;
- slippage;
- time remaining;
- distance to price-to-beat;
- volatility;
- cost of hedging;
- liquidity to exit;
- late-window deterioration;
- capital added to rescue a losing position.

## 5. Examples to preserve in product logic

### Free-roll example

Initial position:

- buy 10 Down at 20c;
- cost: 2 dollars.

Transformation:

- Down rises to 40c;
- sell 5 Down;
- recover 2 dollars;
- keep 5 Down with no net capital at risk.

Result:

- free-roll.

### Lock-profit example

Initial position:

- buy 10 Down at 20c;
- cost: 2 dollars.

Later hedge:

- buy 10 Up at 70c;
- additional cost: 7 dollars;
- total cost: 9 dollars;
- payout regardless of outcome: 10 dollars.

Result:

- 1 dollar locked profit.

### Bad hedge example

Initial position:

- buy 10 Down at 20c;
- Down falls to 4c;
- Up rises to 97c.

Bad response:

- buying much more Up at 95c is not a clean hedge;
- it is probably a new bet that increases capital at risk.

Rule:

- never add much more capital to rescue a small losing position.

## 6. What the product must measure

The product must measure position transformation, not only directional accuracy.

Important events:

- position reaches 2x;
- capital recovery becomes possible;
- free-roll becomes possible;
- lock profit becomes possible;
- partial hedge becomes possible;
- controlled exit becomes possible;
- hedge becomes too late;
- no-trade was better than trading;
- holding was better than hedging;
- hedging added risk instead of reducing it.

Important metrics:

- simulated P&L;
- max drawdown;
- trades per window;
- percentage of trades reaching 2x;
- percentage of possible free-rolls;
- percentage of possible lock profits;
- spread cost;
- slippage cost;
- late-window losses;
- no-trade accuracy;
- performance versus RandomBot;
- performance versus NoTradeBot;
- capital recovered versus capital risked;
- time from entry to transformation point;
- frequency of late hedge warnings;
- frequency of avoidable trades.

## 7. Initial bot taxonomy

The first bots must be simple, deterministic, and comparable.

Initial bot candidates:

- `RandomBot`
- `NoTradeBot`
- `MomentumBot`
- `DistanceTimeBot`
- `ExecutionAwareBot`
- `PositionManagerBot`

No complex AI model is allowed in the early phases.

The first useful comparison is not "which bot predicts best", but:

- which bot avoids bad trades;
- which bot manages exits better;
- which bot avoids late hedges;
- which bot transforms cheap positions most often;
- which bot survives realistic execution costs.

## 8. Data model concepts

The future simulator should model at least these entities.

### MarketWindow

Represents one 15-minute BTC Up/Down window.

Candidate fields:

- `windowId`
- `startTime`
- `endTime`
- `priceToBeat`
- `resolutionPrice`
- `resolvedOutcome`
- `snapshots`

### MarketSnapshot

Represents one point in time inside a window.

Candidate fields:

- `timestamp`
- `secondsRemaining`
- `btcPrice`
- `distanceToBeat`
- `upVisiblePrice`
- `downVisiblePrice`
- `upOrderBook`
- `downOrderBook`
- `spread`
- `depth`
- `volatilityEstimate`

### OrderBookSide

Represents executable liquidity.

Candidate fields:

- `price`
- `size`

### SimulatedPosition

Represents a paper position.

Candidate fields:

- `side`
- `size`
- `averageEntryPrice`
- `totalCost`
- `realizedPnL`
- `unrealizedPnL`
- `freeRollSize`
- `capitalRecovered`
- `lockedProfit`
- `riskState`

### BotDecision

Represents a bot action at a snapshot.

Candidate fields:

- `botName`
- `timestamp`
- `action`
- `side`
- `size`
- `reason`
- `expectedExecutionPrice`
- `estimatedSlippage`
- `riskLabel`

Allowed actions:

- `BUY_UP`
- `BUY_DOWN`
- `WAIT`
- `SELL`
- `PARTIAL_SELL`
- `PARTIAL_HEDGE`
- `LOCK_PROFIT`
- `NO_TRADE`

## 9. Simulation model

The simulation engine must not use visible price as if it were executable price.

Minimum future engine functions:

- simulate buy Up/Down;
- simulate sell/close;
- calculate executable price from order book;
- calculate slippage;
- calculate average fill price;
- calculate P&L by outcome;
- detect free-roll possibility;
- detect lock-profit possibility;
- calculate partial hedge;
- detect late hedge;
- score decisions.

The simulator must explicitly distinguish:

- mark price;
- visible quoted price;
- executable average price;
- best ask/bid;
- average fill;
- theoretical payout;
- realized P&L;
- locked outcome.

## 10. Static integration decision

Precheck V2 and V3 corrected the initial technical assumption.

The repository root is not Astro/Preact/TypeScript. It is a static Open Utility Lab website with:

- `index.html`;
- `styles.css`;
- `sitemap.xml`;
- `robots.txt`;
- `README.md`;
- product folders such as `affiliate-friction-auditor`, `tension-cores`, `spectralcode`, and `ai-assisted-work`;
- documentation under `project_sources/microphases`.

Therefore, this product must initially integrate as a static route.

Approved future route pattern:

- `btc-15m-arena/index.html`

Approved future public URL:

- `https://openutilitylab.com/btc-15m-arena/`

Rejected for now:

- `src/pages/...`
- Astro components
- Vite build setup
- new package.json
- npm-based toolchain
- TypeScript pipeline in the root site

Reason:

Introducing a new toolchain only to create the first shell would be excessive scope and would violate the current microphase discipline.

## 11. Future route-shell pattern

When Fase 2 is opened, the route shell should probably follow the static tool-page pattern observed in existing product folders.

Likely structure:

- `btc-15m-arena/index.html`
- global stylesheet: `/styles.css`
- `body class="tool-page"`
- navigation back to Open Utility Lab
- `header class="tool-hero"`
- content panels using `tool-panel zone-card`
- buttons using `button`
- limitations using `note` or dedicated limitations section

Required public copy elements:

- simulation-only;
- no wallet;
- no orders;
- no trading automation;
- no financial advice;
- no profitability claims;
- mock data only initially;
- purpose: execution-risk and bot-behavior study.

## 12. Home integration decision

The root `index.html` currently uses a project-card pattern inside:

- `section#projects.professional-portfolio`

When a public shell exists, a future phase may add a BTC 15m Arena card to the homepage.

That future card should include:

- product name;
- status as simulation/paper lab;
- short explanation;
- guardrail note;
- link to `/btc-15m-arena/`.

No homepage card should be added in this docs-only phase.

## 13. Sitemap and robots decision

No sitemap or robots changes are allowed in this docs-only phase.

Future sitemap update:

When `/btc-15m-arena/` exists as a public route, `sitemap.xml` should add:

- `https://openutilitylab.com/btc-15m-arena/`

Suggested values:

- `changefreq`: monthly
- `priority`: 0.7 or 0.8

Robots:

- no change required for a normal public route;
- future debug/internal routes must be blocked or noindexed.

## 14. README decision

No README change is allowed in this docs-only phase.

Future README update is optional and should only happen after a visible route exists.

If updated later, it should describe BTC 15m Arena as:

- a simulation-only bot lab;
- local/client-side where possible;
- no wallet;
- no orders;
- no financial advice.

## 15. Phase plan

### Phase 0 — Precheck read-only

Status:

- V1 attempted but failed due to PowerShell parser error;
- V2 executed and revealed static-site architecture;
- V3 executed and validated static integration path.

### Phase 1 — Product spec and static integration decision

This document.

Scope:

- docs-only;
- no implementation;
- no route;
- no CSS;
- no sitemap;
- no README;
- no toolchain.

### Phase 2 — Static route shell mock

Future scope:

- create `btc-15m-arena/index.html`;
- static landing;
- mock panel only;
- no real data;
- no API;
- no wallet;
- no orders;
- likely reuse `/styles.css`;
- optionally add homepage card and sitemap only if included in the explicit phase scope.

### Phase 3 — Pure simulation engine

Future scope:

- JS-only pure functions unless a later architecture phase says otherwise;
- execution price;
- slippage;
- P&L;
- free-roll;
- lock profit;
- partial hedge;
- late hedge detection;
- scoring.

### Phase 4 — Baseline bots

Future scope:

- deterministic baseline bots;
- no complex AI.

### Phase 5 — Fixtures/replay

Future scope:

- small versioned mock fixtures;
- deterministic replay;
- compare bots over same windows.

### Phase 6 — Read-only real-data capture

Future scope:

- discover live BTC 15m markets;
- read price-to-beat;
- read Up/Down prices;
- read order books;
- snapshot every 1-5 seconds;
- save JSONL locally;
- do not commit large datasets.

### Phase 7 — Backtesting

Future scope:

- run bots on historical snapshots;
- compare risk-adjusted results;
- measure free-roll and lock-profit frequency;
- measure no-trade baseline.

## 16. Files allowed in this docs-only phase

Allowed file:

- `project_sources/microphases/OPENUTILITYLAB_BTC_15M_ARENA_PRODUCT_SPEC_AND_STATIC_INTEGRATION_DECISION_V1_2026-06-07.md`

No other file is allowed.

## 17. Files explicitly not allowed in this phase

Not allowed:

- `index.html`
- `styles.css`
- `sitemap.xml`
- `robots.txt`
- `README.md`
- `btc-15m-arena/index.html`
- `btc-15m-arena/styles.css`
- `btc-15m-arena/arena.js`
- `package.json`
- any dataset file
- any Polymarket API integration
- any wallet/auth/trading file

## 18. Validation expected for this phase

This phase is valid if:

- exactly one markdown document is created;
- the markdown path is under `project_sources/microphases`;
- no runtime files change;
- no public route is created;
- no CSS changes;
- no sitemap changes;
- no README changes;
- git diff shows only this document;
- git status is clean after commit/push if closure is performed.

## 19. Product risk register

### Risk: gambling/trading framing

The product can be misunderstood as a tool to gamble better.

Mitigation:

- use simulation language;
- avoid profit claims;
- show limitations;
- include no-financial-advice and no-real-orders language.

### Risk: fake edge

Mock fixtures may make weak strategies look strong.

Mitigation:

- compare against `RandomBot` and `NoTradeBot`;
- label fixtures as artificial;
- require real-data backtesting before drawing conclusions.

### Risk: late hedge illusion

Users may think any opposite-side buy reduces risk.

Mitigation:

- explicitly detect late hedge;
- show capital added;
- show when hedge is a new bet.

### Risk: scope creep

Live data, bots, UI, and backtesting can expand too quickly.

Mitigation:

- phase separation;
- no live data before fixtures;
- no implementation inside docs phases.

### Risk: toolchain creep

Adding npm/Astro/TypeScript to the static repo too early could destabilize the site.

Mitigation:

- static route first;
- JS-only only when needed;
- toolchain only by explicit architecture phase.

## 20. Success criteria for the overall MVP

The MVP is successful only if:

- it never executes real orders;
- it never connects a wallet;
- it works first with deterministic fixtures;
- it can compare bots against baselines;
- it shows execution-aware costs;
- it distinguishes free-roll, lock profit, partial hedge, late hedge, and no-trade;
- it teaches when risk is reduced versus increased;
- it remains clear, honest, and non-promotional;
- it does not claim profitability.

## 21. Decision

Decision:

Proceed with BTC 15m Arena as a static Open Utility Lab product concept.

Approved now:

- docs-only specification;
- static integration decision;
- route candidate `/btc-15m-arena/`;
- future path `btc-15m-arena/index.html`;
- no toolchain in the initial route shell;
- no real data until simulation/replay exists.

Not approved now:

- implementation;
- public route creation;
- homepage card;
- sitemap update;
- CSS update;
- simulation JavaScript;
- fixtures;
- live Polymarket data;
- API integration;
- trading or wallet capabilities.

## 22. Recommended next phase

Recommended next phase:

`OPENUTILITYLAB_BTC_15M_ARENA_STATIC_ROUTE_SHELL_MOCK_V1`

Type:

- minimal static implementation

Candidate scope:

- create `btc-15m-arena/index.html`;
- use global `/styles.css`;
- static landing;
- clear disclaimers;
- mock simulator panel;
- no real data;
- no JavaScript engine unless explicitly scoped;
- maybe no homepage card until route shell passes local/manual validation.

Precheck required before implementation:

- confirm git clean;
- confirm docs file exists;
- confirm route still absent;
- inspect `validate-static-site.ps1` if it is going to be used;
- define exact changed files before writing.

## 23. Closure marker

This document establishes the product specification and static integration decision for BTC 15m Arena.

Closure marker:

`OPENUTILITYLAB_BTC_15M_ARENA_PRODUCT_SPEC_AND_STATIC_INTEGRATION_DECISION_V1_DOCS_ONLY_READY`
