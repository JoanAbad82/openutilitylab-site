# BTC 15m Arena — Static Scenario Calculator Implementation Plan V1

Date: 2026-06-07

Microphase:
BTC_15M_ARENA_STATIC_SCENARIO_CALCULATOR_IMPLEMENTATION_PLAN_DOCS_ONLY_V1

Status:
Docs-only implementation plan. No runtime implementation in this phase.

Baseline:
- Repository: C:\openutilitylab-site
- Branch: main
- Expected HEAD before plan creation: 372931b
- Product spec already published:
  project_sources/btc-15m-arena/BTC_15M_ARENA_PRODUCT_SPEC_AND_DECISION_MODEL_V1.md
- Static scenario calculator precheck already passed.
- Route currently has no script tags, no forms, no inputs, no buttons, no inline event handlers, and no calculator runtime.

---

## 1. Purpose

This document fixes the minimum implementation plan for a future static, manual, simulation-only scenario calculator for BTC 15m Arena.

The calculator must support paper decision training and scenario review only.

It must not become:
- a trading bot;
- a real-time signal tool;
- a live market-data tool;
- a Polymarket integration;
- a wallet-connected app;
- an order-placement system;
- an automated hedge/arbitrage system;
- a financial advice surface.

---

## 2. Authorized future implementation scope

The recommended future implementation should use Option B from the precheck:

1. `btc-15m-arena/index.html`
2. `btc-15m-arena/scenario-calculator.js`

Rationale:
- keeps route structure and calculator logic separated;
- avoids toolchain changes;
- avoids global scripts;
- avoids package changes;
- avoids touching unrelated products;
- keeps review scope small.

No CSS file should be touched initially unless a separate precheck proves the route cannot remain usable with existing styles.

---

## 3. Files explicitly out of scope for the future implementation phase

Do not touch without separate authorization:

- `index.html`
- `sitemap.xml`
- `styles.css`
- `robots.txt`
- `README.md`
- `package.json`
- `package-lock.json`
- `scripts/`
- `src/`
- `public/`
- `dist/`
- `project_sources/` except docs-only phases
- `tension-cores/`
- `affiliate-friction-auditor/`
- `spectralcode/`
- `ai-assisted-work/`

Do not introduce:
- fixtures;
- live data;
- API integrations;
- scraping;
- background loops;
- wallet logic;
- order logic;
- authenticated trading API logic.

---

## 4. Inputs for V1 calculator

All inputs must be manual/static user inputs.

Required fields:

1. Position side
   - allowed values: UP, DOWN

2. Position size
   - numeric, shares/contracts in simulation

3. Entry price
   - numeric, decimal between 0 and 1
   - user-entered simulated entry price

4. Visible price
   - numeric, decimal between 0 and 1
   - displayed/mark/reference price

5. Simulated executable price
   - numeric, decimal between 0 and 1
   - used to model fill quality versus visible price

6. Opposite-side hedge price
   - numeric, decimal between 0 and 1
   - price for hypothetical hedge on the opposite outcome

7. Hedge size
   - numeric
   - shares/contracts to hypothetically hedge

8. Fee/slippage assumption
   - numeric, currency amount or per-share estimate
   - can default to 0 in V1, but must remain visible

9. Time remaining bucket
   - allowed values:
     - early
     - mid
     - late
     - final-minute

10. Liquidity/thin-book flag
   - allowed values:
     - normal
     - thin
     - very-thin

---

## 5. Core formulas for V1

All formulas are simulation-only and assumption-dependent.

### 5.1 Entry cost

`entry_cost = position_size * entry_price`

### 5.2 Hedge cost

`hedge_cost = hedge_size * opposite_side_hedge_price`

### 5.3 Total estimated cost

`total_estimated_cost = entry_cost + hedge_cost + fee_slippage_assumption`

### 5.4 Gross payout if original side wins

If original side wins:

`gross_if_original_wins = position_size`

The hedge loses.

### 5.5 Gross payout if opposite side wins

If opposite side wins:

`gross_if_opposite_wins = hedge_size`

The original position loses.

### 5.6 Net if original side wins

`net_if_original_wins = gross_if_original_wins - total_estimated_cost`

### 5.7 Net if opposite side wins

`net_if_opposite_wins = gross_if_opposite_wins - total_estimated_cost`

### 5.8 Simulated P/L range

`simulated_pl_min = min(net_if_original_wins, net_if_opposite_wins)`

`simulated_pl_max = max(net_if_original_wins, net_if_opposite_wins)`

### 5.9 Spread / execution gap

`execution_gap = abs(visible_price - simulated_executable_price)`

This gap must be shown as a warning input, not as a trading signal.

---

## 6. Scenario labels

The calculator may output only explanatory labels.

Allowed labels:

1. `NO_TRADE`
   - when the scenario is unattractive or risky under the entered assumptions.

2. `ENTER_SIMULATED_POSITION`
   - only for paper scenario modelling.
   - must not imply a real entry.

3. `HOLD`
   - simulated state remains inside paper assumptions.
   - must not imply a real hold recommendation.

4. `LOCK_PROFIT_SIMULATION`
   - both simulated outcomes are positive after assumptions.
   - must be labelled candidate / simulated / not guaranteed.

5. `REDUCE_LOSS_SIMULATION`
   - hedge reduces downside but does not produce two positive outcomes.

6. `LATE_HEDGE_RISK_REVIEW`
   - time remaining is late/final-minute and execution assumptions are fragile.

7. `EXIT_RISK_WARNING`
   - visible price and executable price differ materially, or liquidity flag is thin/very-thin.

---

## 7. Label logic candidate

The future implementation may use simple deterministic rules.

Suggested rule order:

1. If required numeric inputs are invalid:
   - show validation warning;
   - do not produce scenario label.

2. If liquidity is `very-thin`:
   - include `EXIT_RISK_WARNING`.

3. If time bucket is `final-minute`:
   - include `LATE_HEDGE_RISK_REVIEW`.

4. If `execution_gap >= 0.05`:
   - include `EXIT_RISK_WARNING`.

5. If both:
   - `net_if_original_wins > 0`
   - `net_if_opposite_wins > 0`
   then primary label:
   - `LOCK_PROFIT_SIMULATION`

6. Else if:
   - `simulated_pl_min >= -0.05 * total_estimated_cost`
   then candidate label:
   - `REDUCE_LOSS_SIMULATION`

7. Else:
   - `NO_TRADE`

The thresholds are initial static heuristics for simulation review only. They are not trading advice.

---

## 8. Output requirements

The calculator should show:

- scenario label;
- simulated net if original side wins;
- simulated net if opposite side wins;
- simulated P/L range;
- entry cost;
- hedge cost;
- total estimated cost;
- execution gap;
- assumptions used;
- warning text when applicable.

Every result block must include:

`Simulation only. Manual inputs. No wallet, no orders, no live data, no financial advice.`

---

## 9. Required copy / guardrails

Visible route copy must continue to state:

- Simulation-only.
- Manual inputs only.
- No wallet.
- No private keys.
- No authenticated trading API.
- No real orders.
- No trading automation.
- No live data.
- No financial advice.
- No guaranteed profit.
- No guaranteed prediction.

Do not use CTA language such as:
- connect wallet;
- place order;
- execute order;
- trade now;
- buy now;
- sell now;
- hedge now;
- guaranteed;
- risk-free;
- sure win;
- signal.

---

## 10. JavaScript boundaries for future implementation

If `btc-15m-arena/scenario-calculator.js` is created later, it must:

Allowed:
- read manual form inputs;
- validate numeric ranges;
- calculate static formulas;
- render output text;
- render warnings;
- use deterministic local calculations only.

Forbidden:
- `fetch`;
- `XMLHttpRequest`;
- `WebSocket`;
- `EventSource`;
- `localStorage` unless separately authorized;
- wallet libraries;
- private key handling;
- API keys;
- Polymarket API calls;
- order creation;
- order placement;
- order execution;
- background intervals for live polling;
- signals based on live data.

Forbidden tokens/patterns in the future JS:
- `fetch(`
- `XMLHttpRequest`
- `WebSocket`
- `EventSource`
- `localStorage`
- `privateKey`
- `apiKey`
- `createOrder`
- `placeOrder`
- `executeOrder`
- `connectWallet`
- `setInterval`
- `setTimeout` if used for polling or automation

---

## 11. HTML boundary for future implementation

Future route edit may add:

- one calculator section;
- manual input fields;
- one calculate/reset button pair;
- one output area;
- visible guardrail text;
- one local script reference:
  `<script src="./scenario-calculator.js" defer></script>`

Future route edit must not add:

- external scripts;
- CDN scripts;
- wallet buttons;
- trading CTAs;
- live data badges;
- account state;
- order state;
- hidden forms for execution.

---

## 12. Validation plan for future implementation phase

A later implementation phase must validate:

Git:
- branch is `main`;
- HEAD equals origin/main;
- HEAD equals expected baseline;
- working tree clean before edit;
- final dirty scope exact.

Allowed dirty scope:
- `btc-15m-arena/index.html`
- `btc-15m-arena/scenario-calculator.js`

Required content checks:
- route references `scenario-calculator.js`;
- route keeps all guardrails;
- JS file exists;
- JS contains no network/API/wallet/order patterns;
- output copy contains `Simulation only`;
- output copy contains `No wallet`;
- output copy contains `No orders`;
- output copy contains `No live data`;
- output copy contains `No financial advice`.

Forbidden checks:
- no `fetch(`;
- no `WebSocket`;
- no `XMLHttpRequest`;
- no `EventSource`;
- no `privateKey`;
- no `apiKey`;
- no `createOrder`;
- no `placeOrder`;
- no `executeOrder`;
- no `connectWallet`;
- no `guaranteed profit`;
- no `guaranteed prediction`;
- no `risk-free`;
- no `sure win`.

Diff checks:
- exact file scope only;
- no unrelated products;
- no package/toolchain changes;
- no CSS unless separately authorized;
- no visible `^M` line-ending pollution.

---

## 13. Recommended next implementation microphase

Only after this plan is reviewed and committed/pushed, the next technical phase should be:

`BTC_15M_ARENA_STATIC_SCENARIO_CALCULATOR_IMPLEMENTATION_PRECHECK_V1`

Recommended purpose:
- validate baseline after docs-only plan;
- confirm the plan artifact exists;
- confirm route still has no calculator;
- confirm exact files allowed;
- prepare minimal implementation block.

Implementation should still not happen in the precheck. The first actual implementation should be a separate minimal-diff phase.

---

## 14. Current state after this plan

At plan creation time:

- public route exists;
- public home card exists;
- public sitemap entry exists;
- public smoke is closed;
- product spec is published;
- calculator precheck is closed;
- no calculator is implemented;
- no JS exists for BTC 15m Arena;
- no fixtures exist;
- no live data exists;
- no bots exist;
- no wallet/API/order logic exists;
- no Polymarket integration exists.

This plan authorizes only planning. It does not authorize implementation.