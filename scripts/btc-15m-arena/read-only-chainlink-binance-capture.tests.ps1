[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$CaptureScriptPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $CaptureScriptPath -PathType Leaf)) {
    throw "Capture script missing: $CaptureScriptPath"
}

. $CaptureScriptPath

$script:TestsPassed = 0
$script:TestsFailed = 0
$script:FailureMessages = @()

function Assert-Btc15mTrue {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Message
    )
    if (-not $Condition) { throw $Message }
}

function Assert-Btc15mEqual {
    param(
        [AllowNull()]$Actual,
        [AllowNull()]$Expected,
        [Parameter(Mandatory)][string]$Message
    )
    if ($Actual -cne $Expected) {
        throw "$Message expected=[$Expected] actual=[$Actual]"
    }
}

function Assert-Btc15mThrows {
    param(
        [Parameter(Mandatory)][scriptblock]$Action,
        [Parameter(Mandatory)][string]$Message
    )
    $threw = $false
    try {
        & $Action
    }
    catch {
        $threw = $true
    }
    if (-not $threw) { throw $Message }
}

function Invoke-Btc15mTest {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][scriptblock]$Body
    )
    try {
        & $Body
        $script:TestsPassed++
        Write-Output "TEST_PASS::$Name"
    }
    catch {
        $script:TestsFailed++
        $message = "TEST_FAIL::{0}::{1}" -f $Name, $_.Exception.Message
        $script:FailureMessages += $message
        Write-Output $message
    }
}

function New-Btc15mTestBinanceJson {
    param(
        [long]$AggregateTradeId,
        [long]$EventTimestampMs,
        [long]$TradeTimestampMs,
        [string]$Price = '60000.10',
        [string]$Quantity = '0.00100000',
        [bool]$BuyerIsMaker = $true
    )

    $makerText = if ($BuyerIsMaker) { 'true' } else { 'false' }
    $template = '{"e":"aggTrade","E":__EVENT_TS__,"s":"BTCUSDT","a":__AGG_ID__,"p":"__PRICE__","q":"__QTY__","f":__FIRST_ID__,"l":__LAST_ID__,"T":__TRADE_TS__,"m":__MAKER__,"M":false}'
    $result = $template.Replace('__EVENT_TS__', [string]$EventTimestampMs)
    $result = $result.Replace('__AGG_ID__', [string]$AggregateTradeId)
    $result = $result.Replace('__PRICE__', $Price)
    $result = $result.Replace('__QTY__', $Quantity)
    $result = $result.Replace('__FIRST_ID__', [string]($AggregateTradeId * 2))
    $result = $result.Replace('__LAST_ID__', [string]($AggregateTradeId * 2 + 1))
    $result = $result.Replace('__TRADE_TS__', [string]$TradeTimestampMs)
    $result = $result.Replace('__MAKER__', $makerText)
    return $result
}

$chainlinkJson = '{"topic":"crypto_prices_chainlink","type":"update","timestamp":1700000000500,"payload":{"symbol":"btc/usd","timestamp":1700000000000,"value":"60001.25000000"}}'
$binanceJson = New-Btc15mTestBinanceJson -AggregateTradeId 100 -EventTimestampMs 1700000000400 -TradeTimestampMs 1700000000300

Invoke-Btc15mTest -Name '01_CHAINLINK_SUBSCRIPTION_SERIALIZATION_EXACT' -Body {
    $actual = New-Btc15mChainlinkSubscriptionJson
    $expected = '{"action":"subscribe","subscriptions":[{"topic":"crypto_prices_chainlink","type":"*","filters":"{\"symbol\":\"btc/usd\"}"}]}'
    Assert-Btc15mEqual -Actual $actual -Expected $expected -Message 'Chainlink subscription JSON differs.'
}

Invoke-Btc15mTest -Name '02_CHAINLINK_PARSE_AND_TIMESTAMP_PROVENANCE' -Body {
    $eventItem = ConvertFrom-Btc15mChainlinkMessage `
        -RawJson $chainlinkJson `
        -RunId 'TEST_RUN' `
        -CollectorReceiveTimestampMs 1700000000600 `
        -CollectorSequence 1 `
        -ConnectionId 'TEST_CHAINLINK'
    Assert-Btc15mEqual -Actual $eventItem.source -Expected 'CHAINLINK_BTC_USD' -Message 'Chainlink source mismatch.'
    Assert-Btc15mEqual -Actual ([long]$eventItem.source_timestamp_ms) -Expected 1700000000000L -Message 'Source timestamp mismatch.'
    Assert-Btc15mEqual -Actual ([long]$eventItem.event_timestamp_ms) -Expected 1700000000500L -Message 'Event timestamp mismatch.'
    Assert-Btc15mEqual -Actual ([long]$eventItem.collector_receive_timestamp_ms) -Expected 1700000000600L -Message 'Receive timestamp mismatch.'
    Assert-Btc15mEqual -Actual $eventItem.value_decimal_string -Expected '60001.25000000' -Message 'Value string mismatch.'
    Assert-Btc15mEqual -Actual $eventItem.quantity_decimal_string -Expected $null -Message 'Chainlink quantity must normalize to null.'
}

Invoke-Btc15mTest -Name '03_BINANCE_CASE_SENSITIVE_E_E_M_M_PARSER' -Body {
    $eventItem = ConvertFrom-Btc15mBinanceAggTradeMessage `
        -RawJson $binanceJson `
        -RunId 'TEST_RUN' `
        -CollectorReceiveTimestampMs 1700000000500 `
        -CollectorSequence 2 `
        -ConnectionId 'TEST_BINANCE'
    Assert-Btc15mEqual -Actual ([long]$eventItem.event_timestamp_ms) -Expected 1700000000400L -Message 'Uppercase E was not preserved.'
    Assert-Btc15mEqual -Actual ([long]$eventItem.source_timestamp_ms) -Expected 1700000000300L -Message 'Uppercase T was not preserved.'
    Assert-Btc15mEqual -Actual ([bool]$eventItem.buyer_is_maker) -Expected $true -Message 'Lowercase m was not preserved.'
    Assert-Btc15mEqual -Actual $eventItem.quantity_decimal_string -Expected '0.00100000' -Message 'Binance quantity was not preserved.'
    Assert-Btc15mThrows -Action {
        [void](New-Btc15mRawEvent `
            -RunId 'TEST_RUN' `
            -Source 'BINANCE_BTCUSDT' `
            -Symbol 'BTCUSDT' `
            -SourceTimestampMs 1700000000300 `
            -EventTimestampMs 1700000000400 `
            -CollectorReceiveTimestampMs 1700000000500 `
            -CollectorSequence 3 `
            -ConnectionId 'TEST_BINANCE_MISSING_QUANTITY' `
            -ValueDecimalString '60000.10' `
            -RawPayloadJson '{}')
    } -Message 'Binance quantity must remain required.'
}

Invoke-Btc15mTest -Name '04_BINANCE_AGGTRADE_IDENTIFIER_PROVENANCE' -Body {
    $eventItem = ConvertFrom-Btc15mBinanceAggTradeMessage `
        -RawJson $binanceJson `
        -RunId 'TEST_RUN' `
        -CollectorReceiveTimestampMs 1700000000500 `
        -CollectorSequence 2 `
        -ConnectionId 'TEST_BINANCE'
    Assert-Btc15mEqual -Actual ([long]$eventItem.aggregate_trade_id) -Expected 100L -Message 'Aggregate trade ID mismatch.'
    Assert-Btc15mEqual -Actual ([long]$eventItem.first_trade_id) -Expected 200L -Message 'First trade ID mismatch.'
    Assert-Btc15mEqual -Actual ([long]$eventItem.last_trade_id) -Expected 201L -Message 'Last trade ID mismatch.'
}

Invoke-Btc15mTest -Name '05_BINANCE_DIAGNOSTICS_PRESERVE_HASH_AND_PARSE_ERROR' -Body {
    $diagnostic = Get-Btc15mBinanceMessageDiagnostic `
        -RawJson '{bad-json' `
        -RunId 'TEST_RUN' `
        -CollectorReceiveTimestampMs 1700000000500 `
        -CollectorSequence 2 `
        -ConnectionId 'TEST_BINANCE'
    Assert-Btc15mEqual -Actual $diagnostic.result -Expected 'NO_PASS' -Message 'Invalid JSON should fail.'
    Assert-Btc15mTrue -Condition ([string]$diagnostic.raw_payload_sha256 -match '^[0-9a-f]{64}$') -Message 'Raw hash missing.'
    Assert-Btc15mTrue -Condition (-not [string]::IsNullOrWhiteSpace([string]$diagnostic.parse_error_message)) -Message 'Parse error message missing.'
}

Invoke-Btc15mTest -Name '06_BINANCE_GAP_DETECTION_AND_REST_REPAIR_REQUEST' -Body {
    $firstJson = New-Btc15mTestBinanceJson -AggregateTradeId 10 -EventTimestampMs 1700000000100 -TradeTimestampMs 1700000000000
    $secondJson = New-Btc15mTestBinanceJson -AggregateTradeId 13 -EventTimestampMs 1700000000300 -TradeTimestampMs 1700000000200
    $first = ConvertFrom-Btc15mBinanceAggTradeMessage -RawJson $firstJson -RunId 'TEST' -CollectorReceiveTimestampMs 1700000000400 -CollectorSequence 1 -ConnectionId 'B'
    $second = ConvertFrom-Btc15mBinanceAggTradeMessage -RawJson $secondJson -RunId 'TEST' -CollectorReceiveTimestampMs 1700000000500 -CollectorSequence 2 -ConnectionId 'B'
    $gaps = @(Get-Btc15mBinanceGapDiagnostics -Events @($first, $second))
    Assert-Btc15mEqual -Actual $gaps.Count -Expected 1 -Message 'Expected one Binance gap.'
    Assert-Btc15mEqual -Actual ([long]$gaps[0].missing_from_id) -Expected 11L -Message 'Missing from ID mismatch.'
    Assert-Btc15mEqual -Actual ([long]$gaps[0].missing_to_id) -Expected 12L -Message 'Missing to ID mismatch.'
    Assert-Btc15mEqual -Actual $gaps[0].repair_request_uri -Expected 'https://data-api.binance.vision/api/v3/aggTrades?symbol=BTCUSDT&fromId=11&limit=2' -Message 'Repair URI mismatch.'
}

Invoke-Btc15mTest -Name '07_DUPLICATE_REJECTION_PER_SOURCE' -Body {
    $chainlinkEvent = ConvertFrom-Btc15mChainlinkMessage -RawJson $chainlinkJson -RunId 'TEST' -CollectorReceiveTimestampMs 1700000000600 -CollectorSequence 1 -ConnectionId 'C'
    $binanceEvent = ConvertFrom-Btc15mBinanceAggTradeMessage -RawJson $binanceJson -RunId 'TEST' -CollectorReceiveTimestampMs 1700000000500 -CollectorSequence 2 -ConnectionId 'B'
    $unique = @(Select-Btc15mUniqueEvents -Events @($chainlinkEvent, $chainlinkEvent, $binanceEvent, $binanceEvent))
    Assert-Btc15mEqual -Actual $unique.Count -Expected 2 -Message 'Duplicate events were not removed.'
}

Invoke-Btc15mTest -Name '08_AUTOMATIC_CHAINLINK_TO_BINANCE_FALLBACK_FORBIDDEN' -Body {
    $contract = Get-Btc15mCaptureContract
    Assert-Btc15mEqual -Actual $contract.primary_feature_source -Expected 'CHAINLINK_BTC_USD' -Message 'Primary source mismatch.'
    Assert-Btc15mEqual -Actual $contract.secondary_diagnostic_source -Expected 'BINANCE_BTCUSDT' -Message 'Secondary source mismatch.'
    Assert-Btc15mEqual -Actual $contract.automatic_source_fallback -Expected 'FORBIDDEN' -Message 'Fallback must be forbidden.'
}

Invoke-Btc15mTest -Name '09_COLLECTOR_WRITE_BOUNDARY_OUTPUT_DIRECTORY_ONLY' -Body {
    $testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('btc15m-boundary-' + [Guid]::NewGuid().ToString('N'))
    [void][System.IO.Directory]::CreateDirectory($testRoot)
    try {
        $outside = Join-Path ([System.IO.Path]::GetTempPath()) ('btc15m-outside-' + [Guid]::NewGuid().ToString('N'))
        Assert-Btc15mThrows -Action { Assert-Btc15mOutputBoundary -CandidatePath $outside -AllowedRoot $testRoot } -Message 'Outside output path was accepted.'
        $inside = Join-Path $testRoot 'run-1'
        Assert-Btc15mTrue -Condition (Test-Btc15mChildPath -CandidatePath $inside -AllowedRoot $testRoot) -Message 'Inside output path was rejected.'
    }
    finally {
        if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
    }
}

Invoke-Btc15mTest -Name '10_NO_WALLET_API_KEY_PRIVATE_KEY_OR_TRADING_PRIMITIVES' -Body {
    $content = [System.IO.File]::ReadAllText($CaptureScriptPath)
    foreach ($pattern in @(
        'connectWallet',
        'privateKey',
        'apiKey',
        'createOrder',
        'placeOrder',
        'executeOrder',
        'cancelOrder',
        'order signing'
    )) {
        Assert-Btc15mTrue -Condition ($content.IndexOf($pattern, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) -Message "Prohibited primitive present: $pattern"
    }
}

Invoke-Btc15mTest -Name '11_NETWORK_CAPTURE_AND_OFFLINE_BAR_BUILDER_SEPARATED' -Body {
    $content = [System.IO.File]::ReadAllText($CaptureScriptPath)
    Assert-Btc15mTrue -Condition ($content.IndexOf('offline-underlying-1m-bar-builder.ps1', [System.StringComparison]::OrdinalIgnoreCase) -lt 0) -Message 'Capture script invokes bar builder.'
    Assert-Btc15mTrue -Condition ($content.IndexOf('New-Btc15mUnderlyingBars', [System.StringComparison]::OrdinalIgnoreCase) -lt 0) -Message 'Capture script embeds bar construction.'

    $testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('btc15m-capture-' + [Guid]::NewGuid().ToString('N'))
    [void][System.IO.Directory]::CreateDirectory($testRoot)
    try {
        $output = Join-Path $testRoot 'bundle'
        $chainlinkEvent = ConvertFrom-Btc15mChainlinkMessage -RawJson $chainlinkJson -RunId 'TEST' -CollectorReceiveTimestampMs 1700000000600 -CollectorSequence 1 -ConnectionId 'C'
        $binanceEvent = ConvertFrom-Btc15mBinanceAggTradeMessage -RawJson $binanceJson -RunId 'TEST' -CollectorReceiveTimestampMs 1700000000500 -CollectorSequence 2 -ConnectionId 'B'
        $result = Write-Btc15mCaptureBundle -Events @($chainlinkEvent, $binanceEvent) -OutputDirectory $output -AllowedOutputRoot $testRoot -RunId 'TEST'
        Assert-Btc15mEqual -Actual $result.result -Expected 'PASS' -Message 'Capture bundle did not pass.'
        Assert-Btc15mTrue -Condition (Test-Path -LiteralPath (Join-Path $output 'raw_events.jsonl')) -Message 'Raw JSONL missing.'
        Assert-Btc15mTrue -Condition (Test-Path -LiteralPath (Join-Path $output 'manifest.json')) -Message 'Manifest missing.'
    }
    finally {
        if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
    }
}

Write-Output ("TESTS_PASSED={0}" -f $script:TestsPassed)
Write-Output ("TESTS_FAILED={0}" -f $script:TestsFailed)
Write-Output ("TEST_SUITE_RESULT={0}" -f $(if ($script:TestsFailed -eq 0) { 'PASS' } else { 'NO_PASS' }))

if ($script:TestsFailed -ne 0) {
    foreach ($failure in $script:FailureMessages) { Write-Output $failure }
    exit 1
}
exit 0
