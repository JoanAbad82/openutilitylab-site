# BTC 15m Arena - Bounded Loop Read-Only Probe V1
# Mode: PlanOnly local scaffold.
# This local script does not execute market-data requests.
# This local script does not implement a running loop.
# This local script is not a collector, not a bot, not a snapshot writer and not a fixture writer.
# Guardrails:
# - No wallet.
# - No private keys.
# - No authenticated trading API.
# - No real orders.
# - No order creation.
# - No order placement.
# - No order execution.
# - No trading automation.
# - No live trading.
# - No trading signals.
# - No financial advice.
# - No profit claims.
# - No guaranteed profit.
# - No guaranteed prediction.
# Target policy: fresh_window_only_aligned_900_seconds_not_closed_not_reused.

[CmdletBinding()]
param(
  [ValidateSet("PlanOnly")]
  [string]$Mode = "PlanOnly",

  [datetime]$ReferenceUtc = ([datetime]::UtcNow),

  [ValidateRange(1, 3)]
  [int]$MaximumTicksPerRun = 3,

  [ValidateRange(20, 3600)]
  [int]$MinimumTickIntervalSeconds = 20,

  [ValidateRange(1, 10)]
  [int]$HttpTimeoutSeconds = 10,

  [switch]$AsJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Product = "BTC 15m Arena"
$SchemaVersion = "btc_15m_arena_bounded_loop_read_only_probe_plan_v1"

$GammaRequestsPerRun = 1
$ClobBookRequestsPerTick = 2
$MaximumTotalMarketDataHttpRequestsPerRun = $GammaRequestsPerRun + ($ClobBookRequestsPerTick * $MaximumTicksPerRun)

if ($Mode -ne "PlanOnly") {
  throw "Only PlanOnly is implemented. This script does not execute market-data requests."
}

if ($MaximumTotalMarketDataHttpRequestsPerRun -gt 7) {
  throw "Request cap exceeded. Maximum total market-data HTTP requests per run must stay <= 7."
}

function Get-UnixSecondsUtc {
  param([datetime]$UtcDateTime)
  $normalized = $UtcDateTime.ToUniversalTime()
  return [int64][Math]::Floor(($normalized - [datetime]"1970-01-01T00:00:00Z").TotalSeconds)
}

function Get-Btc15mCandidateWindow {
  param([datetime]$UtcDateTime)

  $unixNow = Get-UnixSecondsUtc -UtcDateTime $UtcDateTime
  $windowSize = 900
  $alignedStart = [int64]([Math]::Floor($unixNow / $windowSize) * $windowSize)
  $secondsIntoWindow = [int64]($unixNow - $alignedStart)
  $candidateStart = $alignedStart
  $selectionNote = "current_aligned_window"

  if ($secondsIntoWindow -ge 840) {
    $candidateStart = [int64]($alignedStart + $windowSize)
    $selectionNote = "next_aligned_window_selected_because_current_window_is_in_final_minute"
  }

  $candidateEnd = [int64]($candidateStart + $windowSize)
  $candidateSlug = "btc-updown-15m-$candidateStart"

  [pscustomobject]@{
    unix_now = $unixNow
    window_size_seconds = $windowSize
    candidate_window_start_unix = $candidateStart
    candidate_window_end_unix = $candidateEnd
    seconds_into_current_window = $secondsIntoWindow
    fresh_btc_updown_15m_slug = $candidateSlug
    selection_note = $selectionNote
    target_policy = "fresh_window_only_aligned_900_seconds_not_closed_not_reused"
  }
}

$window = Get-Btc15mCandidateWindow -UtcDateTime $ReferenceUtc

$closedReferenceSlug = "btc-updown-15m-1781708400"
$closedReferenceTokenIds = @(
  "42082333147465454912145556211445121129676724086717569761807000971672053767352",
  "45319980697747047378266542514078429282204322526025589645289739305457177753107"
)

if ($window.fresh_btc_updown_15m_slug -eq $closedReferenceSlug) {
  throw "Candidate slug matches a closed reference slug and must not be reused."
}

$result = [pscustomobject]@{
  product = $Product
  schema_version = $SchemaVersion
  mode = $Mode
  request_execution = "disabled"
  market_data_http_requests_executed = 0
  gamma_requests_executed = 0
  clob_book_requests_executed = 0
  runtime_loop_started = $false
  collector_started = $false
  bot_started = $false
  snapshot_written = $false
  fixture_written = $false
  wallet_or_order_logic = $false
  trading_signals = $false
  financial_advice = $false
  profit_or_prediction_claim = $false
  caps = [pscustomobject]@{
    gamma_requests_per_run = $GammaRequestsPerRun
    clob_book_requests_per_tick = $ClobBookRequestsPerTick
    maximum_ticks_per_run = $MaximumTicksPerRun
    maximum_total_market_data_http_requests_per_run = $MaximumTotalMarketDataHttpRequestsPerRun
    http_timeout_seconds = $HttpTimeoutSeconds
    minimum_tick_interval_seconds = $MinimumTickIntervalSeconds
  }
  window = $window
  planned_endpoint_templates = [pscustomobject]@{
    gamma_events = "https://gamma-api.polymarket.com/events?slug=$($window.fresh_btc_updown_15m_slug)"
    clob_book = "https://clob.polymarket.com/book?token_id=<fresh_token_id_from_fresh_gamma_outcome_mapping>"
  }
  excluded_reuse_references = [pscustomobject]@{
    closed_reference_slug = $closedReferenceSlug
    closed_reference_token_ids = $closedReferenceTokenIds
    stale_or_unavailable_token_book_policy = "stale_or_unavailable_token_book_not_old_uri_bug_unless_fresh_target_proves_otherwise"
  }
  allowed_output_kind = "console_table_or_json_summary_only"
  guardrails = @(
    "Simulation only.",
    "Manual review only.",
    "No wallet.",
    "No private keys.",
    "No authenticated trading API.",
    "No real orders.",
    "No order creation.",
    "No order placement.",
    "No order execution.",
    "No trading automation.",
    "No live trading.",
    "No trading signals.",
    "No financial advice.",
    "No profit claims.",
    "No guaranteed profit.",
    "No guaranteed prediction."
  )
  next_required_authorization = "A later phase must explicitly authorize request execution before any Gamma or CLOB call is added or run."
}

if ($AsJson) {
  $result | ConvertTo-Json -Depth 8
} else {
  Write-Host "BTC_15M_ARENA_BOUNDED_LOOP_READ_ONLY_PROBE_PLAN"
  Write-Host "mode=$($result.mode)"
  Write-Host "request_execution=$($result.request_execution)"
  Write-Host "fresh_slug=$($result.window.fresh_btc_updown_15m_slug)"
  Write-Host "candidate_window_start_unix=$($result.window.candidate_window_start_unix)"
  Write-Host "candidate_window_end_unix=$($result.window.candidate_window_end_unix)"
  Write-Host "gamma_requests_per_run=$($result.caps.gamma_requests_per_run)"
  Write-Host "clob_book_requests_per_tick=$($result.caps.clob_book_requests_per_tick)"
  Write-Host "maximum_ticks_per_run=$($result.caps.maximum_ticks_per_run)"
  Write-Host "maximum_total_market_data_http_requests_per_run=$($result.caps.maximum_total_market_data_http_requests_per_run)"
  Write-Host "http_timeout_seconds=$($result.caps.http_timeout_seconds)"
  Write-Host "minimum_tick_interval_seconds=$($result.caps.minimum_tick_interval_seconds)"
  Write-Host "market_data_http_requests_executed=$($result.market_data_http_requests_executed)"
  Write-Host "runtime_loop_started=$($result.runtime_loop_started)"
  Write-Host "wallet_or_order_logic=$($result.wallet_or_order_logic)"
  Write-Host "trading_signals=$($result.trading_signals)"
  Write-Host "financial_advice=$($result.financial_advice)"
}