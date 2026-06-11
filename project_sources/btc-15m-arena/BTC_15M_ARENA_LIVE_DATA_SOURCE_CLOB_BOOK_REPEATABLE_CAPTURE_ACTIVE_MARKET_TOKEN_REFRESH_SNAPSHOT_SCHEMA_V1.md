# BTC 15m Arena - Active Market Token Refresh CLOB Book Snapshot Schema V1

Fecha: 2026-06-11

Microfase:
BTC_15M_ARENA_LIVE_DATA_SOURCE_CLOB_BOOK_REPEATABLE_CAPTURE_ACTIVE_MARKET_TOKEN_REFRESH_SNAPSHOT_SCHEMA_DOCS_ONLY_V1_REPAIR_NO_HERESTRING

Modo: Docs-only.

## Proposito
Este documento define el contrato minimo para una futura captura repetible de snapshot read-only del orderbook CLOB de Polymarket para mercados BTC Up/Down 15m.
Esta fase no captura snapshots reales, no crea fixtures, no ejecuta replay, no inicia collector, no inicia bot, no introduce runtime live data, no usa wallet y no coloca ordenes.

## Estado previo validado
- Gamma resuelve mercados BTC 15m current/next por slug btc-updown-15m-{epoch}.
- Cada mercado resuelto puede contener dos CLOB token ids largos.
- Los candidatos validos deben estar active=True, closed=False, archived=False, acceptingOrders=True y enableOrderBook=True.
- CLOB /book puede devolver HTTP 200 para un fresh CLOB token id.
- El JSON de /book puede parsear correctamente.
- asset_id debe coincidir con el selected_token_id.
- bids y asks deben existir como arrays.
- El book puede tener profundidad no vacia.
- Los mejores niveles deben calcularse con ordenacion numerica.
- No se exige equivalencia estricta entre Gamma bestBid/bestAsk y CLOB selected-token book.

## Acciones prohibidas
- Sin wallet.
- Sin private keys.
- Sin authenticated trading API.
- Sin real orders.
- Sin order placement.
- Sin trading automation.
- Sin live trading.
- Sin collector continuo.
- Sin background loop.
- Sin bot.
- Sin scraping no autorizado.
- Sin predicciones.
- Sin financial advice.
- Sin profitability claims.

## snapshot_identity
- schema_version: btc_15m_arena_clob_book_snapshot_v1
- capture_mode: read_only_single_book_snapshot
- captured_at_utc: timestamp local de captura en UTC ISO-8601
- source_system: polymarket_gamma_plus_clob
- project: btc_15m_arena
- phase: fase autorizada
- request_budget.gamma_markets_by_slug: 2
- request_budget.clob_book: 1
- request_budget.markets_by_token: 0
- request_budget.orders: 0
- request_budget.wallet: 0

## window_context
- now_epoch
- current_epoch
- next_epoch
- window_seconds: 900
- targets current y next con label, epoch, utc y slug.
Regla: recalcular current/next en cada captura. Nunca reutilizar slugs viejos.

## gamma_discovery
Cada target debe registrar request_index, target_label, requested_slug, uri, status_code, json_parse_ok, market_rows_count y discoveries_added.
Cada discovery normalizado debe registrar slug, market_id, condition_id, question, active, closed, archived, accepting_orders, enable_order_book, outcomes, primary_token_id, secondary_token_id, gamma_best_bid, gamma_best_ask, gamma_last_trade_price, score y score_reasons.
Los token ids deben tratarse siempre como strings.
Do not use condition_id as CLOB /book token identifier.
Gamma bestBid/bestAsk son metadata de apoyo, no sustituto del CLOB token book.

## selected_candidate
- selection_rule: highest_score_first_eligible_candidate
- selected_slug
- selected_market_id
- selected_condition_id
- selected_question
- selected_token_role
- selected_token_id
- selected_token_outcome_inferred
- checks: has_two_token_ids, active, closed, archived, accepting_orders, enable_order_book, token_id_is_long_decimal

## clob_book_request
- method: GET
- uri: https://clob.polymarket.com/book?token_id=...
- status_code
- json_parse_ok
- request_error
- body_length
No se permiten headers de autenticacion, firmas, POST, wallet ni ordenes.

## clob_book_raw
- market
- asset_id
- timestamp
- hash
- bids raw
- asks raw
Preservar price y size raw como strings si vienen como strings.
asset_id debe coincidir con selected_token_id.

## clob_book_normalized
- bids_count
- asks_count
- valid_shape
- asset_id_matches_selected_token
- sorted_bids
- sorted_asks
- numeric_sorting_required: true
- raw_first_level_must_not_be_assumed_best: true
sorting_contract: bids price_descending y asks price_ascending.
Usar cultura invariante para parseo decimal.

## derived_metrics
- best_bid_price
- best_bid_size
- best_ask_price
- best_ask_size
- spread
- mid
- top_bid_notional
- top_ask_notional
- depth_bid_top5_size
- depth_ask_top5_size
- non_empty_book_depth
- computed_best_levels
spread = best_ask_price - best_bid_price.
spread no puede ser negativo.

## gamma_vs_clob_review
- gamma_best_bid
- gamma_best_ask
- clob_best_bid
- clob_best_ask
- best_bid_delta_abs
- best_ask_delta_abs
- material_delta_threshold: 0.05
- material_delta
- equivalence_required_for_valid_snapshot: false
Una diferencia Gamma-vs-CLOB no invalida por si sola el snapshot.

## snapshot_classification
allowed_values:
- valid_non_empty_book
- valid_empty_book
- invalid_http_status
- invalid_json
- invalid_missing_bids_or_asks
- invalid_asset_id_mismatch
- invalid_negative_spread
- invalid_candidate_selection
- invalid_scope_violation

## scope_audit
- gamma_requests_executed
- clob_book_requests_executed
- markets_by_token_requests_executed: 0
- snapshot_file_created
- fixture_created: false
- replay_executed: false
- collector_started: false
- bot_started: false
- runtime_live_data_enabled: false
- wallet_used: false
- orders_placed: false
- stage_commit_push_executed

## Ruta recomendada futura
project_sources/btc-15m-arena/snapshots/
Nombre recomendado: btc_15m_arena_clob_book_snapshot_<captured_at_utc_compact>_<slug>_<token_role>.json
No crear directorio ni snapshot en esta fase docs-only.

## Prevencion de fallos
- No reutilizar slugs viejos.
- No usar condition_id como token_id.
- No confiar en el primer elemento raw del book.
- Ordenar bids descendente y asks ascendente por precio numerico.
- No exigir equivalencia Gamma-vs-CLOB.
- No parsear decimales con cultura local.
- No mezclar snapshot con fixture.
- No mezclar snapshot con bot.
- No usar here-strings largos en bloques pegados en consola.

## Proxima fase recomendada
BTC_15M_ARENA_LIVE_DATA_SOURCE_CLOB_BOOK_REPEATABLE_CAPTURE_ACTIVE_MARKET_TOKEN_REFRESH_BOUNDED_SINGLE_SNAPSHOT_CAPTURE_PRECHECK_READ_ONLY_V1