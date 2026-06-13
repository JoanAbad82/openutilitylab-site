- No order creation.
# BTC 15m Arena — Product Spec and Decision Model V1

Date: 2026-06-07

Microphase:
BTC_15M_ARENA_PRODUCT_SPEC_AND_DECISION_MODEL_DOCS_ONLY_V1

Status:
Drafted as docs-only artifact after read-only validation.

Baseline:
- Repository: C:\openutilitylab-site
- Branch: main
- Expected HEAD before artifact creation: a128121
- Public visibility validated by Home/Sitemap Public Smoke V2.
- Product-spec contextual guardrail classification validated by Read-Only V2.

---

## 1. Product purpose

BTC 15m Arena is a simulation-only decision-training and scenario-review surface for BTC 15-minute binary market situations.

The product exists to help reason about:
- position states;
- hedge scenarios;
- visible price versus executable price;
- spread;
- thin-book risk;
- late hedge risk;
- exit-risk traps;
- simulated outcome ranges.

The product must not operate as:
- a trading bot;
- a signal service;
- an execution engine;
- a wallet-connected app;
- a Polymarket integration;
- an order-placement system;
- a live trading automation tool;
- a guaranteed-profit or guaranteed-prediction product.

---

## 2. Non-negotiable guardrails

The following guardrails are mandatory:

- simulation-only;
- paper research;
- decision training;
- scenario replay;
- execution-risk awareness;
- no wallet;
- no private keys;
- no orders;
- no real orders;
- no authenticated trading API;
- no trading automation;
- no live trading;
- no financial advice;
- no profitability claims;
- no guaranteed profit;
- no guaranteed prediction;
- no live data at this stage;
- no execution real;
- no auto hedge;
- no auto arbitrage;
- no sure-win strategy.

A sensitive phrase is allowed only when used as an explicit negative guardrail, for example:
- No authenticated trading API.
- No trading automation.
- No real orders.
- No wallet.
- No orders.
- No live trading.

A sensitive phrase is forbidden when used as:
- an affirmative capability;
- a CTA;
- an instruction;
- a promise;
- a real trading feature;
- a wallet/API/order integration.

Forbidden examples:
- Authenticated trading API available.
- Connect wallet.
- Place order.
- Execute order.
- Trading automation supported.
- Real orders enabled.
- Live trading mode.
- Guaranteed profit.
- Guaranteed prediction.

---

## 3. Product language

Allowed language:
- simulation-only;
- paper research;
- decision training;
- scenario replay;
- execution-risk awareness;
- hypothetical hedge;
- simulated executable price;
- simulated P/L range;
- candidate;
- warning;
- assumption;
- no wallet;
- no orders;
- no financial advice;
- no profitability claims.

Forbidden language:
- guaranteed profit;
- guaranteed prediction;
- sure win;
- risk-free;
- execute now;
- place order;
- connect wallet;
- real orders;
- trading automation;
- live trading;
- authenticated trading API;
- auto hedge;
- auto arbitrage;
- financial advice;
- signal.

---

## 4. Decision model V1

The first decision model is simulation/paper-only.

It must label scenarios, calculate hypothetical outcomes, and explain execution-risk tradeoffs. It must not tell the user what real trade to place.

### 4.1 Core decision states

1. NO_TRADE

Use when:
- spread is too wide;
- executable price is materially worse than visible price;
- size is too thin;
- exit path is unclear;
- time remaining makes execution risk unacceptable.

Meaning:
- the scenario is not suitable even for a simulated favorable classification;
- output should emphasize risk and uncertainty.

2. ENTER_SIMULATED_POSITION

Use when:
- a hypothetical entry is being modeled for training;
- all values are manual, fixture-based, or static simulation inputs;
- no real order is created.

Meaning:
- this is a paper scenario only;
- no wallet, API, or live execution is involved.

3. HOLD

Use when:
- the simulated state remains within predefined paper rules;
- no simulated hedge action is necessary yet;
- exit-risk has not crossed a warning threshold.

Meaning:
- maintain simulated exposure in the model;
- do not imply a real-world hold recommendation.

4. LOCK_PROFIT_SIMULATION

Use when:
- a hypothetical hedge could make both outcomes positive or near-positive after estimated costs;
- assumptions are explicit;
- execution-risk warnings are shown.

Meaning:
- this is a simulated lock-profit candidate;
- it must not be described as guaranteed.

5. REDUCE_LOSS_SIMULATION

Use when:
- a hypothetical hedge reduces downside but does not necessarily create profit;
- execution cost still matters;
- the model should show tradeoffs.

Meaning:
- downside mitigation in simulation;
- no promise of favorable result.

6. LATE_HEDGE_RISK_REVIEW

Use when:
- time remaining is low;
- book depth is thin;
- visible price may be misleading;
- hedge execution might fail or fill badly.

Meaning:
- focus on late-stage execution risk;
- warn that apparent hedge opportunities may not be achievable.

7. EXIT_RISK_WARNING

Use when:
- mark/visible price looks favorable;
- executable exit is materially worse;
- spread/depth makes exit uncertain.

Meaning:
- the model should flag that getting out may be worse than the visible market price suggests.

---

## 5. Inputs allowed in V1

The first product specification allows only manual, static, fixture, or user-entered simulation inputs.

Allowed inputs:
- visible price;
- simulated executable price;
- spread;
- position side;
- position size;
- opposite-side hedge price;
- time remaining bucket;
- fee/slippage assumption;
- liquidity/thin-book flag.

Not allowed in V1:
- live Polymarket API data;
- authenticated Polymarket API data;
- wallet state;
- account positions;
- real orders;
- private keys;
- automated polling;
- scraping intended for live execution;
- bot loops;
- orderbook ingestion for live trading;
- trade execution endpoints.

---

## 6. Outputs allowed in V1

Allowed outputs:
- scenario label;
- simulated P/L range;
- lock-profit possible/impossible label;
- hedge cost estimate;
- exit-risk warning;
- no-trade warning;
- explanation text;
- assumptions used;
- sensitivity to slippage;
- warning that visible price may differ from executable price.

Forbidden outputs:
- direct trading instruction;
- real-time signal;
- guaranteed prediction;
- expected profit guarantee;
- order placement recommendation;
- automated execution instruction;
- wallet/API connection prompt;
- instruction to buy/sell;
- instruction to hedge now;
- claim that a real hedge is guaranteed to fill;
- claim that a strategy is risk-free.

---

## 7. Scenario taxonomy V1

### Scenario A — Clean no-trade

Definition:
Spread too wide, size too thin, executable price too poor, or exit path unclear.

Expected output:
- NO_TRADE label;
- explanation of why the scenario is unattractive;
- no profit claim.

### Scenario B — Paper entry only

Definition:
Hypothetical position entered in simulation for later review.

Expected output:
- ENTER_SIMULATED_POSITION label;
- explicit reminder that it is paper-only;
- no real order language.

### Scenario C — Free-roll candidate

Definition:
Simulated state where a hedge could make one side non-negative while leaving upside on the other side.

Required wording:
- candidate;
- hypothetical;
- assumption-dependent;
- not guaranteed.

Forbidden wording:
- guaranteed free-roll;
- risk-free;
- sure win.

### Scenario D — Lock-profit candidate

Definition:
Simulated state where both outcomes may be positive after estimated costs.

Required wording:
- candidate;
- simulated;
- after assumed costs;
- execution-risk warning.

Forbidden wording:
- guaranteed profit;
- guaranteed fill;
- real lock.

### Scenario E — Late hedge danger

Definition:
Time remaining is low and visible price may be misleading due to thin depth, spread, or execution uncertainty.

Expected output:
- LATE_HEDGE_RISK_REVIEW label;
- execution-risk warning;
- no instruction to execute.

### Scenario F — Exit trap

Definition:
Mark/visible price appears favorable but executable exit is materially worse.

Expected output:
- EXIT_RISK_WARNING label;
- explanation of visible versus executable price gap;
- warning about false confidence from displayed price.

---

## 8. Calculation principles

The first calculator implementation, when authorized later, should use simple transparent formulas only.

Possible simulated values:
- gross outcome if UP wins;
- gross outcome if DOWN wins;
- estimated hedge cost;
- estimated slippage cost;
- simulated net range;
- break-even estimate;
- downside estimate.

All calculations must:
- expose assumptions;
- avoid guarantees;
- distinguish visible price from executable price;
- treat liquidity as a risk factor;
- avoid external execution.

No hidden model should produce:
- real-time signals;
- automated buy/sell actions;
- live trading advice;
- implied certainty.

---

## 9. Architecture boundary

Allowed architecture after docs-only closure:
- static local scenario calculator;
- manual input fields;
- hardcoded examples;
- static fixtures only if separately authorized;
- no external API;
- no wallet;
- no order placement;
- no authenticated trading API;
- no live data;
- no automation loop;
- no background bot.

Disallowed architecture:
- Polymarket authenticated integration;
- wallet connection;
- private key handling;
- order execution;
- live trading loop;
- auto hedge;
- auto arbitrage;
- scraping tied to execution;
- signal generation;
- account-specific recommendations.

---

## 10. Implementation sequencing

Correct sequence:

1. Public route shell.
2. Home/sitemap visibility.
3. Public smoke.
4. Product spec read-only.
5. Contextual guardrail classification.
6. Docs-only product spec artifact.
7. Static scenario calculator precheck read-only.
8. Only then consider minimal static implementation.

Do not skip directly from docs-only spec to:
- motor;
- bots;
- fixtures;
- live data;
- JavaScript simulation;
- toolchain;
- Polymarket integration;
- wallet/API/order logic.

---

## 11. Acceptance criteria for future static scenario calculator

A future calculator may proceed only if it satisfies:

- simulation-only language is visible;
- no wallet/API/order prompts exist;
- manual/static inputs only;
- outputs are labelled simulated;
- assumptions are visible;
- scenario labels are explanatory, not prescriptive;
- no real-time signals;
- no guaranteed profit;
- no guaranteed prediction;
- no trading automation;
- no live trading;
- no API integration.

Minimum static calculator should be able to show:
- entered side;
- position size;
- visible price;
- simulated executable price;
- hedge price;
- time bucket;
- estimated slippage;
- simulated outcome range;
- risk warnings.

---

## 12. Current project state after this artifact

At the time this document is created:

- Deploy public visibility is validated.
- Home card is public.
- Sitemap entry is public.
- Route is public.
- Product-spec candidate is accepted.
- "authenticated trading API" has been classified as NEGATED_GUARDRAIL.
- Motor is not started.
- Bots are not started.
- Fixtures are not started.
- Live data is not started.
- JavaScript simulation is not started.
- Toolchain is not added.
- Polymarket integration is not started.
- Wallet/API/order logic is not started.

Recommended next microphase after this docs-only artifact is validated:
BTC_15M_ARENA_PRODUCT_SPEC_AND_DECISION_MODEL_DOCS_ONLY_COMMIT_PUSH_V1

Recommended later product microphase, only after docs commit/push:
BTC_15M_ARENA_STATIC_SCENARIO_CALCULATOR_PRECHECK_READ_ONLY_V1
- No order execution.