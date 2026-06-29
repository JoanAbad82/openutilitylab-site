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

function Assert-Btc15mContains {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$Needle,
        [Parameter(Mandatory)][string]$Message
    )
    if ($Text.IndexOf($Needle, [System.StringComparison]::Ordinal) -lt 0) {
        throw "$Message missing=[$Needle] text=[$Text]"
    }
}

function Assert-Btc15mThrowsLike {
    param(
        [Parameter(Mandatory)][scriptblock]$Action,
        [Parameter(Mandatory)][string[]]$ExpectedFragments,
        [Parameter(Mandatory)][string]$Message
    )
    $threw = $false
    $errorText = ''
    try {
        & $Action
    }
    catch {
        $threw = $true
        $errorText = $_.Exception.Message
    }
    if (-not $threw) { throw $Message }
    foreach ($fragment in $ExpectedFragments) {
        Assert-Btc15mContains -Text $errorText -Needle $fragment -Message $Message
    }
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

Invoke-Btc15mTest -Name '12_VALID_MIXED_EVENTS_PASS_SHAPE_VALIDATION_AND_DEDUP' -Body {
    $chainlinkEvent = ConvertFrom-Btc15mChainlinkMessage -RawJson $chainlinkJson -RunId 'TEST' -CollectorReceiveTimestampMs 1700000000600 -CollectorSequence 1 -ConnectionId 'C'
    $binanceEvent = ConvertFrom-Btc15mBinanceAggTradeMessage -RawJson $binanceJson -RunId 'TEST' -CollectorReceiveTimestampMs 1700000000500 -CollectorSequence 2 -ConnectionId 'B'
    $unique = @(Select-Btc15mUniqueEvents -Events @($chainlinkEvent, $binanceEvent, $binanceEvent, $chainlinkEvent))
    Assert-Btc15mEqual -Actual $unique.Count -Expected 2 -Message 'Valid mixed events did not deduplicate to two events.'
    Assert-Btc15mEqual -Actual $unique[0].source -Expected 'BINANCE_BTCUSDT' -Message 'Deterministic source order changed.'
    Assert-Btc15mEqual -Actual $unique[1].source -Expected 'CHAINLINK_BTC_USD' -Message 'Deterministic source order changed.'
    Assert-Btc15mTrue -Condition ([object]::ReferenceEquals($unique[0], $binanceEvent)) -Message 'Binance event object was not preserved exactly.'
    Assert-Btc15mTrue -Condition ([object]::ReferenceEquals($unique[1], $chainlinkEvent)) -Message 'Chainlink event object was not preserved exactly.'
}

Invoke-Btc15mTest -Name '13_AUXILIARY_VOID_TASK_RESULT_REJECTED_BEFORE_SORT' -Body {
    $eventItem = ConvertFrom-Btc15mChainlinkMessage -RawJson $chainlinkJson -RunId 'TEST' -CollectorReceiveTimestampMs 1700000000600 -CollectorSequence 1 -ConnectionId 'C'
    function Invoke-Btc15mUnsuppressedVoidTaskThenEvent {
        [System.Threading.Tasks.Task]::CompletedTask.GetAwaiter().GetResult()
        $eventItem
    }
    $items = @(Invoke-Btc15mUnsuppressedVoidTaskThenEvent)
    Assert-Btc15mEqual -Actual $items.Count -Expected 2 -Message 'Unsuppressed void task did not reproduce a contaminating object.'
    Assert-Btc15mEqual -Actual $items[0].GetType().FullName -Expected 'System.Threading.Tasks.VoidTaskResult' -Message 'Unexpected contaminating object type.'
    Assert-Btc15mThrowsLike -Action {
        [void](Select-Btc15mUniqueEvents -Events $items)
    } -ExpectedFragments @(
        'RAW_EVENT_SHAPE_INVALID',
        'boundary=Select-Btc15mUniqueEvents',
        'index=0',
        'type=System.Threading.Tasks.VoidTaskResult',
        'missing=source'
    ) -Message 'Auxiliary non-event object was not rejected before sorting with precise diagnostics.'
}

Invoke-Btc15mTest -Name '14_SOURCE_PRESENT_EVENT_MISSING_REQUIRED_FIELD_REJECTED_PRECISELY' -Body {
    $partialEvent = [pscustomobject][ordered]@{
        schema_version = $script:Btc15mRawSchemaVersion
        run_id = 'TEST'
        source = 'CHAINLINK_BTC_USD'
        symbol = 'btc/usd'
        source_timestamp_ms = 1700000000000L
        event_timestamp_ms = 1700000000500L
        collector_receive_timestamp_ms = 1700000000600L
        collector_sequence = 1L
        connection_id = 'C'
        value_decimal_string = '60001.25000000'
        raw_payload_sha256 = '0' * 64
    }
    Assert-Btc15mThrowsLike -Action {
        [void](Select-Btc15mUniqueEvents -Events @($partialEvent))
    } -ExpectedFragments @(
        'RAW_EVENT_SHAPE_INVALID',
        'boundary=Select-Btc15mUniqueEvents',
        'index=0',
        'missing=raw_payload_json'
    ) -Message 'Partially shaped event was not rejected with the missing required field.'
}

Invoke-Btc15mTest -Name '15_SINGLE_EVENT_REMAINS_ONE_ELEMENT_COLLECTION' -Body {
    $eventItem = ConvertFrom-Btc15mChainlinkMessage -RawJson $chainlinkJson -RunId 'TEST' -CollectorReceiveTimestampMs 1700000000600 -CollectorSequence 1 -ConnectionId 'C'
    $unique = @(Select-Btc15mUniqueEvents -Events $eventItem)
    Assert-Btc15mEqual -Actual $unique.Count -Expected 1 -Message 'Single event did not remain a one-element collection.'
    Assert-Btc15mEqual -Actual $unique[0].source -Expected 'CHAINLINK_BTC_USD' -Message 'Single event source changed.'
}

Invoke-Btc15mTest -Name '16_MULTIPLE_EVENTS_PRESERVE_DETERMINISTIC_ORDER' -Body {
    $chainlinkEvent = ConvertFrom-Btc15mChainlinkMessage -RawJson $chainlinkJson -RunId 'TEST' -CollectorReceiveTimestampMs 1700000000600 -CollectorSequence 3 -ConnectionId 'C'
    $firstBinance = ConvertFrom-Btc15mBinanceAggTradeMessage -RawJson (New-Btc15mTestBinanceJson -AggregateTradeId 99 -EventTimestampMs 1700000000200 -TradeTimestampMs 1700000000100) -RunId 'TEST' -CollectorReceiveTimestampMs 1700000000500 -CollectorSequence 2 -ConnectionId 'B'
    $secondBinance = ConvertFrom-Btc15mBinanceAggTradeMessage -RawJson $binanceJson -RunId 'TEST' -CollectorReceiveTimestampMs 1700000000500 -CollectorSequence 1 -ConnectionId 'B'
    $unique = @(Select-Btc15mUniqueEvents -Events @($chainlinkEvent, $secondBinance, $firstBinance))
    Assert-Btc15mEqual -Actual $unique.Count -Expected 3 -Message 'Expected three unique events.'
    Assert-Btc15mEqual -Actual ([long]$unique[0].aggregate_trade_id) -Expected 99L -Message 'First Binance event order mismatch.'
    Assert-Btc15mEqual -Actual ([long]$unique[1].aggregate_trade_id) -Expected 100L -Message 'Second Binance event order mismatch.'
    Assert-Btc15mEqual -Actual $unique[2].source -Expected 'CHAINLINK_BTC_USD' -Message 'Chainlink source order mismatch.'
}

Invoke-Btc15mTest -Name '17_ASYNC_SIDE_EFFECT_OUTPUT_SUPPRESSED_AT_SOURCE' -Body {
    function Invoke-Btc15mSuppressedVoidTaskThenEvent {
        [void][System.Threading.Tasks.Task]::CompletedTask.GetAwaiter().GetResult()
        ConvertFrom-Btc15mChainlinkMessage -RawJson $chainlinkJson -RunId 'TEST' -CollectorReceiveTimestampMs 1700000000600 -CollectorSequence 1 -ConnectionId 'C'
    }
    $items = @(Invoke-Btc15mSuppressedVoidTaskThenEvent)
    Assert-Btc15mEqual -Actual $items.Count -Expected 1 -Message 'Suppressed side-effect task emitted functional output.'
    Assert-Btc15mEqual -Actual $items[0].source -Expected 'CHAINLINK_BTC_USD' -Message 'Expected only the functional event output.'

    $content = [System.IO.File]::ReadAllText($CaptureScriptPath)
    Assert-Btc15mContains -Text $content -Needle '[void]$Client.SendAsync(' -Message 'WebSocket send side-effect output is not suppressed at source.'
    Assert-Btc15mContains -Text $content -Needle '[void]$client.CloseAsync(' -Message 'WebSocket close side-effect output is not suppressed at source.'
    Assert-Btc15mTrue -Condition (-not [regex]::IsMatch($content, '(?m)^\s*\$Client\.SendAsync\(')) -Message 'Unsuppressed WebSocket send call remains.'
    Assert-Btc15mTrue -Condition (-not [regex]::IsMatch($content, '(?m)^\s*\$client\.CloseAsync\(')) -Message 'Unsuppressed WebSocket close call remains.'
}

Invoke-Btc15mTest -Name '18_FIXTURE_BUNDLE_GENERATION_REMAINS_DETERMINISTIC' -Body {
    $testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('btc15m-deterministic-' + [Guid]::NewGuid().ToString('N'))
    [void][System.IO.Directory]::CreateDirectory($testRoot)
    try {
        $events = @(
            (ConvertFrom-Btc15mChainlinkMessage -RawJson $chainlinkJson -RunId 'TEST' -CollectorReceiveTimestampMs 1700000000600 -CollectorSequence 1 -ConnectionId 'C'),
            (ConvertFrom-Btc15mBinanceAggTradeMessage -RawJson $binanceJson -RunId 'TEST' -CollectorReceiveTimestampMs 1700000000500 -CollectorSequence 2 -ConnectionId 'B')
        )
        $firstOutput = Join-Path $testRoot 'bundle-a'
        $secondOutput = Join-Path $testRoot 'bundle-b'
        [void](Write-Btc15mCaptureBundle -Events $events -OutputDirectory $firstOutput -AllowedOutputRoot $testRoot -RunId 'TEST')
        [void](Write-Btc15mCaptureBundle -Events $events -OutputDirectory $secondOutput -AllowedOutputRoot $testRoot -RunId 'TEST')
        foreach ($fileName in @('raw_events.jsonl', 'raw_event_schema.json', 'summary.json', 'manifest.json')) {
            $firstHash = Get-Btc15mSha256File -Path (Join-Path $firstOutput $fileName)
            $secondHash = Get-Btc15mSha256File -Path (Join-Path $secondOutput $fileName)
            Assert-Btc15mEqual -Actual $firstHash -Expected $secondHash -Message "Deterministic bundle hash mismatch for $fileName."
        }
    }
    finally {
        if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
    }
}

Invoke-Btc15mTest -Name '19_ROLLBACK_REMOVES_NEW_BUNDLE_AFTER_INVALID_EVENT_FAILURE' -Body {
    $testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('btc15m-rollback-' + [Guid]::NewGuid().ToString('N'))
    [void][System.IO.Directory]::CreateDirectory($testRoot)
    try {
        $output = Join-Path $testRoot 'bundle'
        Assert-Btc15mThrowsLike -Action {
            [void](Write-Btc15mCaptureBundle -Events @([pscustomobject]@{ auxiliary = 'not-an-event' }) -OutputDirectory $output -AllowedOutputRoot $testRoot -RunId 'TEST')
        } -ExpectedFragments @(
            'RAW_EVENT_SHAPE_INVALID',
            'boundary=Select-Btc15mUniqueEvents',
            'index=0',
            'missing=source'
        ) -Message 'Invalid event did not fail through the event-shape validator.'
        Assert-Btc15mTrue -Condition (-not (Test-Path -LiteralPath $output)) -Message 'Rollback did not remove the newly created bundle directory.'
    }
    finally {
        if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
    }
}

Invoke-Btc15mTest -Name '20_TEST_SUITE_REMAINS_OFFLINE' -Body {
    $testContent = [System.IO.File]::ReadAllText($PSCommandPath)
    $liveCaptureName = 'Invoke-Btc15mLive' + 'BoundedCapture'
    $allowNetworkToken = '-Allow' + 'Network'
    $connectAsyncToken = '.Connect' + 'Async('
    Assert-Btc15mTrue -Condition (-not [regex]::IsMatch($testContent, "(?m)^\s*&?\s*$liveCaptureName\b")) -Message 'Test suite invokes live bounded capture.'
    Assert-Btc15mTrue -Condition (-not [regex]::IsMatch($testContent, "(?m)^\s*&?\s*.+\s$allowNetworkToken\b")) -Message 'Test suite enables network.'
    Assert-Btc15mTrue -Condition ($testContent.IndexOf($connectAsyncToken, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) -Message 'Test suite opens WebSocket connections.'
}

Invoke-Btc15mTest -Name '21_DIRECT_NULL_ARGUMENT_HAS_STRUCTURED_DOMAIN_DIAGNOSTIC' -Body {
    $commandInfo = Get-Command -Name 'Select-Btc15mUniqueEvents' -CommandType Function -ErrorAction Stop
    Assert-Btc15mTrue -Condition ($null -ne $commandInfo) -Message 'Select-Btc15mUniqueEvents function is missing.'
    $eventsParameter = $commandInfo.Parameters['Events']
    Assert-Btc15mTrue -Condition ($null -ne $eventsParameter) -Message 'Events parameter is missing.'
    $parameterAttributes = @($eventsParameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] })
    Assert-Btc15mTrue -Condition ($parameterAttributes.Count -gt 0) -Message 'Events parameter has no ParameterAttribute metadata.'
    Assert-Btc15mTrue -Condition (@($parameterAttributes | Where-Object { $_.Mandatory }).Count -gt 0) -Message 'Events parameter is not marked Mandatory.'

    Assert-Btc15mThrowsLike -Action {
        [void](Select-Btc15mUniqueEvents -Events $null)
    } -ExpectedFragments @(
        'RAW_EVENT_SHAPE_INVALID',
        'boundary=Select-Btc15mUniqueEvents',
        'index=0',
        'type=<null>',
        'missing=source',
        'properties='
    ) -Message 'Direct null argument did not produce the structured domain diagnostic.'
}

Invoke-Btc15mTest -Name '22_NULL_ELEMENT_IN_MIXED_COLLECTION_PRESERVES_REAL_INDEX' -Body {
    $chainlinkEvent = ConvertFrom-Btc15mChainlinkMessage -RawJson $chainlinkJson -RunId 'TEST' -CollectorReceiveTimestampMs 1700000000600 -CollectorSequence 1 -ConnectionId 'C'
    $binanceEvent = ConvertFrom-Btc15mBinanceAggTradeMessage -RawJson $binanceJson -RunId 'TEST' -CollectorReceiveTimestampMs 1700000000500 -CollectorSequence 2 -ConnectionId 'B'
    Assert-Btc15mThrowsLike -Action {
        [void](Select-Btc15mUniqueEvents -Events @($chainlinkEvent, $null, $binanceEvent))
    } -ExpectedFragments @(
        'RAW_EVENT_SHAPE_INVALID',
        'boundary=Select-Btc15mUniqueEvents',
        'index=1',
        'type=<null>',
        'missing=source',
        'properties='
    ) -Message 'Null element did not preserve its real mixed-collection index.'
}

Invoke-Btc15mTest -Name '23_EXPLICIT_EMPTY_COLLECTION_REMAINS_ZERO_ELEMENTS' -Body {
    $emptyEvents = [object[]]@()
    $unique = @(Select-Btc15mUniqueEvents -Events $emptyEvents)
    Assert-Btc15mEqual -Actual $unique.Count -Expected 0 -Message 'Explicit empty collection did not remain zero elements.'
}

Invoke-Btc15mTest -Name '24_NULL_EVENT_BUNDLE_FAILURE_PRESERVES_ROLLBACK' -Body {
    $testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('btc15m-null-rollback-' + [Guid]::NewGuid().ToString('N'))
    [void][System.IO.Directory]::CreateDirectory($testRoot)
    try {
        $output = Join-Path $testRoot 'bundle'
        $eventItem = ConvertFrom-Btc15mChainlinkMessage -RawJson $chainlinkJson -RunId 'TEST' -CollectorReceiveTimestampMs 1700000000600 -CollectorSequence 1 -ConnectionId 'C'
        Assert-Btc15mThrowsLike -Action {
            [void](Write-Btc15mCaptureBundle -Events @($eventItem, $null) -OutputDirectory $output -AllowedOutputRoot $testRoot -RunId 'TEST')
        } -ExpectedFragments @(
            'RAW_EVENT_SHAPE_INVALID',
            'boundary=Select-Btc15mUniqueEvents',
            'index=1',
            'type=<null>',
            'missing=source'
        ) -Message 'Null event bundle failure did not preserve the shape diagnostic.'
        Assert-Btc15mTrue -Condition (-not (Test-Path -LiteralPath $output)) -Message 'Rollback did not remove the newly created bundle directory after null-event failure.'
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
