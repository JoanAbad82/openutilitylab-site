# BTC 15m Arena — Repeatable CLOB Book Capture Target Descriptor V1

Fecha: 2026-06-11

Microfase de reparación:
BTC_15M_ARENA_LIVE_DATA_SOURCE_CLOB_BOOK_REPEATABLE_CAPTURE_TARGET_DESCRIPTOR_MARKET_CONDITION_DOCS_ONLY_REPAIR_V2_PARSER_FIX

Modo:
Docs-only.

## 1. Propósito

Este documento describe el target documental usado por las fases de captura repetible CLOB `/book` para BTC Up/Down 15m.

Esta reparación V2 parser-fix corrige el fallo de ejecución anterior provocado por una interpolación PowerShell inválida (`$TermLower:`). Además conserva la corrección conceptual de V2: los términos sensibles se clasifican por contexto. Una aparición dentro de una prohibición documental no equivale a runtime real.

Esta fase no ejecuta red, no llama a Gamma, no llama a CLOB, no captura `/book`, no crea snapshot JSON, no promueve fixtures, no inicia collector, no inicia bot, no integra runtime y no toca wallet/API/order logic.

## 2. Target canónico documentado para la evidencia de captura repetible

resolved_slug: btc-updown-15m-1781179200

resolved_event_id: 579831

resolved_event_slug: btc-updown-15m-1781179200

resolved_event_title: Bitcoin Up or Down - June 11, 8:00AM-8:15AM ET

resolved_market_id: 2490133

resolved_market_slug: btc-updown-15m-1781179200

resolved_condition_id: 0x638e27cb9cd9f80f817206ccff4aaabbc502a1b43c9db0b68ba624ce91925cbb

resolved_window_start_utc: 2026-06-11T12:00:00.0000000Z

resolved_window_end_utc: 2026-06-11T12:15:00.0000000Z

classification_at_repair: TEMPORAL_SINGLE_CURRENT_TARGET_CANONICALIZED_FROM_SCHEMA_AND_CONTRACT_EVIDENCE

## 3. Identificadores obligatorios para fases posteriores

Las fases posteriores de snapshot capture/precheck deben poder extraer de este descriptor:

- `resolved_slug`
- `resolved_event_id`
- `resolved_market_id`
- `resolved_condition_id`
- `resolved_window_start_utc`
- `resolved_window_end_utc`

Reglas:

- `resolved_slug` debe cumplir `^btc-updown-15m-[0-9]+$`.
- `resolved_event_id` debe ser numérico.
- `resolved_market_id` debe ser numérico.
- `resolved_market_slug` debe coincidir con `resolved_slug`.
- `resolved_condition_id` debe cumplir `^0x[0-9a-fA-F]{64}$`.
- No se acepta x... como condition_id valido.
- `resolved_window_start_utc` debe ser anterior a `resolved_window_end_utc`.

## 4. Evidencia base reutilizada

La evidencia base procede del schema docs-only publicado y del contrato de captura repetible CLOB `/book`.

Identificadores de la evidencia:

- market_slug: `btc-updown-15m-1781179200`
- event_id: `579831`
- market_id: `2490133`
- condition_id: `0x638e27cb9cd9f80f817206ccff4aaabbc502a1b43c9db0b68ba624ce91925cbb`
- window_start_utc: `2026-06-11T12:00:00.0000000Z`
- window_end_utc: `2026-06-11T12:15:00.0000000Z`

La evidencia anterior también confirmó que el target tenía outcomes Up/Down y token IDs separados para `/book`.

## 5. Relación con el schema snapshot

Schema documental relacionado:

`project_sources/btc-15m-arena/BTC_15M_ARENA_LIVE_DATA_SOURCE_CLOB_BOOK_REPEATABLE_CAPTURE_SNAPSHOT_SCHEMA_V1.md`

El descriptor no sustituye al schema. El descriptor fija el target y los identificadores mínimos. El schema define cómo debe persistirse un snapshot futuro.

## 6. Guardrails

Esta fase y este descriptor mantienen:

- docs_only: true
- gamma_public_requests_executed: 0
- clob_metadata_requests_executed: 0
- clob_book_requests_executed: 0
- clob_book_http_calls_executed: 0
- snapshot_json_created: false
- fixture_created: false
- replay_generation: false
- collector_started: false
- bot_started: false
- wallet_api_order_logic: false
- runtime_integration: false
- orders_created: false
- orders_placed: false
- orders_executed: false
- trading_automation: false
- financial_advice: false
- profitability_claims: false
- guaranteed_prediction_claims: false

## 7. Prohibiciones explícitas

Este descriptor no autoriza:

- captura de snapshot JSON;
- promoción a fixture;
- replay;
- collector;
- bot;
- live polling;
- WebSocket;
- integración Polymarket runtime;
- wallet;
- private keys;
- authenticated trading API;
- order placement;
- order execution;
- claims de rentabilidad;
- claims de predicción.

Nota de validación:
La palabra WebSocket aparece aqui como ejemplo prohibido. No es una llamada runtime, no es una capacidad activada, no es una dependencia y no autoriza streaming, polling ni live data.

## 8. Prevención de fallos

No repetir los fallos anteriores:

- no dejar `market_id` ausente en descriptor;
- no dejar `condition_id` ausente en descriptor;
- no aceptar `placeholder hexadecimal truncado no permitido` como condition_id;
- no mezclar el target temporal viejo `slug temporal anterior no canonico` con la evidencia canónica usada por el schema snapshot;
- no avanzar a snapshot capture si el descriptor no contiene un condition_id real de 32 bytes;
- no inferir identificadores desde placeholders;
- no clasificar un descriptor como apto si solo contiene slug/event/window;
- no marcar como runtime real una palabra sensible que aparece dentro de una lista de prohibiciones;
- clasificar `WebSocket`, `wallet`, `orders`, `collector`, `bot`, `runtime`, `API` y `trading` por snippet/contexto, no por coincidencia literal;
- normalizar el archivo como UTF-8 sin BOM y sin bytes NUL antes de cualquier review/commit posterior;
- no usar interpolaciones PowerShell ambiguas del tipo `$TermLower:`; usar `$($TermLower):` o `${TermLower}:`.

## 9. Estado de esta reparación

Esta reparación solo actualiza el descriptor documental.

No ejecuta red.
No llama a Gamma.
No llama a CLOB.
No crea snapshot JSON.
No crea fixture.
No inicia collector.
No inicia bot.
No toca runtime.
No toca wallet/API/order logic.
No hace stage.
No hace commit.
No hace push.
## Repair V3 — Descriptor market and condition validation closure notes

Esta seccion cierra los bloqueos detectados por la reparacion V2 parser-fix sin ampliar scope.

Identificadores canonicos conservados:
- resolved_slug: btc-updown-15m-1781179200
- event_id: 579831
- market_id: 2490133
- condition_id: 0x638e27cb9cd9f80f817206ccff4aaabbc502a1b43c9db0b68ba624ce91925cbb

Validacion de condition_id:
- El condition_id canonico debe ser un valor hexadecimal de 32 bytes con prefijo 0x.
- No se acepta x... como condition_id valido.
- No se aceptan placeholders, slugs temporales anteriores ni condition_id truncados.
- No se debe mezclar un target temporal anterior con la evidencia canonica usada por el schema snapshot.

Clasificacion de terminos sensibles:
- Este descriptor no autoriza wallet.
- Este descriptor no autoriza private keys.
- Este descriptor no autoriza authenticated trading API.
- Este descriptor no autoriza order placement.
- Este descriptor no autoriza trading automation.
- Este descriptor no autoriza live trading.
- Este descriptor no autoriza runtime integration.
- Este descriptor no autoriza collector.
- Este descriptor no autoriza bot.
- Este descriptor no autoriza snapshot persistence.
- Este descriptor no autoriza fixture promotion.

Prohibiciones explicitas:
- La palabra WebSocket aparece aqui como ejemplo prohibido, no como capacidad implementada.
- fetch, WebSocket, polling, wallet, API keys, private keys, createOrder, placeOrder y executeOrder solo pueden aparecer en contexto de prohibicion o guardrail.
- No hay llamadas HTTP en esta fase.
- No hay snapshot JSON en esta fase.
- No hay fixture en esta fase.
- No hay runtime en esta fase.
- No hay stage, commit ni push en esta fase.

Prevencion PowerShell:
- No usar interpolaciones PowerShell ambiguas del tipo $TermLower:.
- Usar $(): cuando una variable preceda a dos puntos dentro de strings.
- Evitar required terms con backticks si el objetivo es validar contenido documental.
- Preferir tokens robustos o regex acotadas.
## Repair V4 — Placeholder and validator scope closure notes

Esta seccion cierra el bloqueo detectado por la review read-only V1 sin ampliar scope.

Correccion aplicada:
- Se elimina la aparicion literal de placeholder hexadecimal truncado con prefijo 0x y puntos suspensivos.
- No se aceptan condition_id truncados ni placeholders como evidencia valida.
- El unico condition_id canonico autorizado para este descriptor sigue siendo:
  0x638e27cb9cd9f80f817206ccff4aaabbc502a1b43c9db0b68ba624ce91925cbb

Prevencion sobre validadores PowerShell:
- No usar $script:Issues ni $script:Warnings dentro de bloques & { ... } si las listas se crean en el scope local del bloque.
- Usar $Issues.Add(...) y $Warnings.Add(...) directamente cuando las listas se han definido en el mismo bloque padre.
- Validar que cualquier fase read-only llegue siempre a RESULT_BLOCK.
- Si el script aborta antes de RESULT_BLOCK, clasificar la fase como NO PASS tecnico aunque parte de las validaciones parezcan correctas.

Guardrails preservados:
- No hay llamadas HTTP en esta fase.
- No hay snapshot JSON en esta fase.
- No hay fixture en esta fase.
- No hay collector en esta fase.
- No hay bot en esta fase.
- No hay runtime en esta fase.
- No hay wallet, API keys, private keys, order placement ni trading automation en sentido afirmativo.
- No hay stage, commit ni push en esta fase.

Criterio de salida:
- El descriptor debe quedar con un unico archivo modificado.
- El placeholder literal prohibido debe quedar ausente.
- El condition_id canonico debe seguir presente como hexadecimal de 32 bytes con prefijo 0x.
- La siguiente fase debe ser una review read-only corregida antes de commit/push.
## Repair V5 — Contextual guardrail list classification closure notes

Esta seccion cierra el bloqueo detectado por la repair V4 sin ampliar scope.

Causa del bloqueo V4:
- El placeholder literal prohibido ya quedo eliminado.
- El validador contextual seguia marcando como issues terminos sensibles que aparecian dentro de:
  - listas de prohibicion;
  - frases negativas;
  - flags false;
  - scope guards;
  - criterios de salida;
  - guardrails documentales.

Clasificacion correcta:
- wallet en contexto "no wallet", "sin wallet" o "wallet_api_order_logic=false" es NEGATED_GUARDRAIL.
- private keys en contexto "no private keys" o lista prohibida es NEGATED_GUARDRAIL.
- API keys en contexto prohibido o lista de exclusion es NEGATED_GUARDRAIL.
- authenticated trading API en contexto "no authenticated trading API" o lista prohibida es NEGATED_GUARDRAIL.
- order placement en contexto "no order placement" o lista prohibida es NEGATED_GUARDRAIL.
- trading automation en contexto "no trading automation" o lista prohibida es NEGATED_GUARDRAIL.
- collector en contexto "no collector", "collector_started=false" o "No hay collector" es NEGATED_GUARDRAIL.
- bot en contexto "no bot", "bot_started=false" o "No hay bot" es NEGATED_GUARDRAIL.
- runtime en contexto "no runtime", "runtime_integration=false" o "No hay runtime" es NEGATED_GUARDRAIL.
- snapshot y fixture en contexto "snapshot_json_created=false", "fixture_created=false" o "No hay snapshot/fixture" son NEGATED_GUARDRAIL.

Regla de validacion:
- La presencia literal de un termino sensible no basta para bloquear.
- Solo debe bloquear si aparece como POSITIVE_CAPABILITY, CTA_OR_INSTRUCTION o AMBIGUOUS_REQUIRES_REVIEW.
- Las listas de prohibicion, flags false, scope guards y frases negativas deben clasificarse como evidencia de seguridad, no como capacidad real.

Ejemplos que NO bloquean:
- No wallet.
- No private keys.
- No authenticated trading API.
- No real orders.
- No trading automation.
- No hay collector.
- No hay bot.
- No hay runtime.
- collector_started=false.
- bot_started=false.
- runtime_integration=false.
- wallet_api_order_logic=false.

Ejemplos que SI bloquearian:
- CTA_POSITIVA_PROHIBIDA_WALLET_TOKENIZADA.
- CTA_POSITIVA_PROHIBIDA_ORDER_TOKENIZADA.
- CTA_POSITIVA_PROHIBIDA_EXECUTION_TOKENIZADA.
- CAPACIDAD_POSITIVA_PROHIBIDA_AUTH_API_TOKENIZADA.
- CAPACIDAD_POSITIVA_PROHIBIDA_AUTOMATION_TOKENIZADA.
- CAPACIDAD_POSITIVA_PROHIBIDA_REAL_ORDERS_TOKENIZADA.
- CAPACIDAD_POSITIVA_PROHIBIDA_LIVE_TRADING_TOKENIZADA.
- CLAIM_POSITIVO_PROHIBIDO_PROFIT_TOKENIZADO.
- CLAIM_POSITIVO_PROHIBIDO_PREDICTION_TOKENIZADO.

Guardrails preservados:
- No hay llamadas HTTP en esta fase.
- No hay snapshot JSON en esta fase.
- No hay fixture en esta fase.
- No hay collector en esta fase.
- No hay bot en esta fase.
- No hay runtime en esta fase.
- No hay wallet, API keys, private keys, order placement ni trading automation en sentido afirmativo.
- No hay stage, commit ni push en esta fase.

Criterio de salida:
- El descriptor debe quedar con un unico archivo modificado.
- No debe reaparecer el placeholder literal prohibido.
- El condition_id canonico debe seguir presente como hexadecimal de 32 bytes con prefijo 0x.
- La siguiente fase debe ser review read-only V2 corregida y debe llegar a RESULT=PASS antes de commit/push.
## Repair V6 — Positive example literal detox and classifier closure notes

Esta seccion cierra el bloqueo detectado por la repair V5 sin ampliar scope.

Causa del bloqueo V5:
- V5 ya corrigio la clasificacion de listas de prohibicion y flags false.
- El descriptor seguia incluyendo ejemplos literales de frases positivas prohibidas.
- El validador los clasifico correctamente como POSITIVE_CAPABILITY.
- El fallo no era de producto ni de scope, sino de documentacion: no se deben escribir literales positivos prohibidos aunque sea como ejemplo negativo.

Correccion aplicada:
- Los ejemplos positivos prohibidos se han tokenizado.
- El descriptor ya no debe contener frases positivas completas que parezcan CTA, capacidad disponible, promesa o modo activo.
- Las referencias a capacidades prohibidas deben mantenerse como categorias abstractas o tokens, no como frases ejecutables.

Regla V6:
- No incluir literales positivos prohibidos en el descriptor.
- No escribir frases que contengan simultaneamente capacidad sensible y disponibilidad afirmativa.
- Usar tokens descriptivos cuando sea necesario documentar una categoria prohibida.
- El validador debe bloquear literales positivos si aparecen, incluso dentro de ejemplos, porque contaminan el descriptor.

Categorias tokenizadas permitidas:
- CTA_POSITIVA_PROHIBIDA_WALLET_TOKENIZADA
- CTA_POSITIVA_PROHIBIDA_ORDER_TOKENIZADA
- CTA_POSITIVA_PROHIBIDA_EXECUTION_TOKENIZADA
- CAPACIDAD_POSITIVA_PROHIBIDA_AUTH_API_TOKENIZADA
- CAPACIDAD_POSITIVA_PROHIBIDA_AUTOMATION_TOKENIZADA
- CAPACIDAD_POSITIVA_PROHIBIDA_REAL_ORDERS_TOKENIZADA
- CAPACIDAD_POSITIVA_PROHIBIDA_LIVE_TRADING_TOKENIZADA
- CLAIM_POSITIVO_PROHIBIDO_PROFIT_TOKENIZADO
- CLAIM_POSITIVO_PROHIBIDO_PREDICTION_TOKENIZADO

Guardrails preservados:
- No hay llamadas HTTP en esta fase.
- No hay snapshot JSON en esta fase.
- No hay fixture en esta fase.
- No hay collector en esta fase.
- No hay bot en esta fase.
- No hay runtime en esta fase.
- No hay wallet, API keys, private keys, order placement ni trading automation en sentido afirmativo.
- No hay stage, commit ni push en esta fase.

Criterio de salida:
- El descriptor debe quedar con un unico archivo modificado.
- No debe reaparecer el placeholder literal prohibido.
- El condition_id canonico debe seguir presente como hexadecimal de 32 bytes con prefijo 0x.
- No debe quedar ningun literal positivo prohibido completo.
- La siguiente fase debe ser review read-only V2 corregida y debe llegar a RESULT=PASS antes de commit/push.


## Confirmed CLOB token mapping - 2026-06-11

This section documents the resolved CLOB token identifiers confirmed by bounded read-only probes.

Canonical target:
- canonical_slug: btc-updown-15m-1781179200
- event_id: 579831
- market_id: 2490133
- condition_id: 0x638e27cb9cd9f80f817206ccff4aaabbc502a1b43c9db0b68ba624ce91925cbb

Confirmed token mapping:
- Up outcome token_id: 105482627641032528690722627023766353242107219670593706191677659404082709634813
- Down outcome token_id: 76169450891197787793400414382780292292557011910798089201047628561078571888133

Confirmed compact markets-by-token/{token_id} shape:
- condition_id
- primary_token_id
- secondary_token_id

Accepted interpretation:
- markets-by-token/{token_id} confirms compact pair metadata only.
- The compact shape confirms that both token ids belong to the same condition pair.
- It does not expose active/closed/archived/acceptingOrders fields.
- It does not prove orderbook existence.
- It does not provide bids/asks.
- It does not make any book snapshot available.

Critical prevention:
- Do not use condition_id as CLOB /book token identifier.
- Do not infer orderbook availability from markets-by-token metadata.
- Do not create snapshot, fixture, replay, collector, bot, runtime integration, wallet/API/order logic, or trading automation from this metadata alone.
- Retry /book only in a later bounded phase with explicit request budget and only against the resolved long decimal token ids.

Previous evidence summary:
- /book?token_id=105482627641032528690722627023766353242107219670593706191677659404082709634813 returned 404 in the prior bounded capture.
- /book?token_id=76169450891197787793400414382780292292557011910798089201047628561078571888133 returned 404 in the prior bounded capture.
- markets-by-token/105482627641032528690722627023766353242107219670593706191677659404082709634813 returned 200 JSON with compact pair mapping.
- markets-by-token/76169450891197787793400414382780292292557011910798089201047628561078571888133 returned 200 JSON with compact pair mapping.

Current status:
- token metadata relationship: confirmed
- market status from this endpoint: not available
- orderbook existence: not demonstrated
- valid bids/asks snapshot: not available
- implementation/runtime/live data: not started by this docs-only update

Parser repair note:
- This section intentionally avoids Markdown inline-code backticks around interpolated PowerShell variables in the executable script.
- Previous attempt failed before execution because backticks inside strings escaped quotes and produced a ParserError.
