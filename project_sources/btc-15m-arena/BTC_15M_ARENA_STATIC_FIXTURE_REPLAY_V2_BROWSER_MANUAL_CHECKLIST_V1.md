# BTC 15m Arena — Static Fixture Replay V2 Browser Manual Checklist V1

Date: 2026-06-08

Microphase:
$Phase

Mode:
Docs-only manual browser evidence checklist.

Repository baseline:
- Expected HEAD: $ExpectedHead
- Expected branch: main
- Expected public route: https://openutilitylab.com/btc-15m-arena/
- Expected public JS: https://openutilitylab.com/btc-15m-arena/scenario-calculator.js

## Purpose

This document defines the manual browser checklist for the already-closed Static Fixture Replay V2 slice.

The purpose is to collect browser-level evidence that the public BTC 15m Arena route behaves coherently after the fixture replay V2 implementation and parity closeout.

This checklist does not authorize runtime changes, new fixtures, live data, bots, wallet/API/order logic, Polymarket integration, automation loops, or trading execution.

## Preconditions

Before executing the checklist manually:

- Repository is on main.
- HEAD equals origin/main.
- Expected baseline is $ExpectedHead.
- Working tree is clean.
- tc-15m-arena/index.html exists.
- tc-15m-arena/scenario-calculator.js exists.
- tc-15m-arena/fixtures/static-scenarios.v1.json exists.
- tc-15m-arena/fixture-replay.js does not exist.
- tc-15m-arena/fixtures/static-scenarios.v1.js does not exist.
- Static Fixture Replay V2 parity is already closed:
  - input parity: 80/80
  - expected parity: 24/24
  - total parity: 104/104
- The V1 top-level-only parity failure is superseded as a false negative.

## Manual browser setup

Recommended browser steps:

1. Open the public route:
   - https://openutilitylab.com/btc-15m-arena/
2. Hard refresh the page.
3. Open browser DevTools.
4. Confirm the Console has no uncaught JavaScript errors.
5. Confirm the Network panel loads:
   - /btc-15m-arena/
   - /btc-15m-arena/scenario-calculator.js
6. Do not use wallet extensions or trading accounts for this checklist.
7. Do not connect any wallet.
8. Do not place, simulate through, submit, create, execute, or automate real orders.

## General route checks

| Check | Expected result | Status | Notes |
|---|---|---:|---|
| Route loads | HTTP 200 and visible BTC 15m Arena page | PENDING | |
| Identity visible | Page shows BTC 15m Arena | PENDING | |
| Static fixture replay visible | Static fixture replay section is present | PENDING | |
| Preset selector visible | tc15m-fixture-preset selector is visible | PENDING | |
| Manual inputs visible | Manual/static calculator inputs are visible | PENDING | |
| Guardrails visible | Simulation only / Manual inputs / No wallet / No orders / No live data / No financial advice | PENDING | |
| No wallet CTA | No connect-wallet button, account state or wallet prompt | PENDING | |
| No order CTA | No place-order, execute-order, buy-now, sell-now or hedge-now CTA | PENDING | |
| No live-data claim | No live market feed, real-time signal or live-data badge | PENDING | |
| No profitability promise | No guaranteed profit, guaranteed prediction, risk-free or sure-win language | PENDING | |

## Scenario preset checks

For each preset:

1. Select the preset from the fixture selector.
2. Confirm the manual input fields are populated.
3. Confirm the scenario summary updates.
4. Click calculate if required by the current UI flow.
5. Confirm the output remains simulation-only/paper-only.
6. Confirm no wallet/order/live-data capability appears.
7. Record visible result/warnings in the notes column.

| Scenario ID | Expected label | Manual browser checks | Status | Notes |
|---|---|---|---:|---|
| scenario_a_clean_no_trade | Scenario A — Clean no-trade | selector option present; selecting preset populates manual inputs; output remains simulation-only; warnings/summary are coherent | PENDING | |
| scenario_b_paper_entry_only | Scenario B — Paper entry only | selector option present; selecting preset populates manual inputs; output remains simulation-only; warnings/summary are coherent | PENDING | |
| scenario_c_free_roll_candidate | Scenario C — Free-roll candidate | selector option present; selecting preset populates manual inputs; output remains simulation-only; warnings/summary are coherent | PENDING | |
| scenario_d_lock_profit_candidate | Scenario D — Lock-profit candidate | selector option present; selecting preset populates manual inputs; output remains simulation-only; warnings/summary are coherent | PENDING | |
| scenario_e_late_hedge_danger | Scenario E — Late hedge danger | selector option present; selecting preset populates manual inputs; output remains simulation-only; warnings/summary are coherent | PENDING | |
| scenario_f_exit_trap | Scenario F — Exit trap | selector option present; selecting preset populates manual inputs; output remains simulation-only; warnings/summary are coherent | PENDING | |
| scenario_g_execution_gap_warning | Scenario G — Execution gap warning | selector option present; selecting preset populates manual inputs; output remains simulation-only; warnings/summary are coherent | PENDING | |
| scenario_h_thin_book_false_comfort | Scenario H — Thin-book false comfort | selector option present; selecting preset populates manual inputs; output remains simulation-only; warnings/summary are coherent | PENDING | |

## Field mapping checks

| Field | Expected manual behavior | Status | Notes |
|---|---|---:|---|
| position_side | preset maps side into manual UI | PENDING | |
| position_size | preset maps numeric simulated size | PENDING | |
| entry_price | preset maps decimal entry price | PENDING | |
| visible_price | preset maps visible price | PENDING | |
| simulated_executable_price | preset maps executable price assumption | PENDING | |
| opposite_side_hedge_price | preset maps opposite hedge price assumption | PENDING | |
| hedge_size | preset maps hedge size | PENDING | |
| fee_slippage_assumption | preset maps fee/slippage assumption | PENDING | |
| time_remaining_bucket | preset maps time bucket | PENDING | |
| liquidity_thin_book_flag | preset maps liquidity/thin-book flag | PENDING | |

## Output coherence checks

| Output | Expected behavior | Status | Notes |
|---|---|---:|---|
| Scenario label | Uses explanatory simulation label, not a trading instruction | PENDING | |
| Simulated P/L range | Clearly assumption-dependent and simulated | PENDING | |
| Hedge estimate | Shown as hypothetical/simulated, not an instruction | PENDING | |
| Exit-risk warning | Appears for thin-book or execution-gap scenarios | PENDING | |
| Late-hedge warning | Appears for late/final-minute scenarios when applicable | PENDING | |
| No-trade warning | Appears as a risk label, not financial advice | PENDING | |
| Assumptions used | Inputs/assumptions remain visible or understandable | PENDING | |
| Copy guardrail | Result area repeats simulation/no wallet/no orders/no live data/no financial advice | PENDING | |

## Browser console and network checks

| Check | Expected result | Status | Notes |
|---|---|---:|---|
| Console | No uncaught runtime errors after load | PENDING | |
| Console after preset changes | No uncaught runtime errors after selecting A-H | PENDING | |
| Console after calculate/reset | No uncaught runtime errors | PENDING | |
| Network | No calls to Polymarket API or external live-data feeds | PENDING | |
| Network | No wallet/API/order endpoints | PENDING | |
| Network | Only static local site assets expected | PENDING | |


## NO PASS criteria

The manual browser check must be marked NO PASS if any of the following are observed:

- Scenario A-H selection, replay, labels, summary, or result state cannot be classified from browser evidence.
- Any scenario availability contradicts the expected static fixture checklist without a documented limitation.
- User-facing copy implies real trading, live trading, wallet connection, authenticated trading API access, order placement, order execution, trading automation, or financial advice.
- Any positive capability, CTA, or unresolved ambiguous sensitive-term classification remains after review.
- Mojibake or broken copy materially affects interpretation of the simulator, scenarios, guardrails, or result state.
- Any runtime, fixture, loader, live data, CLOB, Gamma retry, wallet/API/order logic, bot, or trading automation file is changed during manual checklist execution.

This section is a checklist guardrail. It does not authorize implementation, runtime repair, live data, wallet/API/order logic, trading automation, fixture expansion, or Polymarket integration.
## Explicit non-goals

This checklist does not test or authorize:

- live data;
- fixture expansion;
- fixture-replay.js;
- static-scenarios.v1.js loader;
- bots;
- scraping;
- Polymarket integration;
- wallet/API/order logic;
- private keys;
- API keys;
- trading automation;
- real-time trading signals;
- order placement;
- order execution;
- auto hedge;
- auto arbitrage;
- financial advice;
- guaranteed prediction;
- guaranteed profit.

## PASS criteria

This checklist can be marked PASS only if:

1. The public route loads.
2. The selector exposes all 8 scenarios A-H.
3. Selecting each scenario populates coherent manual inputs.
4. Outputs remain simulation-only and assumption-dependent.
5. Guardrails are visible in the page and/or result area.
6. No wallet/order/live-data capability appears.
7. Browser console has no uncaught JavaScript errors.
8. Network activity shows no unauthorized live/API/wallet/order calls.
9. No claims of guaranteed profit, guaranteed prediction, risk-free outcome or sure-win strategy appear.
10. Any visual/copy issues are documented without opening runtime changes in this phase.

## FAIL criteria

Mark FAIL if any of the following are observed:

- selector missing one or more A-H presets;
- selecting a preset does not populate expected fields;
- output contradicts the scenario meaning;
- browser console shows uncaught errors tied to the calculator;
- page suggests connecting a wallet;
- page suggests placing or executing an order;
- page presents live data or real-time signal behavior;
- page claims guaranteed profit or guaranteed prediction;
- route loads a real forbidden JS asset such as fixture-replay.js or static-scenarios.v1.js;
- network panel shows unauthorized API/live-data/wallet/order calls.

## Evidence log

Manual tester should complete this section after browser execution.

| Evidence item | Result | Notes |
|---|---:|---|
| Browser used | PENDING | |
| Date/time of manual check | PENDING | |
| Public route screenshot captured | PENDING | |
| Selector screenshot captured | PENDING | |
| Scenario A-H evidence captured | PENDING | |
| Console screenshot captured | PENDING | |
| Network screenshot captured if relevant | PENDING | |
| Final verdict | PENDING | PASS / WARN / FAIL |

## Recommended next phase after this checklist

If this checklist is completed and passes:

BTC_15M_ARENA_STATIC_FIXTURE_REPLAY_V2_BROWSER_MANUAL_CHECKLIST_COMMIT_PUSH_V1

If this checklist reveals browser issues:

BTC_15M_ARENA_STATIC_FIXTURE_REPLAY_V2_BROWSER_MANUAL_CHECKLIST_FINDINGS_CLASSIFICATION_READ_ONLY_V1

If the checklist is intentionally skipped:

BTC_15M_ARENA_ROADMAP_AND_NEXT_PRODUCT_SLICE_SELECTION_READ_ONLY_V1

## Closure note

This artifact is documentation only. It records what must be manually verified in a real browser. It does not modify product runtime behavior and does not authorize any implementation.