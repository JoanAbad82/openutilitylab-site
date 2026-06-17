# BTC 15m Arena - Fresh V3 Evidence Retention Summary V1

Date: 2026-06-17

Phase:
BTC_15M_ARENA_LIVE_DATA_READ_ONLY_BOUNDED_DUAL_TOKEN_BOOK_PROBE_EXECUTION_V3_EVIDENCE_RETENTION_SUMMARY_DOCS_ONLY_V1

Classification:
TECHNICAL_ENDPOINT_EVIDENCE_ONLY

Retention decision:
PASS_RETAIN_SUMMARIZED_TECHNICAL_EVIDENCE_AS_DOCS_ONLY_NOT_SNAPSHOT_OR_FIXTURE

## Scope

This file is a summarized docs-only evidence record.

It is not a snapshot.
It is not a fixture.
It is not replay data.
It is not a collector output.
It is not a runtime loop output.
It is not a bot output.
It is not a trading signal.
It is not financial advice.
It is not a recommendation to trade.
It is not evidence of expected profit or guaranteed prediction.

No market request was executed by this docs-only summary phase.
No Gamma request was repeated by this docs-only summary phase.
No CLOB /book request was repeated by this docs-only summary phase.
No selected token id was reused by this docs-only summary phase.

## Reviewed phase chain

Execution phase:
BTC_15M_ARENA_LIVE_DATA_READ_ONLY_BOUNDED_DUAL_TOKEN_BOOK_PROBE_EXECUTION_V3_FRESH_MARKET_DUAL_TOKEN_PROBE_EXECUTION_V1

Execution decision:
PASS_FRESH_MARKET_RESOLVED_AND_BOTH_CLOB_BOOKS_CAPTURED_READ_ONLY

Post-execution review phase:
BTC_15M_ARENA_LIVE_DATA_READ_ONLY_BOUNDED_DUAL_TOKEN_BOOK_PROBE_EXECUTION_V3_FRESH_MARKET_DUAL_TOKEN_PROBE_POST_EXECUTION_REVIEW_V1

Post-execution review decision:
PASS_TECHNICAL_EVIDENCE_REVIEWED_NO_REPEAT_REQUESTS_NO_PERSISTENCE

Evidence retention decision phase:
BTC_15M_ARENA_LIVE_DATA_READ_ONLY_BOUNDED_DUAL_TOKEN_BOOK_PROBE_EXECUTION_V3_EVIDENCE_RETENTION_DECISION_READ_ONLY_V1

Evidence retention decision:
PASS_RETAIN_SUMMARIZED_TECHNICAL_EVIDENCE_AS_DOCS_ONLY_NOT_SNAPSHOT_OR_FIXTURE

## Selected market evidence

Selected slug:
btc-updown-15m-1781708400

Selected start unix:
1781708400

Selected start UTC:
2026-06-17T15:00:00Z

Selected end UTC:
2026-06-17T15:15:00Z

Selected market id:
2565941

Selected condition id:
0x50559ea8d7c63e1f692e330448ca814e22219e197ca2599f7e39acdcab230da3

Selected question:
Bitcoin Up or Down - June 17, 11:00AM-11:15AM ET

Previous blocked slug:
btc-updown-15m-1781703900

Previous 404 classification:
STALE_OR_UNAVAILABLE_REUSED_TOKEN_BOOK_NOT_OLD_URI_BUG

Interpretation:
The previous 404 remains classified as stale or unavailable reused token book evidence, not as the old URI construction bug.

## Token evidence

Up token id:
42082333147465454912145556211445121129676724086717569761807000971672053767352

Down token id:
45319980697747047378266542514078429282204322526025589645289739305457177753107

Token retention warning:
These token ids belong to a closed 15-minute market window.
They must not be reused for future requests.
They must not be treated as a stable fixture.
They must not be used as replay data.
They are retained only for technical traceability of the reviewed stdout evidence.

## Gamma evidence

Gamma status code:
200

Gamma market rows:
1

Gamma best bid:
0.5

Gamma best ask:
0.51

## CLOB /book evidence - Up

Up book status code:
200

Up bids count:
72

Up asks count:
27

Up best bid:
0.72

Up best ask:
0.73

Up spread:
0.01

Up mid:
0.725

## CLOB /book evidence - Down

Down book status code:
200

Down bids count:
27

Down asks count:
72

Down best bid:
0.27

Down best ask:
0.28

Down spread:
0.01

Down mid:
0.275

## Dual-book coherence

Up bid plus Down ask:
1.00

Up ask plus Down bid:
1.00

Up mid plus Down mid:
1.00

Coherence interpretation:
The reviewed fresh dual-token book evidence was internally coherent at best prices:
- Up bid plus Down ask equals 1.00.
- Up ask plus Down bid equals 1.00.
- Up mid plus Down mid equals 1.00.

This is a technical parseability and consistency observation only.
It is not a signal.
It is not advice.
It is not a profit claim.
It is not a prediction claim.

## Request counts

Reviewed execution Gamma requests:
1

Reviewed execution CLOB /book requests:
2

Reviewed execution market-data HTTP requests:
3

Reviewed execution public smoke requests:
0

Gamma cap:
7

CLOB /book cap:
2

Total market-data cap:
9

Timeout seconds per request:
10

This docs-only phase Gamma requests:
0

This docs-only phase CLOB /book requests:
0

This docs-only phase market-data HTTP requests:
0

This docs-only phase public smoke requests:
0

## Guardrails preserved

No wallet.
No private keys.
No authenticated trading API.
No real orders.
No order creation.
No order placement.
No order execution.
No trading automation.
No live trading.
No live data in this summary phase.
No collector.
No runtime loop.
No bot.
No trading signals.
No financial advice.
No profit claims.
No guaranteed prediction.
No snapshot created.
No fixture created.
No raw stdout artifact created.
No repeated requests.
No token reuse.

## Retention outcome

Retain in master:
true

Create raw stdout artifact:
false

Create snapshot:
false

Create fixture:
false

Create docs-only summary:
true

Repeat same market requests:
false

Reuse selected token ids:
false

Open collector, runtime or bot:
false

Open wallet, API or order logic:
false

Emit trading signal:
false

## Future handling

This evidence may be referenced as summarized technical documentation.

Future phases must not:
- repeat the selected market requests;
- reuse the selected token ids;
- treat this file as a fixture;
- treat this file as a snapshot;
- derive trading instructions from this evidence;
- present the observed prices as a signal;
- create a collector, runtime loop, bot, wallet integration, authenticated trading API or order logic from this evidence.

A future commit/push phase may version this docs-only summary after reviewing scope and diff.
