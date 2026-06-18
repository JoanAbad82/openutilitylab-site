# BTC_15M_ARENA_RAW_SCHEMA_MAPPING_RULE: outcomes_index_to_clobTokenIds_index; source=Gamma event.markets[0] stringified arrays; tokens field not required for this shape.
# BTC 15m Arena - Bounded Loop Read-Only Probe V2
# BTC15M_RAW_SCHEMA_CONTRACT_PARSER_V2
# Purpose: resolve BTC 15m Gamma event market token ids from the accepted raw schema shape.
# Contract: Gamma /events/slug/<slug> returns a top-level event object; the operable market is in event.markets[0].
# Contract fields: market.outcomes, market.outcomePrices and market.clobTokenIds are JSON arrays encoded as strings.
# Mapping rule: outcomes[index] -> clobTokenIds[index].
# Default mode is plan-only and executes zero market-data requests unless -RequestExecution is explicitly supplied by a later authorized phase.

[CmdletBinding()]
param(
    [switch]$RequestExecution,
    [datetime]$ReferenceUtc = (Get-Date).ToUniversalTime(),
    [int]$TimeoutSeconds = 10
)

$ErrorActionPreference = "Stop"

$Product = "BTC 15m Arena"
$SchemaVersion = "btc_15m_arena_bounded_loop_read_only_probe_v2_raw_schema_contract"
$GammaRequestsPerRun = 1
$ClobBookRequestsPerTick = 2
$MaximumTotalMarketDataHttpRequestsPerRun = $GammaRequestsPerRun + $ClobBookRequestsPerTick

function Write-ProbeLine {
    param([string]$Text)
    Write-Output $Text
}

function ConvertFrom-GammaJsonArrayField {
    param(
        [Parameter(Mandatory=$true)]
        [object]$Value,
        [Parameter(Mandatory=$true)]
        [string]$FieldName
    )

    if ($null -eq $Value) {
        throw ("missing_gamma_market_field:{0}" -f $FieldName)
    }

    if ($Value -is [array]) {
        return @($Value)
    }

    $text = [string]$Value
    if ([string]::IsNullOrWhiteSpace($text)) {
        throw ("empty_gamma_market_field:{0}" -f $FieldName)
    }

    try {
        $parsed = $text | ConvertFrom-Json
    }
    catch {
        throw ("invalid_stringified_json_array_field:{0}" -f $FieldName)
    }

    return @($parsed)
}

function Get-Btc15mAlignedStartUnix {
    param([datetime]$UtcDateTime)

    $normalized = $UtcDateTime.ToUniversalTime()
    $dto = [System.DateTimeOffset]::new($normalized)
    $unix = [int64]$dto.ToUnixTimeSeconds()
    return [int64]([Math]::Floor([double]$unix / 900.0) * 900)
}

function Get-Btc15mCandidateWindow {
    param([datetime]$UtcDateTime)

    $alignedUnix = Get-Btc15mAlignedStartUnix -UtcDateTime $UtcDateTime
    $startUtc = [System.DateTimeOffset]::FromUnixTimeSeconds($alignedUnix).UtcDateTime
    $endUtc = $startUtc.AddMinutes(15)

    return [pscustomobject]@{
        slug = ("btc-updown-15m-{0}" -f $alignedUnix)
        start_unix = $alignedUnix
        start_utc = $startUtc.ToString("o")
        end_utc = $endUtc.ToString("o")
    }
}

function Resolve-Btc15mGammaMarketContract {
    param(
        [Parameter(Mandatory=$true)]
        [object]$GammaEvent,
        [Parameter(Mandatory=$true)]
        [string]$ExpectedSlug
    )

    if ($null -eq $GammaEvent) {
        throw "gamma_event_missing"
    }

    $markets = @($GammaEvent.markets)
    if ($markets.Count -lt 1) {
        throw "gamma_event_markets_missing_or_empty"
    }

    $selectedMarket = $null
    foreach ($candidate in $markets) {
        if ([string]$candidate.slug -eq $ExpectedSlug) {
            $selectedMarket = $candidate
            break
        }
    }

    if ($null -eq $selectedMarket) {
        $selectedMarket = $markets[0]
    }

    $outcomes = @(ConvertFrom-GammaJsonArrayField -Value $selectedMarket.outcomes -FieldName "markets[0].outcomes")
    $outcomePrices = @(ConvertFrom-GammaJsonArrayField -Value $selectedMarket.outcomePrices -FieldName "markets[0].outcomePrices")
    $clobTokenIds = @(ConvertFrom-GammaJsonArrayField -Value $selectedMarket.clobTokenIds -FieldName "markets[0].clobTokenIds")

    if ($outcomes.Count -ne 2) {
        throw ("unexpected_outcomes_count:{0}" -f $outcomes.Count)
    }

    if ($outcomePrices.Count -ne 2) {
        throw ("unexpected_outcomePrices_count:{0}" -f $outcomePrices.Count)
    }

    if ($clobTokenIds.Count -ne 2) {
        throw ("unexpected_clobTokenIds_count:{0}" -f $clobTokenIds.Count)
    }

    $mapping = [ordered]@{}
    for ($i = 0; $i -lt $outcomes.Count; $i++) {
        $outcome = ([string]$outcomes[$i]).Trim()
        $tokenId = ([string]$clobTokenIds[$i]).Trim()

        if ([string]::IsNullOrWhiteSpace($outcome)) {
            throw ("empty_outcome_at_index:{0}" -f $i)
        }

        if ($tokenId -notmatch "^[0-9]{20,}$") {
            throw ("invalid_clob_token_id_at_index:{0}" -f $i)
        }

        $mapping[$outcome] = $tokenId
    }

    if (-not $mapping.Contains("Up")) {
        throw "up_outcome_missing"
    }

    if (-not $mapping.Contains("Down")) {
        throw "down_outcome_missing"
    }

    return [pscustomobject]@{
        event_id = [string]$GammaEvent.id
        event_slug = [string]$GammaEvent.slug
        market_id = [string]$selectedMarket.id
        market_slug = [string]$selectedMarket.slug
        condition_id = [string]$selectedMarket.conditionId
        outcomes = ($outcomes -join "|")
        outcome_prices = ($outcomePrices -join "|")
        clob_token_ids = ($clobTokenIds -join "|")
        up_token_id = [string]$mapping["Up"]
        down_token_id = [string]$mapping["Down"]
        mapping = ("Up->{0};Down->{1}" -f $mapping["Up"], $mapping["Down"])
        parser_contract = "event.markets[0].outcomes/outcomePrices/clobTokenIds stringified arrays mapped by index"
    }
}

function Invoke-Btc15mPublicJsonRequest {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Uri,
        [int]$TimeoutSecondsValue = 10
    )

    return Invoke-RestMethod -Uri $Uri -Method Get -TimeoutSec $TimeoutSecondsValue
}

function Get-Btc15mClobBook {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TokenId,
        [int]$TimeoutSecondsValue = 10
    )

    $encoded = [System.Uri]::EscapeDataString($TokenId)
    $uri = "https://clob.polymarket.com/book?token_id=$encoded"
    return Invoke-Btc15mPublicJsonRequest -Uri $uri -TimeoutSecondsValue $TimeoutSecondsValue
}

Write-ProbeLine ("product={0}" -f $Product)
Write-ProbeLine ("schema_version={0}" -f $SchemaVersion)
Write-ProbeLine ("request_execution_requested={0}" -f [bool]$RequestExecution)
Write-ProbeLine ("gamma_requests_per_run={0}" -f $GammaRequestsPerRun)
Write-ProbeLine ("clob_book_requests_per_tick={0}" -f $ClobBookRequestsPerTick)
Write-ProbeLine ("maximum_total_market_data_http_requests_per_run={0}" -f $MaximumTotalMarketDataHttpRequestsPerRun)

$window = Get-Btc15mCandidateWindow -UtcDateTime $ReferenceUtc
Write-ProbeLine ("target_slug={0}" -f $window.slug)
Write-ProbeLine ("target_window_start_unix={0}" -f $window.start_unix)
Write-ProbeLine ("target_window_start_utc={0}" -f $window.start_utc)
Write-ProbeLine ("target_window_end_utc={0}" -f $window.end_utc)
Write-ProbeLine "parser_contract=Gamma event object -> markets[0] -> stringified outcomes/outcomePrices/clobTokenIds -> index mapping"
Write-ProbeLine "tokens_field_required_for_this_shape=False"

if (-not $RequestExecution) {
    Write-ProbeLine "execution_mode=PLAN_ONLY_ZERO_MARKET_DATA_REQUESTS"
    Write-ProbeLine "gamma_requests_executed=0"
    Write-ProbeLine "clob_book_requests_executed=0"
    Write-ProbeLine "market_data_http_requests_executed=0"
    Write-ProbeLine "RESULT=PLAN_ONLY"
    return
}

$gammaUri = "https://gamma-api.polymarket.com/events/slug/$($window.slug)"
$gammaEvent = Invoke-Btc15mPublicJsonRequest -Uri $gammaUri -TimeoutSecondsValue $TimeoutSeconds
$resolved = Resolve-Btc15mGammaMarketContract -GammaEvent $gammaEvent -ExpectedSlug $window.slug

Write-ProbeLine ("resolved_event_id={0}" -f $resolved.event_id)
Write-ProbeLine ("resolved_event_slug={0}" -f $resolved.event_slug)
Write-ProbeLine ("resolved_market_id={0}" -f $resolved.market_id)
Write-ProbeLine ("resolved_market_slug={0}" -f $resolved.market_slug)
Write-ProbeLine ("resolved_condition_id={0}" -f $resolved.condition_id)
Write-ProbeLine ("resolved_outcomes={0}" -f $resolved.outcomes)
Write-ProbeLine ("resolved_outcome_prices={0}" -f $resolved.outcome_prices)
Write-ProbeLine ("resolved_clob_token_ids={0}" -f $resolved.clob_token_ids)
Write-ProbeLine ("resolved_mapping={0}" -f $resolved.mapping)
Write-ProbeLine ("resolved_up_token_id={0}" -f $resolved.up_token_id)
Write-ProbeLine ("resolved_down_token_id={0}" -f $resolved.down_token_id)

$upBook = Get-Btc15mClobBook -TokenId $resolved.up_token_id -TimeoutSecondsValue $TimeoutSeconds
$downBook = Get-Btc15mClobBook -TokenId $resolved.down_token_id -TimeoutSecondsValue $TimeoutSeconds

Write-ProbeLine ("up_book_bids_count={0}" -f @($upBook.bids).Count)
Write-ProbeLine ("up_book_asks_count={0}" -f @($upBook.asks).Count)
Write-ProbeLine ("down_book_bids_count={0}" -f @($downBook.bids).Count)
Write-ProbeLine ("down_book_asks_count={0}" -f @($downBook.asks).Count)
Write-ProbeLine "gamma_requests_executed=1"
Write-ProbeLine "clob_book_requests_executed=2"
Write-ProbeLine "market_data_http_requests_executed=3"
Write-ProbeLine "RESULT=BOUNDED_READ_ONLY_PROBE_COMPLETE"