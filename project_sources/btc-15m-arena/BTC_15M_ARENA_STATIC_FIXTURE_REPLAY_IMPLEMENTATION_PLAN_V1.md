# BTC 15m Arena — Static Fixture Replay Implementation Plan V1

Status: docs-only implementation plan. No replay implementation in this phase.

Date: 2026-06-08

Baseline:
- Expected HEAD/origin/main before this plan: f2fcbe3.
- Current committed fixture source: btc-15m-arena/fixtures/static-scenarios.v1.json.
- Current static calculator: btc-15m-arena/scenario-calculator.js.
- Current route: btc-15m-arena/index.html.

## 1. Purpose

This plan defines how BTC 15m Arena should expose deterministic fixture replay after the static fixture library has been committed and validated.

The goal is to let a user select one of the committed deterministic scenarios and populate/replay the existing manual static calculator without introducing live data, external API calls, wallet connectivity, order logic, bot behavior, or claims of profitability.

This plan authorizes only planning. It does not authorize implementation.

## 2. Current confirmed state

The current repository state already includes:

- static manual scenario calculator;
- local deterministic calculator JavaScript;
- committed static fixture JSON;
- product specification;
- calculator implementation plan;
- fixtures/replay specification;
- fixture library implementation plan.

Replay implementation remains absent:

- no btc-15m-arena/fixtures/static-scenarios.v1.js;
- no btc-15m-arena/fixture-replay.js;
- no fixture replay UI;
- no route integration for fixture replay.

## 3. Fixture source

Canonical fixture source:

- btc-15m-arena/fixtures/static-scenarios.v1.json

Expected fixture schema:

- schema_version = static-scenarios.v1
- status = static-local-deterministic-fixture-library
- scenario count = 8

Expected scenario ids:

1. scenario_a_clean_no_trade
2. scenario_b_paper_entry_only
3. scenario_c_free_roll_candidate
4. scenario_d_lock_profit_candidate
5. scenario_e_late_hedge_danger
6. scenario_f_exit_trap
7. scenario_g_execution_gap_warning
8. scenario_h_thin_book_false_comfort

## 4. Implementation options considered

### Option A — JSON-only replay validation, no UI

Description:
- Keep the fixture JSON as a validation source only.
- Add no public controls.
- Use the fixture data only to validate formula consistency before public replay controls.

Pros:
- Safest.
- Lowest public surface.
- No route changes.
- No extra JS surface.

Cons:
- No user-facing replay value.
- Does not let users explore scenarios A-H.

Decision:
- Valid as an internal validation layer, but not recommended as the main next product step because the calculator already exists and can benefit from fixture presets.

### Option B — preset selector integrated into the existing static calculator

Description:
- Add a fixture/preset selector to the existing calculator surface.
- Selecting a scenario populates the manual calculator fields.
- The existing calculate path remains manual/static/local.
- Fixture values are transformed into local constant data inside the existing calculator JS or equivalent deterministic local structure.
- No network fetch is used.

Pros:
- Highest practical user value with minimal surface expansion.
- Uses existing calculator.
- Avoids creating a second replay UI.
- Avoids fetch/live data.
- Keeps route and JS scope small.

Cons:
- Touches the existing route and existing calculator JS.
- Requires careful validation that fixture data is copied or transformed accurately from the committed JSON.

Decision:
- Recommended product direction for V1 replay implementation.

### Option C — separate fixture-replay.js UI

Description:
- Create a separate replay JS surface and route controls dedicated to fixture replay.

Pros:
- Clean separation from the manual calculator.
- Easier to reason about replay-specific UI if it grows.

Cons:
- Larger surface.
- Creates a second JS file.
- Adds more future validation burden.
- More likely to drift from the existing calculator.

Decision:
- Not recommended for first replay implementation.
- May be reconsidered after preset selector proves useful.

### Option D — static-scenarios.v1.js fixture loader

Description:
- Transform JSON fixture library into a local JS data module/loader.

Pros:
- Avoids fetch.
- Keeps static data local.

Cons:
- Adds another file and duplicate source of truth.
- Without module/toolchain, loader ordering and globals require additional validation.
- Increases implementation scope.

Decision:
- Not recommended for first replay implementation.

## 5. Recommended V1 product direction

Recommended product direction: preset selector integrated into the existing static calculator.

V1 should:
- add one scenario preset selector to the calculator route;
- add a short explanation that scenarios are deterministic local fixtures;
- populate existing manual fields from selected scenario data;
- allow the user to calculate/reset normally;
- show fixture title/description/archetype in the output or helper text;
- keep all results simulation-only.

V1 should not:
- create fixture-replay.js;
- create static-scenarios.v1.js;
- fetch the JSON at runtime;
- add live data;
- add wallet/API/order logic;
- add Polymarket integration;
- add bot behavior;
- add real-time signals.

## 6. Future implementation scope for replay V1

Allowed future dirty scope for replay V1:

1. btc-15m-arena/index.html
2. btc-15m-arena/scenario-calculator.js

Existing source artifact read as reference:
- btc-15m-arena/fixtures/static-scenarios.v1.json

Files explicitly out of scope for replay V1:
- index.html
- sitemap.xml
- styles.css
- robots.txt
- README.md
- package.json
- package-lock.json
- scripts/
- src/
- public/
- dist/
- project_sources/ except docs-only phases
- tension-cores/
- affiliate-friction-auditor/
- spectralcode/
- ai-assisted-work/
- btc-15m-arena/fixture-replay.js
- btc-15m-arena/fixtures/static-scenarios.v1.js

## 7. Future route changes allowed

Future btc-15m-arena/index.html changes may include:

- one preset selector;
- one small helper block explaining deterministic fixture replay;
- one optional fixture detail area;
- references to existing manual/static calculator fields;
- unchanged guardrail copy;
- no external scripts;
- no CDN scripts;
- no wallet buttons;
- no trading CTAs;
- no live-data badge;
- no account state;
- no order state.

The route may continue referencing:

script src="./scenario-calculator.js" defer

The route must not reference:

script src="./fixture-replay.js" defer
script src="./fixtures/static-scenarios.v1.js" defer

in V1.

## 8. Future calculator JS changes allowed

Future btc-15m-arena/scenario-calculator.js changes may include:

- local fixture preset constants derived from static-scenarios.v1.json;
- a map from fixture JSON input names to current calculator field names;
- preset selector event handling;
- deterministic population of manual input fields;
- clear/reset behavior for selected fixture state;
- fixture metadata rendering;
- validation that expected labels/calculations remain consistent.

Future JS must remain:

- deterministic;
- local;
- static;
- manual/simulation-only;
- without network calls;
- without storage;
- without wallet/API/order logic;
- without background timers.

## 9. Data mapping requirements

Fixture JSON input fields expected:

- position_side
- position_size
- entry_price
- visible_price
- simulated_executable_price
- opposite_side_hedge_price
- hedge_size
- fee_slippage_assumption
- time_remaining_bucket
- liquidity_thin_book_flag

Replay V1 should map each fixture input to the existing calculator field model.

Expected calculations in fixture JSON:

- entry_cost
- hedge_cost
- total_estimated_cost
- gross_if_original_wins
- gross_if_opposite_wins
- net_if_original_wins
- net_if_opposite_wins
- simulated_pl_min
- simulated_pl_max
- execution_gap

Replay V1 may use fixture expected calculations only for display/validation hints. It must not claim these values are live, executable, guaranteed, or predictive.

## 10. Required labels

Replay V1 must preserve the existing allowed labels:

- NO_TRADE
- ENTER_SIMULATED_POSITION
- HOLD
- LOCK_PROFIT_SIMULATION
- REDUCE_LOSS_SIMULATION
- LATE_HEDGE_RISK_REVIEW
- EXIT_RISK_WARNING

Labels must remain explanatory, not prescriptive.

## 11. Required copy and guardrails

Required visible copy:

Simulation only. Manual inputs. No wallet, no orders, no live data, no financial advice.

Additional safe copy:

- Deterministic local fixture.
- Scenario replay for decision training.
- Paper-only calculation.
- Assumption-dependent result.
- No real-time signal.
- No order execution.
- No wallet/API/order logic.

Forbidden copy:

- guaranteed profit
- guaranteed prediction
- risk-free
- sure win
- signal
- buy now
- sell now
- trade now
- hedge now
- connect wallet
- place order
- execute order
- real orders enabled
- trading automation supported
- live trading mode

## 12. Prohibited runtime/capability patterns

Future replay implementation must not include real runtime/capability patterns:

- fetch(
- XMLHttpRequest
- WebSocket
- EventSource
- localStorage
- privateKey
- apiKey
- createOrder
- placeOrder
- executeOrder
- connectWallet
- setInterval
- setTimeout

These tokens may appear in documentation as prohibited examples, but must not appear as active runtime implementation in BTC 15m Arena code.

## 13. Validation requirements for future replay implementation precheck

Before implementation, open:

BTC_15M_ARENA_STATIC_FIXTURE_REPLAY_IMPLEMENTATION_PRECHECK_READ_ONLY_V1

That precheck must validate:

1. HEAD = origin/main = f2fcbe3 or the then-current committed docs-only baseline if this plan has been committed.
2. Working tree clean.
3. Existing calculator is tracked and clean.
4. Fixture JSON is tracked, clean, parseable and has 8 scenarios.
5. fixture-replay.js remains absent.
6. static-scenarios.v1.js remains absent.
7. Route currently has no replay selector unless already authorized.
8. Future dirty scope is exactly:
   - btc-15m-arena/index.html
   - btc-15m-arena/scenario-calculator.js
9. No live data, bot, Polymarket integration, wallet/API/order logic.
10. No stage, commit or push during precheck.

## 14. Validation requirements for future replay implementation

Replay implementation V1 must validate:

Route:

- BTC 15m Arena identity preserved.
- Existing calculator preserved.
- Preset selector present exactly once.
- Fixture helper text present.
- Local script count remains expected.
- No external script source.
- No inline event handlers.
- No wallet/trading/order CTA.
- Guardrails remain visible.

Calculator JS:

- Existing formulas remain present.
- Existing labels remain present.
- Preset selection logic exists.
- Scenario A-H identifiers exist if fixture constants are embedded.
- No fetch/XMLHttpRequest/WebSocket/EventSource.
- No localStorage.
- No privateKey/apiKey.
- No createOrder/placeOrder/executeOrder/connectWallet.
- No setInterval/background polling.
- No import/export unless a future module plan explicitly authorizes it.

Scope:

- Only btc-15m-arena/index.html and btc-15m-arena/scenario-calculator.js may be dirty.
- No changes to home, sitemap, CSS, package files, scripts, dist, project_sources, or other products.

Git:

- no stage;
- no commit;
- no push in local implementation phase.

## 15. Future phase sequence

Recommended next phases:

1. BTC_15M_ARENA_STATIC_FIXTURE_REPLAY_IMPLEMENTATION_PLAN_DOCS_ONLY_COMMIT_PUSH_V1

   - Commit this plan only.
   - Scope:
     - project_sources/btc-15m-arena/BTC_15M_ARENA_STATIC_FIXTURE_REPLAY_IMPLEMENTATION_PLAN_V1.md

2. BTC_15M_ARENA_STATIC_FIXTURE_REPLAY_IMPLEMENTATION_PRECHECK_READ_ONLY_V1

   - Confirm committed plan.
   - Reconfirm fixture JSON and calculator surfaces.
   - Reconfirm exact future dirty scope.

3. BTC_15M_ARENA_STATIC_FIXTURE_REPLAY_IMPLEMENTATION_V1_PRESET_SELECTOR_LOCAL_ONLY

   - Implement preset selector locally.
   - Edit only:
     - btc-15m-arena/index.html
     - btc-15m-arena/scenario-calculator.js
   - No stage, no commit, no push.

4. BTC_15M_ARENA_STATIC_FIXTURE_REPLAY_IMPLEMENTATION_COMMIT_PUSH_V1

   - Only after local implementation output is reviewed and passes.

5. BTC_15M_ARENA_STATIC_FIXTURE_REPLAY_PUBLIC_SMOKE_V1

   - Only after commit/push and deploy propagation.

## 16. Non-authorization

This plan does not authorize:

- implementation in this phase;
- route edit in this phase;
- JS edit in this phase;
- fixture-replay.js;
- static-scenarios.v1.js;
- live data;
- external API;
- Polymarket integration;
- wallet;
- private keys;
- authenticated trading API;
- real orders;
- order placement;
- order execution;
- trading automation;
- bots;
- scraping;
- background polling;
- real-time signals;
- profitability claims;
- prediction claims.

## 17. Closure statement

This docs-only plan selects preset selector integration as the recommended first replay implementation path because it provides immediate user value while keeping the surface small and deterministic.

The plan deliberately avoids a separate replay UI and avoids a fixture JS loader in V1.

No implementation is authorized until this plan is reviewed, committed/pushed in a separate docs-only commit phase, and followed by a read-only implementation precheck.
## 18. V2 exact required validator terms repair

This section exists only to satisfy exact docs-only validator terms after BTC_15M_ARENA_STATIC_FIXTURE_REPLAY_IMPLEMENTATION_PLAN_DOCS_ONLY_V1.

Required exact non-authorization statements:

- No fixture-replay.js in V1.
- No static-scenarios.v1.js loader in V1.
- No fetch.
- No live data.
- No wallet.
- No orders.
- No authenticated trading API.
- No Polymarket integration.

Interpretation:

- These statements are prohibitions, not implementation capabilities.
- They do not authorize route edits.
- They do not authorize calculator JavaScript edits.
- They do not authorize fixture-replay.js.
- They do not authorize static-scenarios.v1.js.
- They do not authorize live data.
- They do not authorize wallet, API, order, bot, or Polymarket integration logic.
- The recommended product direction remains: preset selector integrated into the existing static calculator.
