# BTC 15m Arena — Fixtures and Replay Spec V1

Status: docs-only specification
Date: 2026-06-07
Phase: BTC_15M_ARENA_FIXTURES_AND_REPLAY_SPEC_DOCS_ONLY_V1

## 1. Purpose

This document defines the first fixtures/replay layer for BTC 15m Arena.

The goal is to create reproducible, static, simulation-only scenario archetypes that can later support manual replay, scenario comparison and paper decision training.

This document does not implement fixtures, JSON data, JavaScript loaders, live data, bots, scraping, Polymarket integration, wallet/API logic or order execution.

## 2. Product boundary

BTC 15m Arena remains:

- simulation-only;
- manual-input based;
- paper research;
- decision training;
- scenario replay;
- execution-risk awareness.

BTC 15m Arena is not:

- a trading bot;
- a live signal product;
- a wallet-connected app;
- an order execution system;
- an arbitrage executor;
- a prediction system;
- financial advice.

## 3. Guardrails

The fixtures/replay layer must preserve these guardrails:

- No wallet.
- No private keys.
- No authenticated trading API.
- No orders.
- No real orders.
- No order execution.
- No trading automation.
- No live trading.
- No live data in this phase.
- No financial advice.
- No guaranteed profit.
- No guaranteed prediction.
- No risk-free claims.
- No sure-win strategy.
- No real-time trading signals.

Any future fixture must be static and deterministic unless a later phase explicitly authorizes another boundary.

## 4. Why fixtures before indicators or bots

Fixtures should come before indicators, motor work or bot logic because they create known reference cases.

A fixture library lets the product test the calculator and decision labels against repeatable examples:

- no-trade;
- paper entry only;
- free-roll candidate;
- lock-profit candidate;
- late hedge danger;
- exit trap;
- reduce-loss candidate;
- thin-book warning.

This improves the product without introducing live data, automation, scraping or execution risk.

## 5. Fixture format candidate

A future static fixture may contain these fields:

```text
id
title
scenario_archetype
description
position_side
position_size
entry_price
visible_price
simulated_executable_price
opposite_side_hedge_price
hedge_size
fee_slippage_assumption
time_remaining_bucket
liquidity_flag
expected_primary_label
expected_secondary_warnings
expected_net_if_original_wins
expected_net_if_opposite_wins
expected_simulated_min
expected_simulated_max
expected_execution_gap
expected_explanation_points
guardrail_copy
```

This is only a candidate schema. It does not create JSON fixtures in this phase.

## 6. Manual replay behavior candidate

A future replay surface may allow a user to:

1. select a static scenario;
2. read the scenario description;
3. manually load or copy the scenario inputs into the calculator;
4. calculate the scenario locally;
5. compare actual calculator output with expected fixture labels;
6. review explanation and guardrails.

The first implementation should prefer explicit manual loading or static examples over hidden automation.

## 7. Scenario archetypes

### Scenario A — Clean no-trade

Purpose:
Identify cases where entry should not be simulated because execution quality or exit path is poor.

Candidate input pattern:

- visible_price looks attractive;
- simulated_executable_price is materially worse;
- spread is wide;
- liquidity_flag = thin or very-thin;
- time_remaining_bucket = early or mid.

Expected label:

- NO_TRADE

Expected warnings:

- EXIT_RISK_WARNING if execution_gap is high or liquidity is thin.

Required explanation:

- visible price is not enough;
- executable price and exit path dominate;
- no order is suggested or created.

### Scenario B — Paper entry only

Purpose:
Represent a hypothetical position used only for replay/training.

Candidate input pattern:

- normal liquidity;
- moderate execution gap;
- position size small;
- no hedge yet;
- time_remaining_bucket = early or mid.

Expected label:

- ENTER_SIMULATED_POSITION or HOLD

Expected warnings:

- none or mild execution-risk note.

Required explanation:

- this is a paper state;
- no live order is created;
- next review depends on later simulated hedge assumptions.

### Scenario C — Free-roll candidate

Purpose:
Represent a scenario where a hypothetical hedge might leave one side near non-negative while preserving upside on the other side.

Candidate input pattern:

- original side already has favorable mark movement;
- hedge price is low enough to reduce downside;
- simulated_min is near zero or slightly negative;
- simulated_max remains materially positive.

Expected label:

- REDUCE_LOSS_SIMULATION or LOCK_PROFIT_SIMULATION depending on simulated_min.

Expected warnings:

- candidate only;
- execution assumptions matter;
- not guaranteed.

Required explanation:

- this is not a guaranteed free-roll;
- liquidity and executable hedge price can invalidate the scenario.

### Scenario D — Lock-profit candidate

Purpose:
Represent a scenario where both simulated outcomes are positive after estimated costs.

Candidate input pattern:

- net_if_original_wins > 0;
- net_if_opposite_wins > 0;
- execution_gap acceptable;
- liquidity_flag = normal or thin, not very-thin.

Expected label:

- LOCK_PROFIT_SIMULATION

Expected warnings:

- execution-risk warning if liquidity is thin;
- assumption-dependent result warning.

Required explanation:

- both outcomes are positive only under manual assumptions;
- no order is suggested;
- no guaranteed profit claim is allowed.

### Scenario E — Late hedge danger

Purpose:
Highlight that a hedge may look attractive but become unreliable near resolution.

Candidate input pattern:

- time_remaining_bucket = final-minute;
- liquidity_flag = thin or very-thin;
- execution_gap elevated;
- hedge depends on thin book.

Expected label:

- LATE_HEDGE_RISK_REVIEW

Expected warnings:

- EXIT_RISK_WARNING;
- no-trade or caution wording.

Required explanation:

- late execution risk can dominate expected P/L;
- visible prices may be stale or misleading;
- no automated hedge is performed.

### Scenario F — Exit trap

Purpose:
Represent cases where displayed mark/visible price looks favorable but executable exit is much worse.

Candidate input pattern:

- visible_price favorable;
- simulated_executable_price materially worse;
- execution_gap >= threshold;
- liquidity_flag = thin or very-thin.

Expected label:

- EXIT_RISK_WARNING or NO_TRADE

Expected warnings:

- visible price is not executable price;
- thin-book exit trap.

Required explanation:

- do not infer liquidity from mark price;
- this is a replay/training scenario only.

### Scenario G — Reduce-loss candidate

Purpose:
Represent cases where a hypothetical hedge reduces downside but does not lock profit.

Candidate input pattern:

- simulated_min remains negative;
- simulated_min is less negative after hedge;
- simulated_max remains acceptable;
- liquidity is not very-thin.

Expected label:

- REDUCE_LOSS_SIMULATION

Expected warnings:

- not profit lock;
- hedge cost can still worsen outcome if execution is poor.

Required explanation:

- reducing downside is different from profit guarantee;
- output remains paper-only.

### Scenario H — Thin-book false comfort

Purpose:
Represent a scenario where the calculated output looks good numerically but liquidity flag should dominate interpretation.

Candidate input pattern:

- net_if_original_wins and net_if_opposite_wins may look acceptable;
- liquidity_flag = very-thin;
- time_remaining_bucket = late or final-minute.

Expected label:

- EXIT_RISK_WARNING
- possibly NO_TRADE depending on final rules.

Expected warnings:

- very-thin liquidity;
- execution assumptions unreliable.

Required explanation:

- calculator arithmetic is not a fill guarantee;
- result is only as good as manual executable assumptions.

## 8. Acceptance rules for future static fixtures

A future fixture implementation may be accepted only if:

- fixture data is static;
- fixture data is local;
- no network request is required;
- no live price is fetched;
- no wallet or account state is read;
- no order-related operation exists;
- expected outputs use candidate/simulated wording;
- every scenario includes guardrail copy;
- every scenario has an explicit educational purpose;
- scenarios are deterministic and reproducible.

## 9. Forbidden future implementation details

The first fixtures/replay implementation must not include runtime use of:

- fetch(
- XMLHttpRequest
- WebSocket
- EventSource
- localStorage unless explicitly authorized later
- privateKey
- apiKey
- createOrder
- placeOrder
- executeOrder
- connectWallet
- setInterval polling
- setTimeout polling
- Polymarket API integration
- wallet state
- account positions
- live orderbook
- live data feed
- real-time signal generation

These strings may appear in documentation as forbidden examples only. They must not appear as runtime capabilities.

## 10. Suggested later implementation sequence

Recommended sequence after this docs-only spec is committed:

1. BTC_15M_ARENA_FIXTURES_AND_REPLAY_SPEC_DOCS_ONLY_COMMIT_PUSH_V1
2. BTC_15M_ARENA_STATIC_FIXTURE_LIBRARY_PRECHECK_READ_ONLY_V1
3. BTC_15M_ARENA_STATIC_FIXTURE_LIBRARY_IMPLEMENTATION_V1_LOCAL_ONLY
4. BTC_15M_ARENA_STATIC_FIXTURE_LIBRARY_COMMIT_PUSH_V1
5. BTC_15M_ARENA_STATIC_FIXTURE_LIBRARY_PUBLIC_SMOKE_V1

Do not skip directly to bots, live data, indicators or Polymarket integration.

## 11. Explicit non-authorization

This document authorizes only a docs-only specification.

It does not authorize:

- creating JSON fixtures;
- creating fixture loaders;
- editing btc-15m-arena/index.html;
- editing btc-15m-arena/scenario-calculator.js;
- adding JavaScript runtime;
- adding live data;
- adding scraping;
- adding bots;
- adding order logic;
- adding wallet/API logic;
- adding indicators;
- changing global styles;
- changing home or sitemap.