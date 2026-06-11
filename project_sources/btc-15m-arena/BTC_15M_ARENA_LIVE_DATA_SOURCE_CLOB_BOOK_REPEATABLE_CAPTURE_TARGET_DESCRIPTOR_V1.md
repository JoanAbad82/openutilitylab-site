# BTC 15m Arena — CLOB Book Repeatable Capture Target Descriptor V1

## Phase

BTC_15M_ARENA_LIVE_DATA_SOURCE_CLOB_BOOK_REPEATABLE_CAPTURE_TARGET_DESCRIPTOR_DOCS_ONLY_V1

## Mode

Docs-only target descriptor.

This file is a documentary descriptor for the target resolved during temporal disambiguation. It is not a CLOB /book capture, not a snapshot, not a fixture, not a replay, not a collector configuration, not a bot configuration, and not a live-data runtime integration.

## Resolved Gamma target

- resolved_slug: btc-updown-15m-1781176500
- resolved_event_id: 579686
- resolved_event_slug: btc-updown-15m-1781176500
- resolved_event_title: Bitcoin Up or Down - June 11, 7:15AM-7:30AM ET
- resolved_window_start_utc: 2026-06-11T11:15:00.0000000Z
- resolved_window_end_utc: 2026-06-11T11:30:00.0000000Z
- classification_at_scan: TEMPORAL_SINGLE_CURRENT_TARGET_CANDIDATE

## Scan anchor

- scan_now_utc: 2026-06-11T11:23:14.6674734Z
- scan_now_unix: 1781176994
- aligned_floor_unix: 1781176500
- aligned_floor_utc: 2026-06-11T11:15:00.0000000Z
- aligned_next_utc: 2026-06-11T11:30:00.0000000Z
- resolved_seconds_since_start_at_scan: 495
- resolved_seconds_until_end_at_scan: 405

## Descriptor creation anchor

- descriptor_created_utc: 2026-06-11T11:27:35.6976898Z
- descriptor_created_unix: 1781177255
- seconds_until_end_at_descriptor_creation: 144
- descriptor_staleness_class: window_not_ended_at_descriptor_creation_but_capture_still_not_authorized
- descriptor_validity_mode: HISTORICAL_SCAN_EVIDENCE

## Safety interpretation

This descriptor records that the temporal disambiguation phase resolved exactly one Gamma target at the time of the scan.

It does not prove that the market is still live at descriptor creation time.

It does not authorize CLOB /book.

It does not authorize a snapshot.

It does not authorize fixture promotion.

It does not authorize replay generation.

It does not authorize runtime integration.

It does not authorize a live-data loop.

It does not authorize a collector.

It does not authorize a bot.

It does not authorize wallet, private-key, authenticated API, order, execution, or trading automation logic.

## Staleness rule

BTC 15-minute market targets expire quickly.

Any future CLOB /book phase must either:

1. revalidate a fresh current target before capture; or
2. explicitly declare that it is using this descriptor only as historical scan evidence and refuse live capture if the window has expired.

A future phase must not assume that this descriptor remains a valid live target merely because the file exists.

## Authorized follow-up

Allowed next step after this docs-only descriptor:

- a read-only CLOB book capture precheck or target revalidation phase.

Not allowed next step:

- direct CLOB /book capture without precheck;
- direct snapshot write;
- direct fixture promotion;
- direct replay generation;
- live collector;
- bot;
- wallet/API/order integration.

## Scope confirmation

This descriptor was created without:

- Gamma requests;
- CLOB metadata requests;
- CLOB /book requests;
- snapshot writes;
- data-file writes;
- fixture writes;
- replay writes;
- runtime changes;
- route changes;
- calculator changes;
- home changes;
- sitemap changes;
- stage;
- commit;
- push.

## Next recommended phase

BTC_15M_ARENA_LIVE_DATA_SOURCE_CLOB_BOOK_REPEATABLE_CAPTURE_TARGET_DESCRIPTOR_DOCS_ONLY_COMMIT_PUSH_OR_CAPTURE_PRECHECK_DECISION_V1

Recommended interpretation:

Because the descriptor refers to a 15-minute target, prefer a read-only capture precheck / temporal revalidation before any CLOB /book request.