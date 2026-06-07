# BTC 15m Arena — Static Fixture Library Implementation Plan V1

Status: docs-only implementation plan.
Date: 2026-06-07
Phase: BTC_15M_ARENA_STATIC_FIXTURE_LIBRARY_IMPLEMENTATION_PLAN_DOCS_ONLY_V2_POWERSHELL_BACKTICK_QUOTING_REPAIR

## 1. Purpose

This document defines the next static fixture-library implementation step for BTC 15m Arena.

The goal is to create a deterministic local scenario library that supports repeatable manual review and later replay-style validation of the existing static scenario calculator.

This plan does not authorize fixture data creation, JSON creation, JavaScript loader creation, route edits, replay UI, live data, bot logic, Polymarket integration, wallet logic, API logic, or order logic.

## 2. Current baseline

- The public BTC 15m Arena route already contains a manual static scenario calculator.
- The local calculator script already exists at `btc-15m-arena/scenario-calculator.js`.
- The fixtures/replay spec is already published at `project_sources/btc-15m-arena/BTC_15M_ARENA_FIXTURES_AND_REPLAY_SPEC_V1.md`.
- The fixture library itself does not exist yet.
- There is no JSON fixture file.
- There is no JavaScript fixture loader.
- There is no replay UI.
- There is no live data.
- There is no bot.
- There is no wallet/API/order logic.

## 3. Future implementation files

The future implementation may be authorized only after this plan is reviewed and committed.

Preferred future scope:

1. `btc-15m-arena/fixtures/static-scenarios.v1.json`
2. Optional limited edit to `btc-15m-arena/index.html` only if a visible replay selector is explicitly authorized later.
3. Optional `btc-15m-arena/fixture-replay.js` only if a separate precheck confirms that a loader is necessary.

Preferred first implementation:

- Create only `btc-15m-arena/fixtures/static-scenarios.v1.json`.
- Do not edit route in the first fixture-library implementation.
- Do not create a loader in the first fixture-library implementation.
- Do not create replay UI in the first fixture-library implementation.
- Keep the first library usable as deterministic source material for later validation.

Alternative future implementation:

- `btc-15m-arena/fixtures/static-scenarios.v1.js` may be considered only if JSON proves unsuitable.
- This alternative is not preferred because JSON is easier to validate as passive data.

## 4. Explicitly out of scope

The future fixture-library implementation must not touch:

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
- `project_sources/` except later docs-only phases
- `tension-cores/`
- `affiliate-friction-auditor/`
- `spectralcode/`
- `ai-assisted-work/`
- any other product in the repository

The future fixture-library implementation must not create:

- wallet connection
- account state
- order state
- order placement
- order execution
- trading automation
- live data feed
- background polling
- real-time signals
- Polymarket API integration

## 5. Fixture library format candidate

The preferred future format is a single JSON document with a versioned top-level structure:

- `schema_version`
- `generated_for`
- `guardrails`
- `scenarios`

Each scenario should be a deterministic object. No scenario should depend on current market data, current date, wallet state, account positions, API responses, or orderbook fetches.

## 6. Scenario object candidate fields

Each scenario object should include:

- `id`
- `title`
- `scenario_archetype`
- `description`
- `position_side`
- `position_size`
- `entry_price`
- `visible_price`
- `simulated_executable_price`
- `opposite_side_hedge_price`
- `hedge_size`
- `fee_slippage_assumption`
- `time_remaining_bucket`
- `liquidity_flag`
- `expected_primary_label`
- `expected_secondary_warnings`
- `expected_net_if_original_wins`
- `expected_net_if_opposite_wins`
- `expected_simulated_min`
- `expected_simulated_max`
- `expected_execution_gap`
- `expected_explanation_points`
- `guardrail_copy`

Optional later fields:

- `notes`
- `source_spec_section`
- `manual_replay_steps`
- `assertions`

## 7. Required initial scenario set

The first fixture library should include exactly eight static scenarios derived from the fixtures/replay spec:

1. Scenario A — Clean no-trade
2. Scenario B — Paper entry only
3. Scenario C — Free-roll candidate
4. Scenario D — Lock-profit candidate
5. Scenario E — Late hedge danger
6. Scenario F — Exit trap
7. Scenario G — Reduce-loss candidate
8. Scenario H — Thin-book false comfort

The first fixture library should not add additional scenarios until these eight pass validation.

## 8. Label mapping

Allowed primary labels:

- `NO_TRADE`
- `ENTER_SIMULATED_POSITION`
- `HOLD`
- `LOCK_PROFIT_SIMULATION`
- `REDUCE_LOSS_SIMULATION`
- `LATE_HEDGE_RISK_REVIEW`
- `EXIT_RISK_WARNING`

Allowed warning labels:

- `EXIT_RISK_WARNING`
- `LATE_HEDGE_RISK_REVIEW`
- `THIN_BOOK_WARNING`
- `EXECUTION_GAP_WARNING`
- `ASSUMPTION_WARNING`
- `NO_LIVE_DATA_GUARDRAIL`

Labels must be descriptive and educational. They must not instruct a user to place trades.

## 9. Calculation compatibility

The future fixtures should align with the existing static calculator formulas:

- `entry_cost = position_size * entry_price`
- `hedge_cost = hedge_size * opposite_side_hedge_price`
- `total_estimated_cost = entry_cost + hedge_cost + fee_slippage_assumption`
- `gross_if_original_wins = position_size`
- `gross_if_opposite_wins = hedge_size`
- `net_if_original_wins = gross_if_original_wins - total_estimated_cost`
- `net_if_opposite_wins = gross_if_opposite_wins - total_estimated_cost`
- `simulated_pl_min = min(net_if_original_wins, net_if_opposite_wins)`
- `simulated_pl_max = max(net_if_original_wins, net_if_opposite_wins)`
- `execution_gap = abs(visible_price - simulated_executable_price)`

The fixture data should include expected outputs to allow manual and scripted validation later.

## 10. Guardrail copy requirements

Every fixture must carry or inherit this guardrail copy:

Simulation only. Manual inputs. No wallet, no orders, no live data, no financial advice.

The future fixture library must preserve these constraints:

- No wallet.
- No private keys.
- No authenticated trading API.
- No orders.
- No order execution.
- No real orders.
- No trading automation.
- No live trading.
- No live data.
- No financial advice.
- No guaranteed profit.
- No guaranteed prediction.
- No risk-free language.
- No sure-win language.
- No real-time signal generation.

## 11. Forbidden implementation patterns

The future fixture-library implementation must not include runtime use of:

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

These tokens are listed as forbidden patterns. Their presence in this document is documentation only and does not authorize implementation.

## 12. First implementation acceptance criteria

A future first implementation may pass only if:

- baseline HEAD matches the expected commit before implementation;
- working tree is clean before implementation;
- only `btc-15m-arena/fixtures/static-scenarios.v1.json` is created;
- no route file is edited;
- no JS loader is created;
- no replay UI is created;
- no live data is introduced;
- no network calls are introduced;
- no wallet/API/order logic is introduced;
- the fixture file contains exactly the required eight scenarios;
- every scenario has the required fields;
- every scenario has allowed labels;
- every scenario has guardrail copy;
- JSON parses successfully;
- numeric fields are numbers, not strings;
- prices are between 0 and 1 where applicable;
- position sizes and hedge sizes are non-negative;
- expected values are internally coherent with the documented formulas;
- no stage, commit, or push happens during first local implementation.

## 13. Validation sequence after this plan

Recommended next phases:

1. `BTC_15M_ARENA_STATIC_FIXTURE_LIBRARY_IMPLEMENTATION_PLAN_DOCS_ONLY_COMMIT_PUSH_V1`
2. `BTC_15M_ARENA_STATIC_FIXTURE_LIBRARY_IMPLEMENTATION_PRECHECK_READ_ONLY_V1`
3. `BTC_15M_ARENA_STATIC_FIXTURE_LIBRARY_IMPLEMENTATION_V1_LOCAL_ONLY`
4. `BTC_15M_ARENA_STATIC_FIXTURE_LIBRARY_COMMIT_PUSH_V1`
5. `BTC_15M_ARENA_STATIC_FIXTURE_LIBRARY_REPLAY_VALIDATION_V1`

Do not skip the commit/push of this plan.
Do not skip the implementation precheck.
Do not create fixture data in this docs-only phase.

## 14. Non-authorization

This document authorizes only a docs-only implementation plan.

It does not authorize:

- fixture data creation;
- JSON fixture creation;
- JavaScript fixture loader creation;
- replay UI;
- route edits;
- live data;
- bot logic;
- wallet/API/order logic;
- Polymarket integration;
- stage;
- commit;
- push.
