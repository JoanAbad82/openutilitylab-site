# BTC 15m Arena — Public Route Smoke Closeout V1

Date: 2026-06-14

Phase:
BTC_15M_ARENA_PUBLIC_ROUTE_SMOKE_CLOSEOUT_DOCS_ONLY_V1

Mode:
Docs-only closeout.

Repository:
C:\openutilitylab-site

Branch:
main

Baseline:
aaa1f66257271ee0bdb962181f0a10215a0ce9b7

Latest commit:
aaa1f66 Add BTC 15m Arena browser smoke closeout

## Purpose

This document closes the read-only public route and public script smoke for the current BTC 15m Arena static/manual scenario calculator surface.

It records the public HTTP evidence, contextual guardrail classification, non-blocking warnings, and the decision that no product patch is required from this phase.

## Public surfaces validated

Route:
https://openutilitylab.com/btc-15m-arena/

Route status:
200

Script:
https://openutilitylab.com/btc-15m-arena/scenario-calculator.js

Script status:
200

Public static route HTTP request count:
2

Market data HTTP request count:
0

Gamma request count:
0

CLOB book request count:
0

## Local repository state during public smoke

HEAD:
aaa1f66257271ee0bdb962181f0a10215a0ce9b7

origin/main:
aaa1f66257271ee0bdb962181f0a10215a0ce9b7

Working tree:
clean

No stage, no commit, and no push were performed in the public smoke phase.

## Artifact hashes at public smoke

Route SHA256:
928c983fa8ed52da5621459c251b3ee553e7b30f108587a46717cc4f97a77eef

Script SHA256:
dc69d19e74adddab136295c5fd82f5d4f3ee1ca54a02169ae75b724ce2bcef93

Product spec SHA256:
f7320b0402f0ca35688f9dbf31d44862116598c87751da7170c5b854efc228da

Final closeout summary SHA256:
1b19fdb81ef979ab42241890816e03cf6125e89eaeabacd4497670ea5c15a945

Browser smoke closeout SHA256:
6755128579c4946f80050f9423f430392c9205baca3aced65a68714c39c99b88

## Public route evidence

The public route returned HTTP 200.

The public route contained:
- BTC 15m Arena
- Static scenario calculator
- btc-scenario-calculator
- btc-scenario-output
- btc15m-fixture-preset
- ./scenario-calculator.js
- Simulation only
- Manual inputs
- No wallet
- No orders
- No live data
- No financial advice

## Public script evidence

The public script returned HTTP 200.

The public script contained:
- BTC15M_STATIC_FIXTURE_PRESETS
- function calculateScenario
- function readNumber
- form.addEventListener
- document.addEventListener
- LOCK_PROFIT_SIMULATION
- REDUCE_LOSS_SIMULATION
- LATE_HEDGE_RISK_REVIEW
- EXIT_RISK_WARNING
- NO_TRADE
- totalEstimatedCost
- executionGap

## Public script forbidden operational patterns

The following patterns were absent from the public script:
- fetch(
- XMLHttpRequest
- WebSocket
- EventSource
- localStorage
- sessionStorage
- privateKey
- apiKey
- createOrder(
- placeOrder(
- executeOrder(
- connectWallet(
- setInterval(
- setTimeout(
- window.ethereum
- ethers
- web3

## Contextual sensitive-term classification

The public route and script were scanned for sensitive terms.

All relevant hits were classified as NEGATED_GUARDRAIL or absent.

Public route:
- wallet: all hits NEGATED_GUARDRAIL
- private keys: all hits NEGATED_GUARDRAIL
- authenticated trading API: all hits NEGATED_GUARDRAIL
- orders: all hits NEGATED_GUARDRAIL
- real orders: all hits NEGATED_GUARDRAIL
- trading automation: all hits NEGATED_GUARDRAIL
- live trading: absent
- live data: all hits NEGATED_GUARDRAIL
- financial advice: all hits NEGATED_GUARDRAIL
- guaranteed profit: absent
- guaranteed prediction: absent
- risk-free: absent
- sure win: absent
- connect wallet: absent
- place order: absent
- execute order: absent
- create order: absent

Public script:
- wallet: all hits NEGATED_GUARDRAIL
- private keys: absent
- authenticated trading API: all hits NEGATED_GUARDRAIL
- orders: all hits NEGATED_GUARDRAIL
- real orders: all hits NEGATED_GUARDRAIL
- trading automation: all hits NEGATED_GUARDRAIL
- live trading: absent
- live data: all hits NEGATED_GUARDRAIL
- financial advice: all hits NEGATED_GUARDRAIL
- guaranteed profit: absent
- guaranteed prediction: absent
- risk-free: absent
- sure win: absent
- connect wallet: absent
- place order: absent
- execute order: absent
- create order: absent

Representative accepted guardrail snippets:
- No wallet.
- No private keys.
- No authenticated trading API.
- No orders of any kind are created or submitted.
- No trading automation in this shell.
- No live data in this route shell.
- Simulation only. Manual inputs. No wallet, no orders, no live data, no financial advice.
- Simulation only. Manual review. No wallet. No authenticated trading API. No real orders. No runtime live data. No financial advice.
- Simulation only. Static local fixture. No wallet, no orders, no live data, no API, no bot.
- Simulation only. No wallet. No authenticated trading API. No real orders. No runtime live data. No trading automation. No financial advice.

## Non-blocking warnings

PowerShell reported final URL unavailable for:
- public route
- public script

Classification:
Non-blocking technical warning.

Reason:
Both surfaces returned HTTP 200 and contained the required content. The warning reflects PowerShell/ResponseUri availability, not a confirmed deployment or routing failure.

Permanent handling rule:
Do not fail a public smoke solely because BaseResponse.ResponseUri / final URL is unavailable when status and content validate.

## Product decision

Public route smoke:
PASS

Public script smoke:
PASS

Local repo state:
PASS

Browser smoke closeout already confirmed:
true

No product patch needed from this phase:
true

The static/manual calculator remains:
- simulation-only
- manual-input only
- paper research / decision-training oriented
- no wallet
- no private keys
- no authenticated trading API
- no real orders
- no order creation
- no order placement
- no order execution
- no trading automation
- no live trading
- no live data
- no collector
- no bot
- no financial advice
- no guaranteed profit
- no guaranteed prediction

## Scope and mutation status

No route changes were made.

No script changes were made.

No home or sitemap changes were made.

No runtime was touched.

No fixture was promoted.

No stage, commit, or push was performed.

This phase is a documentation closeout of a previously completed read-only public validation.

## Future work constraints

Do not open implementation, live data, collector, bot, wallet/API, order logic, package install, visual changes, runtime integration, or fixture promotion from this closeout.

Recommended next phase:
BTC_15M_ARENA_PUBLIC_ROUTE_SMOKE_CLOSEOUT_DOCS_ONLY_COMMIT_PUSH_V1

## Permanent prevention rules

For future public route/script smoke phases:

1. Validate status and required content first.
2. Treat empty final URL as a warning if status/content pass.
3. Classify sensitive terms by context, not literal presence.
4. Accept negated guardrails such as:
   - No wallet
   - No orders
   - No real orders
   - No authenticated trading API
   - No trading automation
   - No live data
   - No financial advice
5. Block only positive capabilities, CTAs, promises, or ambiguous unresolved hits.
6. Validate public script for forbidden operational patterns.
7. Record local HEAD/origin/main and final working tree state.
8. Keep public smoke read-only unless a separate docs-only closeout phase is explicitly authorized.