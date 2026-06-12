# BTC 15m Arena — Local Static Fixture Consumption Implementation Plan V1

Status: docs-only implementation plan.
Date: 2026-06-12

## Purpose

Plan the next local-only consumption step for the existing CLOB book single-snapshot fixture before any runtime implementation.

This document does not authorize runtime live data, collector, bot, wallet, authenticated API, order logic, order creation, order submission or order execution.

## Current baseline

- HEAD/origin/main expected: 953cd09cc37d84738cc10b1efc53813d6677d97b.
- Last closed line: local static fixture adapter closeout.
- Precheck result: PASS.
- Fixture JSON parses locally.
- Route references scenario-calculator.js and the local fixture JSON.
- Scenario JS contains the local static adapter anchors.

## Existing files

- btc-15m-arena/index.html
- btc-15m-arena/scenario-calculator.js
- btc-15m-arena/fixtures/clob-book-single-snapshot.v1.json
- project_sources/btc-15m-arena/BTC_15M_ARENA_CLOB_BOOK_SINGLE_SNAPSHOT_CONTRACT_V1.md
- project_sources/btc-15m-arena/BTC_15M_ARENA_LOCAL_STATIC_FIXTURE_ADAPTER_CLOSEOUT_V1.md

## Intended implementation boundary

The future implementation may only prepare deterministic local consumption of the existing static fixture.

Allowed future implementation candidates, only after a separate precheck:

1. btc-15m-arena/scenario-calculator.js
2. btc-15m-arena/index.html only if the UI needs explicit status/copy for local static fixture consumption.

No other files are authorized by this plan.

## Explicitly out of scope

- Runtime live data.
- Polymarket live API.
- CLOB live endpoint calls.
- Collector process.
- Bot process.
- Loader/replay execution loop.
- Wallet integration.
- Private keys.
- API keys.
- Authenticated trading API.
- Order creation.
- Order submission.
- Order execution.
- Trading automation.
- Real-time trading signals.
- Financial advice.
- Guaranteed profit.
- Guaranteed prediction.

## Fixture consumption model

The fixture must remain local and static.

The future implementation should:

- read or import only the local fixture data already present in the repository;
- validate fixture shape defensively;
- extract bid/ask summary values from the static snapshot;
- expose best bid, best ask and spread as local static values;
- feed only deterministic values into existing scenario calculations;
- label all outputs as local static fixture / simulation-only;
- avoid any network call;
- avoid any timer loop;
- avoid any account, wallet or order state.

## Required guardrail copy

Any visible result using fixture-derived values must include or preserve:

- Local static fixture only.
- Simulation only.
- No wallet.
- No authenticated trading API.
- No real orders.
- No runtime live data.
- No trading automation.
- No financial advice.

## Validation requirements for future implementation

A future implementation phase must validate:

- dirty scope exactly matches the authorized files;
- no fetch(
- no XMLHttpRequest;
- no WebSocket;
- no EventSource;
- no localStorage unless separately authorized;
- no privateKey;
- no apiKey;
- no createOrder;
- no placeOrder;
- no executeOrder;
- no connectWallet;
- no setInterval;
- no setTimeout for polling or automation;
- fixture JSON still parses;
- fixture guardrails remain present;
- outputs remain simulation-only.

## Acceptance criteria

The future implementation can pass only if:

1. It consumes only the local static fixture.
2. It performs deterministic calculations only.
3. It does not call any external network.
4. It does not introduce wallet/API/order capabilities.
5. It does not introduce live data, collector or bot behavior.
6. It keeps the repository diff small and auditable.
7. It leaves stage/commit/push for a separate controlled phase.

## Next phase after this plan

BTC_15M_ARENA_LIVE_DATA_SOURCE_CLOB_BOOK_REPEATABLE_CAPTURE_LOCAL_STATIC_FIXTURE_CONSUMPTION_IMPLEMENTATION_PRECHECK_READ_ONLY_V1

That phase must be read-only and must define exact implementation scope before code changes.

## Non-authorization statement

This plan authorizes planning only. It does not authorize implementation, runtime live data, collector, bot, wallet/API/order logic or real orders.
