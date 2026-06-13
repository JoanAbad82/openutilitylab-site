# BTC 15m Arena — Static Scenario Calculator Browser Smoke Closeout V1

Date: 2026-06-14

Phase:
BTC_15M_ARENA_STATIC_SCENARIO_CALCULATOR_BROWSER_SMOKE_CLOSEOUT_DOCS_ONLY_V1

Mode:
Docs-only closeout.

Repository:
C:\openutilitylab-site

Branch:
main

Baseline:
1a7368d5b3b1afe894de459a7f17f3bde6ed1b16

Latest commit:
1a7368d Complete BTC 15m Arena product spec order guardrails

## Purpose

This document closes the browser-smoke validation chain for the existing BTC 15m Arena static/manual scenario calculator.

It records the technical failures in Browser Smoke V1 and V2, the successful Browser Smoke V3, and the operational guardrails that must remain in force before any future phase.

## Validated artifacts

Route:
btc-15m-arena/index.html

Route SHA256:
928c983fa8ed52da5621459c251b3ee553e7b30f108587a46717cc4f97a77eef

Script:
btc-15m-arena/scenario-calculator.js

Script SHA256:
dc69d19e74adddab136295c5fd82f5d4f3ee1ca54a02169ae75b724ce2bcef93

Product spec:
project_sources/btc-15m-arena/BTC_15M_ARENA_PRODUCT_SPEC_AND_DECISION_MODEL_V1.md

Product spec SHA256:
f7320b0402f0ca35688f9dbf31d44862116598c87751da7170c5b854efc228da

Final closeout summary:
project_sources/btc-15m-arena/BTC_15M_ARENA_REAL_SNAPSHOT_COLLECTION_CAPTURE_V2_FINAL_CLOSEOUT_SUMMARY_V1.md

Final closeout summary SHA256:
1b19fdb81ef979ab42241890816e03cf6125e89eaeabacd4497670ea5c15a945

## Validation chain

### Static scenario calculator precheck

Result:
PASS.

The route and script existed, the product spec and summary hashes matched expectations, and the route contained the expected static/manual calculator surface.

### Existing script review V2 count-safe

Result:
PASS.

The script was reviewed read-only after fixing the earlier `.Count` scalar issue. The calculator was classified as likely functional static/manual calculator.

### Local Smoke V1

Result:
NO PASS.

Classification:
False negative caused by literal-name expectations.

The smoke expected internal names that were not literal matches in the implementation:
- BTC15M_DECISION_LABELS
- function renderResult
- totalCost
- secondaryWarnings

This did not prove a functional calculator failure.

### Local Smoke V2 behavior-contract equivalence

Result:
PASS.

The V2 confirmed semantic equivalence:
- decision labels existed as explicit state labels;
- result rendering existed via DOM construction and appendChild;
- total cost existed as totalEstimatedCost;
- warnings existed through expected_secondary_warnings and warning classifications.

### Browser Smoke V1

Result:
NO PASS technical.

Cause:
The harness relied on Blob download / anchor.download to create browser-smoke-result.json. Chrome/headless did not produce the result file, and the user observed a profile/session picker side effect.

Classification:
Harness failure, not calculator failure.

### Browser Smoke V2 dump-dom result

Result:
NO PASS technical.

Cause:
Chrome returned DOM with --dump-dom, but the injected probe marker was not present before the DOM was dumped.

Classification:
Harness timing/extraction failure, not calculator failure.

### Browser Smoke V3 virtual-time DOM probe

Result:
PASS.

Configuration that worked:
- no Chrome --version call;
- no Blob download;
- temporary user-data-dir;
- route/script copied to TEMP outside the repo;
- probe injected only into the temporary route copy;
- --headless=new;
- --dump-dom;
- --virtual-time-budget=8000;
- --run-all-compositor-stages-before-draw;
- --allow-file-access-from-files;
- JSON result emitted to:
  <pre id="btc15m-smoke-result">...</pre>
- JSON extracted from stdout.

## Browser Smoke V3 evidence

Browser path:
C:\Program Files\Google\Chrome\Application\chrome.exe

Browser result channel:
dump_dom_pre_json_virtual_time

Browser execution:
performed

Browser smoke pass:
true

Browser issue count:
0

Network requests:
[]

Probe inserted:
true

Preset option count:
8

Preset selected:
scenario_d_lock_profit_candidate

Observed values after preset:
- entryPriceAfterPreset: 0.24
- visiblePriceAfterPreset: 0.73
- executablePriceAfterPreset: 0.57
- hedgePriceAfterPreset: 0.42
- hedgeSizeAfterPreset: 30

Observed output:
- LOCK_PROFIT_SIMULATION
- Entry cost: 7.20
- Hedge cost: 12.60
- Total estimated cost: 19.80
- Net if original side wins: 10.20
- Net if opposite side wins: 10.20
- Simulated P/L range: 10.20 to 10.20
- Execution gap: 0.1600
- Time bucket: early
- Liquidity flag: normal
- EXIT_RISK_WARNING: visible price and executable price differ materially.

Visible guardrail text:
Simulation only. Manual inputs. No wallet, no orders, no live data, no financial advice.

## Functional conclusion

The existing static/manual scenario calculator passed browser/headless smoke for the lock-profit candidate scenario.

The calculator renders a visible simulated output with:
- scenario state;
- entry cost;
- hedge cost;
- total estimated cost;
- net if original side wins;
- net if opposite side wins;
- simulated P/L range;
- execution gap;
- timing bucket;
- liquidity flag;
- warning text;
- guardrails.

No functional patch is warranted based on this browser-smoke chain.

## Scope and mutation status

Browser Smoke V3 did not write to repo files.

Temporary files were written outside the repo and cleanup was attempted successfully.

Final repo state after Browser Smoke V3:
- HEAD unchanged;
- origin/main unchanged;
- working tree clean;
- cached diff count 0;
- unstaged diff count 0.

## Guardrails preserved

The calculator remains:
- simulation-only;
- manual-input only;
- static/local;
- paper research / decision-training oriented;
- no wallet;
- no private keys;
- no authenticated trading API;
- no real orders;
- no order creation;
- no order placement;
- no order execution;
- no trading automation;
- no live data;
- no collector;
- no bot;
- no financial advice;
- no guaranteed profit;
- no guaranteed prediction.

## Future work constraints

Do not open:
- live data;
- collector;
- bot;
- wallet/API;
- order logic;
- package install;
- runtime integration;
- fixture promotion;
- visual changes;
- broad implementation.

The next phase, if this docs-only artifact validates locally, should be a commit/push phase limited to this closeout document.

Recommended next phase:
BTC_15M_ARENA_STATIC_SCENARIO_CALCULATOR_BROWSER_SMOKE_CLOSEOUT_DOCS_ONLY_COMMIT_PUSH_V1

## Permanent prevention rules

For future browser smoke phases on Windows/Chrome:

1. Do not rely on Chrome `--version` when it can open a profile selector.
2. Do not rely on Blob download / anchor.download as the only result channel.
3. Use a temporary user-data-dir.
4. Copy route/script to a temporary directory outside the repo.
5. Inject probes only into temporary copies.
6. Use `--dump-dom` plus `--virtual-time-budget`.
7. Emit JSON to a stable DOM marker:
   `<pre id="btc15m-smoke-result">...</pre>`
8. Extract JSON from stdout.
9. Validate issue count 0.
10. Confirm the repo is clean after the smoke.

Do not patch product code because of harness failures. Patch only if a browser JSON result reports a real functional issue.