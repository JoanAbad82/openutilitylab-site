# BTC 15m Arena — Live Data Source Probe Result Classification V1

Status: docs-only classification.
Date: 2026-06-08.
Repository: C:\openutilitylab-site.
Baseline expected before this classification: HEAD equals origin/main equals 77b9327.

This document classifies the result of:

BTC_15M_ARENA_LIVE_DATA_SOURCE_PROBE_READ_ONLY_V3_FIXED_OBJECT_PROPERTY_ENUMERATION

This document does not authorize implementation.

No runtime fetch is authorized.
No UI live data is authorized.
No polling is authorized.
No WebSocket is authorized.
No serverless proxy is authorized.
No bot is authorized.
No wallet is authorized.
No private keys are authorized.
No API keys are authorized.
No authenticated trading API is authorized.
No order creation is authorized.
No order placement is authorized.
No order execution is authorized.
No trading automation is authorized.
No financial advice is authorized.
No guaranteed profit is authorized.
No guaranteed prediction is authorized.

---

## 1. Classification summary

The V3 probe is classified as:

PASS_TECHNICAL_READ_ONLY_WITH_BLOCKING_DISCOVERY_WARNINGS

Meaning:

- The probe script completed safely.
- It reached final guardrail validation.
- It left the repository unchanged.
- It confirmed that documentation endpoints were reachable.
- It confirmed that Gamma public endpoints were reachable.
- It confirmed that Gamma responses were JSON-parseable.
- It confirmed that the fixed market-like object collector reached counts.
- It did not resolve a BTC 15m candidate market.
- It did not discover CLOB token IDs for BTC 15m.
- It did not probe CLOB orderbook or price endpoints for a valid BTC 15m market.

Therefore:

- The read-only probe phase can be considered technically closed.
- Live data implementation remains blocked.
- A more precise discovery phase is required before any runtime work.

---

## 2. What V3 proved

V3 proved the following:

1. Local baseline was valid.
   - branch: main
   - HEAD: 77b9327
   - origin/main: 77b9327
   - working tree: clean

2. The live data source contract exists and is readable.

3. Public documentation endpoints were reachable.

4. Gamma public discovery endpoints were reachable.

5. Gamma public discovery responses were parseable as JSON.

6. Market-like object collection no longer aborts on PowerShell object enumeration.

7. The collector reached:

   total_market_like_object_count = 1944

8. The probe completed final read-only guardrail checks.

9. The probe performed no file writes.

10. The probe performed no stage, commit, or push.

11. The probe did not request wallet credentials.

12. The probe did not request API keys.

13. The probe did not use authenticated trading endpoints.

14. The probe did not place, create, execute, cancel, or prepare orders.

---

## 3. What V3 did not prove

V3 did not prove that BTC 15m live data is ready to implement.

Unproven items:

1. No unequivocal BTC 15m market candidate was found.

2. No market id was selected.

3. No condition id was selected.

4. No CLOB token IDs were selected.

5. No CLOB orderbook shape was validated.

6. No CLOB BUY price shape was validated.

7. No CLOB SELL price shape was validated.

8. No browser CORS decision was made.

9. No frontend runtime shape was defined.

10. No staleness policy was validated against a real BTC 15m market response.

11. No fallback behavior was validated.

12. No manual refresh UI contract was validated against real source shape.

---

## 4. Warning classification

### Warning 1

Text:

Gamma probe found no clear BTC 15m candidate with current heuristic.

Classification:

BLOCKING_FOR_IMPLEMENTATION

Reason:

A live data surface cannot be built until the resolver can identify the correct BTC 15m market. A broad public search returning JSON is not enough. The system must resolve a current, active BTC 15m binary market unambiguously.

Decision:

Do not implement live data from this result.

---

### Warning 2

Text:

No CLOB token ids discovered; skipping CLOB orderbook/price probe.

Classification:

BLOCKING_FOR_IMPLEMENTATION

Reason:

CLOB book and price endpoints require valid token IDs from the correct market. Without valid token IDs, there is no source contract for executable price, bid, ask, spread, depth, or exit-risk calculations.

Decision:

Do not implement CLOB UI, price display, orderbook readout, spread display, or live snapshot cards from this result.

---

## 5. Why candidate_count equals zero may have happened

The zero-candidate result does not prove that a BTC 15m market does not exist.

Possible explanations:

1. The search terms were too broad.

2. The search terms were not aligned with the exact Polymarket naming convention.

3. BTC 15m markets may be temporal, rotating, or grouped under an event or series not matched by the heuristic.

4. The relevant event text may not include the exact terms "15m", "15 minute", or "up or down".

5. The relevant market may use a slug or title pattern not captured by the current candidate text builder.

6. The Gamma events endpoint may expose nested markets whose text requires deeper or different parsing.

7. The Gamma markets endpoint search may return noisy results unrelated to BTC because search ranking may match broader crypto terms or unrelated descriptions.

8. The current active market may not have been present during the probe window.

9. The resolver may need a known series slug, event slug, tag, or manually captured URL as a seed.

10. The market may require a specialized discovery strategy based on time windows rather than simple text search.

---

## 6. V4 discovery recommendation

A V4 read-only probe is recommended before implementation.

Recommended phase name:

BTC_15M_ARENA_LIVE_DATA_SOURCE_DISCOVERY_PROBE_READ_ONLY_V4_PRECISE_BTC_15M_RESOLVER

Purpose:

Find a current BTC 15m candidate more precisely, extract token IDs, and probe CLOB public read endpoints only after a valid candidate is found.

V4 should remain read-only.

V4 should not modify files.
V4 should not stage.
V4 should not commit.
V4 should not push.
V4 should not touch UI.
V4 should not introduce runtime fetch.
V4 should not create a proxy.
V4 should not use wallet, API keys, authenticated trading API, or order endpoints.

---

## 7. Suggested V4 discovery strategy

V4 should improve discovery in stages.

### Stage 1 — Broader but logged Gamma search

Try multiple read-only Gamma search strings and print top titles/slugs:

- bitcoin up or down
- btc up or down
- bitcoin 15 minute
- btc 15 minute
- bitcoin 15m
- btc 15m
- bitcoin higher lower
- btc higher lower
- bitcoin above below
- btc above below
- up or down bitcoin
- up or down btc

For each result, log:

- endpoint used
- id
- title
- question
- slug
- event slug if present
- series slug if present
- start date
- end date
- active
- closed
- accepting orders
- enable order book
- clob token ids count
- candidate text

### Stage 2 — Candidate scoring rather than binary heuristic

Score candidates using weighted terms:

Positive terms:

- bitcoin
- btc
- up
- down
- higher
- lower
- above
- below
- 15m
- 15 minute
- 15-minute
- next 15
- end of
- close
- price

Negative terms:

- IPO
- album
- GTA
- election
- sports
- company
- stock
- yearly
- monthly
- non-BTC crypto unless clearly BTC-related

Candidate threshold should be logged, not hidden.

### Stage 3 — Manual seed support

If automated search still fails, V4 should support a manual seed from a Polymarket URL, slug, or event title.

Manual seed must still be read-only.

Manual seed must not contain wallet, account, order, or private information.

### Stage 4 — Token ID extraction

Only after an unambiguous candidate is found:

- extract clobTokenIds or equivalent public token ID fields;
- validate token count;
- validate outcomes;
- map token ID to UP/DOWN or YES/NO if possible;
- do not guess token direction if outcomes are ambiguous.

### Stage 5 — CLOB read probe

Only after valid token IDs exist:

- call public CLOB book endpoint;
- call public CLOB price endpoint for BUY;
- call public CLOB price endpoint for SELL;
- log response properties;
- log bid count;
- log ask count;
- log whether price fields are numeric;
- classify empty book as warning;
- classify non-2xx response as warning or issue depending on context.

### Stage 6 — Browser/runtime feasibility classification

V4 should classify, but not implement:

- whether direct browser access is plausible;
- whether CORS blocks browser implementation;
- whether a serverless proxy would be required;
- whether manual refresh is sufficient;
- whether staleness metadata is available or must be synthetic.

---

## 8. Implementation remains blocked until all criteria pass

Live data implementation remains blocked until all of the following are true:

1. A BTC 15m candidate is resolved unambiguously.

2. Market identity is documented.

3. Condition id or market id is documented if present.

4. Token IDs are documented.

5. Outcome to token mapping is documented or explicitly marked unresolved.

6. CLOB book is probed successfully or failure mode is classified.

7. CLOB price BUY is probed successfully or failure mode is classified.

8. CLOB price SELL is probed successfully or failure mode is classified.

9. Schema fields required by the future UI are documented.

10. Staleness policy is documented.

11. Manual refresh behavior is documented.

12. Browser or proxy strategy is documented.

13. Error states are documented.

14. Guardrails are preserved.

15. No authenticated trading capability is introduced.

---

## 9. Explicit non-authorization

This classification does not authorize:

- route edits;
- UI live snapshot;
- runtime Gamma integration;
- runtime CLOB integration;
- public browser fetch implementation;
- polling;
- WebSocket;
- serverless proxy;
- bots;
- orderbook trading logic;
- wallet connection;
- API key usage;
- authenticated trading API usage;
- order creation;
- order placement;
- order execution;
- financial advice;
- guaranteed profit claims;
- guaranteed prediction claims.

---

## 10. Next recommended phase

Recommended next phase:

BTC_15M_ARENA_LIVE_DATA_SOURCE_DISCOVERY_PROBE_READ_ONLY_V4_PRECISE_BTC_15M_RESOLVER

Mode:

Read-only.

Objective:

Run a more precise public discovery probe for BTC 15m markets, using improved query coverage, candidate scoring, token ID extraction, and CLOB read probes only after candidate validation.

Alternative:

If the user provides a current Polymarket BTC 15m URL or slug manually, open a read-only seeded resolver phase instead:

BTC_15M_ARENA_LIVE_DATA_SOURCE_SEEDED_DISCOVERY_PROBE_READ_ONLY_V1

Either way, live data remains blocked until candidate, token IDs, CLOB shape, and staleness behavior are documented.
---

## 11. V2 repair addendum — exact V3 probe metrics

This addendum repairs the V1 classification artifact by adding the exact literal candidate-count references required by the validator.

The V3 read-only probe reached market-like object collection and produced the following metrics:

- total_market_like_object_count=1944
- deduped_candidate_market_count=0
- unique_token_ids_for_probe=0

Classification of these metrics:

- total_market_like_object_count=1944 confirms that Gamma returned parseable market-like objects and the object collector no longer aborted.
- deduped_candidate_market_count=0 is BLOCKING_FOR_IMPLEMENTATION because no unambiguous BTC 15m market was resolved.
- unique_token_ids_for_probe=0 is BLOCKING_FOR_IMPLEMENTATION because no valid CLOB token IDs were available for BTC 15m.
- CLOB book/price probe status: SKIPPED_BECAUSE_NO_TOKEN_IDS.
- Live data implementation remains blocked.
- Runtime UI live data remains blocked.
- CLOB price, spread, depth, executable price, and exit-risk live snapshot implementation remain blocked.

This V2 repair does not authorize implementation.

No runtime fetch is authorized.
No UI live data is authorized.
No polling is authorized.
No WebSocket is authorized.
No serverless proxy is authorized.
No bot is authorized.
No wallet is authorized.
No private keys are authorized.
No API keys are authorized.
No authenticated trading API is authorized.
No order creation is authorized.
No order placement is authorized.
No order execution is authorized.
No trading automation is authorized.
No financial advice is authorized.
No guaranteed profit is authorized.
No guaranteed prediction is authorized.

Decision after V2 repair:

BTC_15M_ARENA_LIVE_DATA_SOURCE_PROBE_RESULT_CLASSIFICATION_DOCS_ONLY_V2_ADD_CANDIDATE_COUNT_REFERENCE can be considered locally complete only if the validator confirms:

- deduped_candidate_market_count=0
- total_market_like_object_count=1944
- unique_token_ids_for_probe=0
- CLOB book/price probe status: SKIPPED_BECAUSE_NO_TOKEN_IDS
- Live data implementation remains blocked

Next recommended phase after local V2 repair review:

BTC_15M_ARENA_LIVE_DATA_SOURCE_PROBE_RESULT_CLASSIFICATION_DOCS_ONLY_COMMIT_PUSH_V1

That future commit/push phase must stage only this docs-only classification artifact.
