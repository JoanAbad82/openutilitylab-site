# BTC 15m Arena — Repeatable CLOB `/book` Snapshot Schema V1

Fecha: 2026-06-11

Microfase:
BTC_15M_ARENA_LIVE_DATA_SOURCE_CLOB_BOOK_REPEATABLE_CAPTURE_SNAPSHOT_SCHEMA_DOCS_ONLY_V1

Modo:
Docs-only.

## 1. Objetivo

Definir el schema documental mínimo para persistir en una fase posterior una captura repetible de CLOB `/book` para mercados BTC Up/Down 15m.

Esta fase no captura datos nuevos, no llama a Gamma, no llama a CLOB, no crea snapshot JSON, no promueve fixtures, no genera replay, no inicia collector, no inicia bot y no toca wallet/API/order logic.

El propósito del schema es separar claramente:

1. metadata del target;
2. metadata de request;
3. raw book preservado;
4. top levels normalizados;
5. métricas derivadas;
6. checks de coherencia Up/Down;
7. summary de validación;
8. guardrails.

## 2. Evidencia base usada

La fase anterior revisó evidencia ya impresa de una captura acotada CLOB `/book` con:

- target real resuelto: `btc-updown-15m-1781179200`;
- event_id: `579831`;
- market_id: `2490133`;
- condition_id: `0x638e27cb9cd9f80f817206ccff4aaabbc502a1b43c9db0b68ba624ce91925cbb`;
- window_start_utc: `2026-06-11T12:00:00.0000000Z`;
- window_end_utc: `2026-06-11T12:15:00.0000000Z`;
- CLOB `/book` request budget: 2;
- CLOB `/book` requests executed: 2;
- outcomes cubiertos: Up y Down;
- snapshot_created: false;
- fixture_created: false;
- collector_started: false;
- bot_started: false;
- wallet_api_order_logic: false.

Book observado:

Outcome Up:
- token_id: `105482627641032528690722627023766353242107219670593706191677659404082709634813`;
- best_bid: `0.38`;
- best_bid_size: `74`;
- best_ask: `0.39`;
- best_ask_size: `16`;
- bids_count: 38;
- asks_count: 56;
- spread: `0.01`.

Outcome Down:
- token_id: `76169450891197787793400414382780292292557011910798089201047628561078571888133`;
- best_bid: `0.61`;
- best_bid_size: `16`;
- best_ask: `0.62`;
- best_ask_size: `94`;
- bids_count: 56;
- asks_count: 38;
- spread: `0.01`.

Coherencia Up/Down observada:
- up_best_bid + down_best_bid = `0.99`;
- up_best_ask + down_best_ask = `1.01`;
- up_best_bid + down_best_ask = `1.00`;
- up_best_ask + down_best_bid = `1.00`.

## 3. Ubicación recomendada para snapshots futuros

Directorio recomendado:

`project_sources/btc-15m-arena/snapshots/`

Nombre recomendado:

`btc_15m_clob_book_snapshot_<market_slug>_<YYYYMMDD>_<HHMMSS>_utc.json`

Ejemplo:

`btc_15m_clob_book_snapshot_btc-updown-15m-1781179200_20260611_120037_utc.json`

Reglas de naming:
- usar siempre `_utc`, no `_uc`;
- incluir market_slug;
- incluir fecha UTC;
- incluir hora UTC;
- extensión `.json`;
- no sobrescribir snapshots existentes;
- no promover automáticamente a fixtures.

## 4. Schema raíz recomendado

```json
{
  "schema_version": "BTC_15M_CLOB_BOOK_SNAPSHOT_V1",
  "phase": "BTC_15M_ARENA_LIVE_DATA_SOURCE_CLOB_BOOK_REPEATABLE_CAPTURE_SNAPSHOT_CAPTURE_V1",
  "created_at_utc": "ISO-8601 UTC timestamp",
  "source": "polymarket_clob_book_public",
  "auth": {
    "uses_wallet": false,
    "uses_private_keys": false,
    "uses_authenticated_trading_api": false,
    "uses_order_headers": false
  },
  "target_metadata": {},
  "request_metadata": {},
  "outcome_books": [],
  "derived_metrics": {},
  "validation_summary": {},
  "guardrails": {}
}
```

## 5. `target_metadata`

Debe contener:

```json
{
  "resolved_slug": "btc-updown-15m-1781179200",
  "resolved_event_id": "579831",
  "resolved_event_slug": "btc-updown-15m-1781179200",
  "resolved_event_title": "Bitcoin Up or Down - June 11, 8:00AM-8:15AM ET",
  "resolved_market_id": "2490133",
  "resolved_market_slug": "btc-updown-15m-1781179200",
  "resolved_condition_id": "0x...",
  "resolved_window_start_utc": "2026-06-11T12:00:00.0000000Z",
  "resolved_window_end_utc": "2026-06-11T12:15:00.0000000Z",
  "seconds_until_end_at_capture_precheck": 863
}
```

Validaciones:

* `resolved_slug` debe cumplir `^btc-updown-15m-[0-9]+$`;
* `resolved_market_slug` debe coincidir con `resolved_slug`;
* `resolved_condition_id` debe cumplir `^0x[0-9a-fA-F]{64}$`;
* `resolved_window_start_utc` debe ser anterior a `resolved_window_end_utc`;
* `seconds_until_end_at_capture_precheck` debe ser positivo y suficientemente alto para evitar capturas tardías accidentales.

## 6. `request_metadata`

Debe contener:

```json
{
  "gamma_public_requests_executed": 5,
  "clob_book_request_budget": 2,
  "clob_book_requests_executed": 2,
  "clob_book_endpoint": "/book",
  "http_auth_required": false,
  "capture_started_at_utc": "ISO-8601 UTC timestamp",
  "capture_finished_at_utc": "ISO-8601 UTC timestamp"
}
```

Reglas:

* `clob_book_request_budget` debe ser explícito;
* `clob_book_requests_executed` debe coincidir con el número de outcomes capturados;
* no registrar ni usar headers privados;
* no registrar tokens de autenticación;
* no incluir wallet;
* no incluir API keys;
* no incluir lógica de órdenes.

## 7. `outcome_books`

Debe ser un array con exactamente dos elementos para el mercado binario inicial:

```json
[
  {
    "outcome": "Up",
    "token_id": "string numeric token id",
    "http_status": 200,
    "fetch_ok": true,
    "parse_ok": true,
    "has_bids_array": true,
    "has_asks_array": true,
    "bids_count": 38,
    "asks_count": 56,
    "best_bid": {
      "price": "0.38",
      "size": "74"
    },
    "best_ask": {
      "price": "0.39",
      "size": "16"
    },
    "top_bids": [],
    "top_asks": [],
    "raw_book": {}
  },
  {
    "outcome": "Down",
    "token_id": "string numeric token id",
    "http_status": 200,
    "fetch_ok": true,
    "parse_ok": true,
    "has_bids_array": true,
    "has_asks_array": true,
    "bids_count": 56,
    "asks_count": 38,
    "best_bid": {
      "price": "0.61",
      "size": "16"
    },
    "best_ask": {
      "price": "0.62",
      "size": "94"
    },
    "top_bids": [],
    "top_asks": [],
    "raw_book": {}
  }
]
```

Reglas:

* outcomes esperados iniciales: `Up`, `Down`;
* `token_id` debe ser numérico y largo;
* los dos `token_id` deben ser únicos;
* `http_status` debe ser 200 para snapshot válido;
* `fetch_ok` y `parse_ok` deben ser true;
* `bids` y `asks` deben existir como arrays, aunque alguno pueda estar vacío en otros mercados;
* precios y tamaños deben conservarse como string decimal para evitar errores de precisión;
* `raw_book` debe preservar la respuesta cruda relevante, sin credenciales.

## 8. `top_bids` y `top_asks`

Formato recomendado:

```json
[
  {
    "level": 1,
    "price": "0.38",
    "size": "74"
  },
  {
    "level": 2,
    "price": "0.37",
    "size": "..."
  }
]
```

Reglas:

* `level` empieza en 1;
* los precios se preservan como string;
* los tamaños se preservan como string;
* `top_bids` debe estar ordenado de mejor bid a peor bid;
* `top_asks` debe estar ordenado de mejor ask a peor ask;
* se recomienda capturar al menos top 5 si existen;
* si hay menos de 5 niveles, registrar los disponibles y marcarlo en `validation_summary`.

## 9. `derived_metrics`

Debe contener:

```json
{
  "up_best_bid": "0.38",
  "up_best_ask": "0.39",
  "down_best_bid": "0.61",
  "down_best_ask": "0.62",
  "up_spread": "0.01",
  "down_spread": "0.01",
  "best_bid_sum_up_plus_down": "0.99",
  "best_ask_sum_up_plus_down": "1.01",
  "cross_sum_up_bid_plus_down_ask": "1.00",
  "cross_sum_up_ask_plus_down_bid": "1.00"
}
```

Reglas:

* calcular con decimal invariant culture;
* no usar float binario para decisiones de validación;
* spreads deben ser positivos o cero;
* cross sums cercanos a 1.00 indican coherencia básica de mercado binario, no edge;
* cualquier desviación debe tratarse como observación de market microstructure, no como señal automática.

## 10. `validation_summary`

Debe contener:

```json
{
  "schema_valid": true,
  "outcome_coverage_valid": true,
  "token_ids_unique": true,
  "http_status_valid": true,
  "book_arrays_present": true,
  "top_of_book_parseable": true,
  "spreads_parseable": true,
  "up_down_coherence_valid": true,
  "snapshot_eligible_for_review": true,
  "eligible_for_fixture_promotion": false,
  "warnings": [],
  "issues": []
}
```

Reglas:

* `schema_valid=true` no significa fixture válido;
* `snapshot_eligible_for_review=true` no significa apto para runtime;
* `eligible_for_fixture_promotion=false` por defecto;
* promotion a fixture requiere fase explícita posterior;
* cualquier warning debe quedar registrado, no oculto.

## 11. `guardrails`

Debe contener:

```json
{
  "read_only_capture": true,
  "wallet_used": false,
  "private_keys_used": false,
  "authenticated_trading_api_used": false,
  "orders_created": false,
  "orders_placed": false,
  "orders_executed": false,
  "trading_automation": false,
  "collector_started": false,
  "bot_started": false,
  "runtime_integration": false,
  "fixture_promotion": false,
  "financial_advice": false,
  "profitability_claims": false,
  "guaranteed_prediction_claims": false
}
```

Regla crítica:
Un snapshot de CLOB `/book` es evidencia de estructura y microestructura observable. No es una estrategia, no es edge, no es señal de trading y no autoriza ejecución real.

## 12. Criterios de snapshot válido

Un snapshot futuro V1 será válido si:

1. contiene `schema_version = BTC_15M_CLOB_BOOK_SNAPSHOT_V1`;
2. contiene target metadata completa;
3. contiene request metadata completa;
4. contiene exactamente dos outcome books para Up/Down;
5. ambos books tienen HTTP 200;
6. ambos books son parseables;
7. ambos tienen arrays `bids` y `asks`;
8. ambos tienen best bid/ask parseables si hay liquidez;
9. token IDs son únicos, numéricos y largos;
10. derived metrics se calculan con decimal invariant culture;
11. up/down coherence checks se registran;
12. guardrails están presentes y niegan wallet/orders/bot/runtime;
13. el archivo queda inicialmente como review artifact, no como fixture;
14. no se commitea sin fase explícita de review/retention/promotion.

## 13. Criterios de rechazo

Debe rechazarse o marcarse `snapshot_eligible_for_review=false` si:

* falta `schema_version`;
* falta target metadata;
* falta condition_id;
* condition_id no es 32-byte hex;
* falta outcome Up o Down;
* token IDs duplicados;
* token ID vacío o no numérico;
* HTTP status no es 200;
* book no parsea;
* faltan arrays bids/asks;
* precios no parsean como decimal;
* hay credenciales, wallet, private keys, headers privados o API auth;
* aparece order placement o execution logic;
* el archivo intenta declararse fixture sin fase de promotion.

## 14. Relación con fases futuras

Fase futura probable:
`BTC_15M_ARENA_LIVE_DATA_SOURCE_CLOB_BOOK_REPEATABLE_CAPTURE_SNAPSHOT_CAPTURE_PRECHECK_READ_ONLY_V1`

Después, solo si procede:
`BTC_15M_ARENA_LIVE_DATA_SOURCE_CLOB_BOOK_REPEATABLE_CAPTURE_SNAPSHOT_CAPTURE_V1`

No saltar directamente a:

* collector;
* bot;
* WebSocket;
* polling loop;
* runtime integration;
* strategy;
* signals;
* wallet/API/order logic;
* fixture promotion.

## 15. Estado de esta fase

Esta fase solo crea el documento de schema.

No ejecuta red.
No crea snapshot JSON.
No crea data file.
No crea fixture.
No genera replay.
No inicia collector.
No inicia bot.
No toca runtime.
No hace stage.
No hace commit.
No hace push.