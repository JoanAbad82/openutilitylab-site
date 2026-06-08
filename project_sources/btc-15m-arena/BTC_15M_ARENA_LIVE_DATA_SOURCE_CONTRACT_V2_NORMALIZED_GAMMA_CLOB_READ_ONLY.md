# BTC 15m Arena — Live Data Source Contract V2

## Status

Docs-only source contract.

This document formalizes the normalized read-only Gamma + CLOB contract discovered after the V4 candidate/book normalization probe.

This document does not authorize runtime integration, polling, WebSocket usage, wallet access, authenticated API usage, order creation, order placement, order execution, trading automation, financial advice, guaranteed profit claims, or guaranteed prediction claims.

## Purpose

BTC 15m Arena may use this contract only as a read-only public market snapshot source for research, simulation, fixture capture, and execution-risk awareness.

The first permitted use is documentation and future static fixture capture. Runtime UI integration remains out of scope until separately authorized.

## Source boundary

Allowed public/no-auth sources:

1. Gamma event lookup by deterministic slug.
2. CLOB public order book lookup by token ID.

Explicitly forbidden in this contract:

- No wallet.
- No private keys.
- No API keys.
- No authenticated trading API.
- No order creation.
- No order placement.
- No order execution.
- No trading automation.
- No live trading.
- No WebSocket.
- No polling loop.
- No bot.
- No financial advice.
- No guaranteed profit.
- No guaranteed prediction.
- No runtime route integration.
- No UI live-data integration.

## Timestamp and slug contract

BTC 15m markets are addressed by deterministic Unix UTC timestamps aligned to 900 seconds.

Canonical formula:

```text
base_timestamp = floor(now_utc_unix / 900) * 900
candidate_timestamp = base_timestamp + (k * 900)
slug = btc-updown-15m-{candidate_timestamp}
```

Where:

- `k` may be negative, zero, or positive.
- every `candidate_timestamp` must satisfy `candidate_timestamp % 900 == 0`.
- the timestamp is a full Unix timestamp, not a visual suffix.
- future markets are reached by adding exactly 900 seconds.
- previous markets are reached by subtracting exactly 900 seconds.

If a known valid slug exists:

```text
next_timestamp = known_timestamp + 900
previous_timestamp = known_timestamp - 900
```

Do not construct future slugs by editing only the last digits of the timestamp. The decimal suffix may appear to rotate because of normal arithmetic carry. The contract is always full-timestamp arithmetic.

## Probe horizon versus product contract

Offsets used in probes are only a bounded query horizon.

Examples:

```text
short_probe_offsets = -900, 0, 900, 1800, 2700, 3600
extended_probe_offsets = -1800, -900, 0, 900, 1800, 2700, 3600, 4500, 5400, 6300, 7200, 8100, 9000, 9900, 10800
```

These lists must not be treated as the real series limit.

For robust discovery, generate buckets programmatically:

```text
for k in desired_bucket_range:
  candidate_timestamp = base_timestamp + (k * 900)
```

Every generated candidate must still be validated against Gamma response content.

## Gamma event lookup

Endpoint shape:

```text
GET https://gamma-api.polymarket.com/events?slug=btc-updown-15m-{candidate_timestamp}
```

Expected event-level filters:

- `returned_slug == requested_slug`
- BTC/Bitcoin identity in title/question/series context
- 15m or 15-minute identity in title/series context
- `seriesSlug == btc-up-or-down-15m` when available
- `markets_count >= 1`

Expected event fields to preserve:

- `slug`
- `title`
- `event_id`
- `seriesSlug`
- `start_time`
- `end_time`
- `active`
- `closed`
- `markets`

## Market candidate selection

A candidate market is acceptable only when all these checks pass:

1. Event slug matches requested deterministic slug.
2. Event/market identifies BTC or Bitcoin.
3. Event/series identifies 15m.
4. Market contains binary outcomes Up and Down.
5. Market has exactly two CLOB token IDs.
6. Candidate is preferably `active=True`.
7. Candidate must be `closed=False` for book normalization.

Closed candidates may be recorded for historical/contextual evidence, but they must not be selected for active book normalization.

## Outcome to token mapping

Gamma market outcomes and CLOB token IDs are normalized by positional alignment.

Observed normalized shape:

```text
outcomes = ["Up", "Down"]
clobTokenIds = [token_for_up, token_for_down]
```

Contract:

```text
Up -> clobTokenIds[index_of("Up")]
Down -> clobTokenIds[index_of("Down")]
```

Required validation:

- exactly two outcomes
- exactly two CLOB token IDs
- one outcome equal to Up
- one outcome equal to Down
- token IDs match numeric long-token shape
- reject ambiguous or non-binary mappings

Do not infer Up/Down mapping from prices alone. Use outcomes first, token order second.

## CLOB book lookup

Primary public endpoint:

```text
GET https://clob.polymarket.com/book?token_id={clobTokenId}
```

Confirmed contract:

- Gamma `market.clobTokenIds` map to CLOB `asset_id`.
- `/book?token_id={clobTokenId}` returns public order book data for open candidates.
- The response contains `market`, `asset_id`, `timestamp`, `hash`, `bids`, and `asks` when book data is available.

Do not use `/books?token_id=...` as the primary endpoint. It was observed returning 400 Bad Request in prior diagnostics.

Do not treat `/health` 404 as evidence that `/book?token_id=...` is unavailable.

## Normalized snapshot fields

A normalized read-only row should preserve:

```text
slug
timestamp
event_id
market_id
condition_id
start_time
end_time
active
closed
side
token_id
book_market
book_asset_id
book_timestamp
book_hash
best_bid
best_bid_size
best_ask
best_ask_size
spread
bids_count
asks_count
snapshot_collected_at_utc
source
```

Side-specific normalized output:

```text
up_token_id
down_token_id
up_best_bid
up_best_ask
up_spread
down_best_bid
down_best_ask
down_spread
```

Derived fields:

```text
spread = best_ask - best_bid
midpoint = (best_bid + best_ask) / 2, only if both sides exist
missing_bid = bids_count == 0
missing_ask = asks_count == 0
thin_book_warning = top-of-book size below configured research threshold
wide_spread_warning = spread above configured research threshold
```

Thresholds are research labels only. They are not trading signals.

## Confirmed V4 normalized evidence

V4 confirmed at least three normalized open candidates with both Up and Down books available.

Example normalized rows from V4:

```text
slug=btc-updown-15m-1780949700
condition_id=0x71822a34d5dcb6f58fcbf1cc791ffbad7f956217edbe9eb4637309ad1e1ed8ad
up_token_id=106202852566729727555670808925220985573023250663085412098311606010904527523158
down_token_id=113627486502808196929892947612682778334111524424593410540854090198508127036883
up_best_bid=0.62
up_best_ask=0.63
down_best_bid=0.37
down_best_ask=0.38
```

```text
slug=btc-updown-15m-1780950600
condition_id=0x16f1fa442ef7edb706ac0db70558d4a78481150bb56df12f659cb92e568825ab
up_token_id=42023366258067020807555046453665004128197172453651402541026089717213077213703
down_token_id=53097532352193106645895305176498363554540842722331570001473107137935572086135
up_best_bid=0.51
up_best_ask=0.52
down_best_bid=0.48
down_best_ask=0.49
```

```text
slug=btc-updown-15m-1780951500
condition_id=0x1c8db22454248d6cb53633af47c545f80d1020cc0ee7529cc9363251c689b758
up_token_id=13974953266153825393698281086569350461503338902131576778680773387696814349475
down_token_id=76221592460107078339171554052443909554789885728014128610337215384101095484744
up_best_bid=0.50
up_best_ask=0.51
down_best_bid=0.49
down_best_ask=0.50
```

## Selection order

When multiple candidates are available, prefer:

1. `closed=False`
2. `active=True`
3. event slug exactly matches requested slug
4. outcomes exactly Up and Down
5. token count exactly two
6. both side books return status 200
7. both side books contain bids and asks
8. lower ambiguity in title/series identity
9. most relevant current/future bucket for the selected task

## Failure modes

Return a classified result instead of guessing.

Allowed failure labels:

```text
MARKET_NOT_FOUND
MARKET_CLOSED_OR_RESOLVED
AMBIGUOUS_MARKET_MATCH
OUTCOME_MAPPING_FAILED
TOKEN_IDS_MISSING
TOKEN_COUNT_INVALID
BOOK_NOT_FOUND
BOOK_MISSING_BIDS
BOOK_MISSING_ASKS
BOOK_EMPTY_OR_THIN
WIDE_SPREAD_WARNING
STALE_SNAPSHOT_WARNING
SOURCE_SHAPE_CHANGED
NETWORK_TIMEOUT
PUBLIC_ENDPOINT_ERROR
CONTRACT_VALIDATION_FAILED
```

Forbidden labels:

```text
BUY_SIGNAL
SELL_SIGNAL
PLACE_ORDER
EXECUTE_ORDER
AUTO_HEDGE
AUTO_ARBITRAGE
GUARANTEED_PROFIT
RISK_FREE
SURE_WIN
```

## Staleness rules

Book timestamps are source timestamps and may be compared against collection time only for read-only freshness labels.

Candidate labels:

```text
fresh: snapshot age <= 15 seconds
caution: snapshot age > 15 seconds and <= 60 seconds
stale: snapshot age > 60 seconds
unknown: source timestamp unavailable or unparsable
```

These labels are not trading advice and must not trigger automated actions.

## Manual refresh only

Allowed in a future separately authorized read-only UI slice:

- user clicks refresh
- one request flow resolves market identity and book snapshot
- result is rendered as read-only public market context

Not allowed:

- setInterval polling
- setTimeout polling loop
- WebSocket stream
- background bot
- automated hedge
- automated order tracking
- account state
- wallet state
- private authenticated state
- order state
- live trading mode

## Fixture capture implications

This contract allows a future static fixture capture phase, but does not implement it.

A future fixture capture may store normalized rows only if separately authorized and if it remains docs/static/research-only.

Fixture rows should include:

```text
captured_at_utc
slug
timestamp
condition_id
up_token_id
down_token_id
up_best_bid
up_best_ask
up_spread
down_best_bid
down_best_ask
down_spread
bids_count
asks_count
source_urls
```

No private state, account state, wallet state, order state, or trading execution state may be stored.

## Runtime implementation status

This document does not authorize runtime implementation.

Still not authorized:

- route live data UI
- automatic refresh
- polling
- WebSocket
- serverless proxy
- authenticated API
- wallet/API/order logic
- bot
- trade execution
- trading recommendation
- financial advice
- guaranteed outcome language

## Required copy for future read-only snapshot output

```text
Read-only public market snapshot. No wallet. No orders. No live trading. No financial advice. Prices and books can move before any manual action.
```

## Acceptance criteria for this contract

This contract is acceptable only if:

- it remains docs-only;
- it creates or changes only this markdown artifact;
- it records timestamp arithmetic with 900-second alignment;
- it records deterministic slug generation;
- it records Gamma event lookup;
- it records Up/Down outcome mapping;
- it records CLOB `/book?token_id=...`;
- it records normalized fields;
- it records failure modes;
- it preserves all guardrails;
- it does not introduce runtime code;
- it does not authorize implementation.

## Next recommended phase

After this docs-only contract is reviewed and committed in a separate controlled phase, the next likely phase is:

```text
BTC_15M_ARENA_STATIC_FIXTURE_CAPTURE_PRECHECK_READ_ONLY_V1
```

Alternative, if the product direction is to avoid persisted fixtures first:

```text
BTC_15M_ARENA_LIVE_DATA_SOURCE_CONTRACT_V2_COMMIT_PUSH_DOCS_ONLY_V1
```

The immediate next phase after local creation should be commit/push control of this docs-only artifact, not runtime implementation.