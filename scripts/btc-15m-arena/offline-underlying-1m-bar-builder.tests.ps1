[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BarBuilderScriptPath,
    [Parameter(Mandatory)][string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $BarBuilderScriptPath -PathType Leaf)) {
    throw "Bar builder script missing: $BarBuilderScriptPath"
}
if (-not (Test-Path -LiteralPath $RepoRoot -PathType Container)) {
    throw "Repository root missing: $RepoRoot"
}

. $BarBuilderScriptPath

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

function New-Btc15mTestRawEvent {
    param(
        [string]$Source = 'CHAINLINK_BTC_USD',
        [string]$Symbol = 'btc/usd',
        [long]$SourceTimestampMs,
        [long]$CollectorReceiveTimestampMs,
        [long]$CollectorSequence,
        [string]$Value = '100.0',
        [long]$AggregateTradeId = 0,
        [string]$HashCharacter = 'a'
    )

    $aggregateIdValue = if ($Source -ceq 'BINANCE_BTCUSDT') { [Nullable[long]]$AggregateTradeId } else { $null }
    $quantityValue = if ($Source -ceq 'BINANCE_BTCUSDT') { '0.001' } else { $null }
    $buyerMakerValue = if ($Source -ceq 'BINANCE_BTCUSDT') { [Nullable[bool]]$true } else { $null }
    $rawJson = if ($Source -ceq 'BINANCE_BTCUSDT') { '{"source":"binance"}' } else { '{"source":"chainlink"}' }

    return [pscustomobject][ordered]@{
        schema_version = 'BTC15M_UNDERLYING_RAW_EVENT_V1'
        run_id = 'TEST_RUN'
        source = $Source
        symbol = $Symbol
        source_timestamp_ms = $SourceTimestampMs
        event_timestamp_ms = $SourceTimestampMs
        collector_receive_timestamp_ms = $CollectorReceiveTimestampMs
        collector_sequence = $CollectorSequence
        connection_id = 'TEST_CONNECTION'
        value_decimal_string = $Value
        raw_payload_sha256 = ($HashCharacter * 64)
        raw_payload_json = $rawJson
        quantity_decimal_string = $quantityValue
        aggregate_trade_id = $aggregateIdValue
        first_trade_id = $aggregateIdValue
        last_trade_id = $aggregateIdValue
        buyer_is_maker = $buyerMakerValue
    }
}

function Write-Btc15mTestRawFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Events
    )

    $lines = @($Events | ForEach-Object { $_ | ConvertTo-Json -Depth 20 -Compress })
    $text = ($lines -join "`n") + "`n"
    [System.IO.File]::WriteAllText($Path, $text, [System.Text.UTF8Encoding]::new($false))
}

Invoke-Btc15mTest -Name '12_UTC_MINUTE_FLOOR_EXACTNESS' -Body {
    Assert-Btc15mEqual -Actual (Get-Btc15mUtcMinuteStartMs -TimestampMs 1700000039999) -Expected 1699999980000L -Message 'UTC minute floor mismatch.'
    Assert-Btc15mEqual -Actual (Get-Btc15mUtcMinuteStartMs -TimestampMs 1700000040000) -Expected 1700000040000L -Message 'Exact minute boundary changed.'
}

Invoke-Btc15mTest -Name '13_OHLC_SOURCE_TIMESTAMP_ORDER_EXACTNESS' -Body {
    $open = 1700000040000L
    $events = @(
        New-Btc15mTestRawEvent -SourceTimestampMs ($open + 1000) -CollectorReceiveTimestampMs ($open + 1100) -CollectorSequence 1 -Value '100.0' -HashCharacter 'a'
        New-Btc15mTestRawEvent -SourceTimestampMs ($open + 2000) -CollectorReceiveTimestampMs ($open + 2100) -CollectorSequence 2 -Value '105.0' -HashCharacter 'b'
        New-Btc15mTestRawEvent -SourceTimestampMs ($open + 3000) -CollectorReceiveTimestampMs ($open + 3100) -CollectorSequence 3 -Value '95.0' -HashCharacter 'c'
        New-Btc15mTestRawEvent -SourceTimestampMs ($open + 4000) -CollectorReceiveTimestampMs ($open + 4100) -CollectorSequence 4 -Value '102.0' -HashCharacter 'd'
    )
    $result = New-Btc15mUnderlyingBars -Events $events -CutoffTimestampMs ($open + 60000) -DatasetId 'TEST'
    Assert-Btc15mEqual -Actual $result.bars.Count -Expected 1 -Message 'Expected one bar.'
    $bar = $result.bars[0]
    Assert-Btc15mEqual -Actual $bar.open_decimal_string -Expected '100.0' -Message 'Open mismatch.'
    Assert-Btc15mEqual -Actual $bar.high_decimal_string -Expected '105.0' -Message 'High mismatch.'
    Assert-Btc15mEqual -Actual $bar.low_decimal_string -Expected '95.0' -Message 'Low mismatch.'
    Assert-Btc15mEqual -Actual $bar.close_decimal_string -Expected '102.0' -Message 'Close mismatch.'
}

Invoke-Btc15mTest -Name '14_DUPLICATE_EVENTS_DO_NOT_CHANGE_BAR' -Body {
    $open = 1700000040000L
    $eventItem = New-Btc15mTestRawEvent -SourceTimestampMs ($open + 1000) -CollectorReceiveTimestampMs ($open + 1100) -CollectorSequence 1 -Value '100.0'
    $single = New-Btc15mUnderlyingBars -Events @($eventItem) -CutoffTimestampMs ($open + 60000) -DatasetId 'TEST'
    $duplicated = New-Btc15mUnderlyingBars -Events @($eventItem, $eventItem) -CutoffTimestampMs ($open + 60000) -DatasetId 'TEST'
    Assert-Btc15mEqual -Actual $duplicated.bars.Count -Expected $single.bars.Count -Message 'Duplicate changed bar count.'
    Assert-Btc15mEqual -Actual $duplicated.bars[0].event_count -Expected 1 -Message 'Duplicate changed event count.'
    Assert-Btc15mEqual -Actual $duplicated.duplicate_count -Expected 1 -Message 'Duplicate count mismatch.'
}

Invoke-Btc15mTest -Name '15_MISSING_MINUTE_REMAINS_MISSING' -Body {
    $open = 1700000040000L
    $events = @(
        New-Btc15mTestRawEvent -SourceTimestampMs ($open + 1000) -CollectorReceiveTimestampMs ($open + 1100) -CollectorSequence 1 -Value '100.0' -HashCharacter 'a'
        New-Btc15mTestRawEvent -SourceTimestampMs ($open + 121000) -CollectorReceiveTimestampMs ($open + 121100) -CollectorSequence 2 -Value '101.0' -HashCharacter 'b'
    )
    $result = New-Btc15mUnderlyingBars -Events $events -CutoffTimestampMs ($open + 180000) -DatasetId 'TEST'
    Assert-Btc15mEqual -Actual $result.bars.Count -Expected 2 -Message 'Missing minute was forward-filled.'
    Assert-Btc15mEqual -Actual $result.bars[1].gap_status -Expected 'GAP_BEFORE' -Message 'Gap was not marked.'
    Assert-Btc15mEqual -Actual ([long]$result.bars[1].bar_open_timestamp_ms) -Expected ($open + 120000) -Message 'Unexpected bar minute.'
}

Invoke-Btc15mTest -Name '16_CURRENT_PARTIAL_MINUTE_EXCLUDED' -Body {
    $open = 1700000040000L
    $closedEvent = New-Btc15mTestRawEvent -SourceTimestampMs ($open + 1000) -CollectorReceiveTimestampMs ($open + 1100) -CollectorSequence 1 -Value '100.0' -HashCharacter 'a'
    $partialEvent = New-Btc15mTestRawEvent -SourceTimestampMs ($open + 61000) -CollectorReceiveTimestampMs ($open + 61100) -CollectorSequence 2 -Value '101.0' -HashCharacter 'b'
    $result = New-Btc15mUnderlyingBars -Events @($closedEvent, $partialEvent) -CutoffTimestampMs ($open + 60000) -DatasetId 'TEST'
    Assert-Btc15mEqual -Actual $result.bars.Count -Expected 1 -Message 'Partial minute produced a bar.'
    Assert-Btc15mEqual -Actual $result.partial_event_count_excluded -Expected 1 -Message 'Partial exclusion count mismatch.'
}

Invoke-Btc15mTest -Name '17_LATE_EVENT_POLICY_DETERMINISTIC' -Body {
    $open = 1700000040000L
    $onTime = New-Btc15mTestRawEvent -SourceTimestampMs ($open + 1000) -CollectorReceiveTimestampMs ($open + 2000) -CollectorSequence 1 -Value '100.0' -HashCharacter 'a'
    $late = New-Btc15mTestRawEvent -SourceTimestampMs ($open + 2000) -CollectorReceiveTimestampMs ($open + 66001) -CollectorSequence 2 -Value '999.0' -HashCharacter 'b'
    $first = New-Btc15mUnderlyingBars -Events @($onTime, $late) -CutoffTimestampMs ($open + 60000) -AllowedLatenessMs 5000 -DatasetId 'TEST'
    $second = New-Btc15mUnderlyingBars -Events @($onTime, $late) -CutoffTimestampMs ($open + 60000) -AllowedLatenessMs 5000 -DatasetId 'TEST'
    Assert-Btc15mEqual -Actual $first.late_event_count_excluded -Expected 1 -Message 'Late event was not excluded.'
    Assert-Btc15mEqual -Actual $first.bars[0].close_decimal_string -Expected '100.0' -Message 'Late event changed close.'
    Assert-Btc15mEqual -Actual (ConvertTo-Btc15mCanonicalJson -InputObject $first -Depth 30) -Expected (ConvertTo-Btc15mCanonicalJson -InputObject $second -Depth 30) -Message 'Late-event policy is not deterministic.'
}

Invoke-Btc15mTest -Name '18_CHAINLINK_AND_BINANCE_BARS_REMAIN_SEPARATE' -Body {
    $open = 1700000040000L
    $chainlink = New-Btc15mTestRawEvent -Source 'CHAINLINK_BTC_USD' -Symbol 'btc/usd' -SourceTimestampMs ($open + 1000) -CollectorReceiveTimestampMs ($open + 1100) -CollectorSequence 1 -Value '100.0' -HashCharacter 'a'
    $binance = New-Btc15mTestRawEvent -Source 'BINANCE_BTCUSDT' -Symbol 'BTCUSDT' -SourceTimestampMs ($open + 1000) -CollectorReceiveTimestampMs ($open + 1100) -CollectorSequence 2 -Value '101.0' -AggregateTradeId 10 -HashCharacter 'b'
    $result = New-Btc15mUnderlyingBars -Events @($chainlink, $binance) -CutoffTimestampMs ($open + 60000) -DatasetId 'TEST'
    Assert-Btc15mEqual -Actual $result.bars.Count -Expected 2 -Message 'Sources were merged into one bar.'
    Assert-Btc15mEqual -Actual (@($result.bars | Where-Object { $_.source -ceq 'CHAINLINK_BTC_USD' }).Count) -Expected 1 -Message 'Chainlink bar missing.'
    Assert-Btc15mEqual -Actual (@($result.bars | Where-Object { $_.source -ceq 'BINANCE_BTCUSDT' }).Count) -Expected 1 -Message 'Binance bar missing.'
}

Invoke-Btc15mTest -Name '19_WARMUP_REQUIRES_120_COMPLETE_CHAINLINK_BARS' -Body {
    $open = 1699999980000L
    $events119 = @()
    $hexCharacters = '0123456789abcdef'
    for ($index = 0; $index -lt 119; $index++) {
        $minute = $open + ($index * 60000L)
        $hashCharacter = [string]$hexCharacters[$index % $hexCharacters.Length]
        $events119 += New-Btc15mTestRawEvent -SourceTimestampMs ($minute + 1000) -CollectorReceiveTimestampMs ($minute + 1100) -CollectorSequence ($index + 1) -Value ('{0}.0' -f (100 + $index)) -HashCharacter $hashCharacter
    }
    $result119 = New-Btc15mUnderlyingBars -Events $events119 -CutoffTimestampMs ($open + 119 * 60000L) -DatasetId 'TEST'
    Assert-Btc15mEqual -Actual $result119.chainlink_warmup_ready -Expected $false -Message '119 bars incorrectly passed warmup.'

    $minute120 = $open + (119 * 60000L)
    $events120 = @($events119 + (New-Btc15mTestRawEvent -SourceTimestampMs ($minute120 + 1000) -CollectorReceiveTimestampMs ($minute120 + 1100) -CollectorSequence 120 -Value '219.0' -HashCharacter 'f'))
    $result120 = New-Btc15mUnderlyingBars -Events $events120 -CutoffTimestampMs ($open + 120 * 60000L) -DatasetId 'TEST'
    Assert-Btc15mEqual -Actual $result120.chainlink_bar_count -Expected 120 -Message '120 bar count mismatch.'
    Assert-Btc15mEqual -Actual $result120.chainlink_warmup_ready -Expected $true -Message '120 contiguous bars did not pass warmup.'
}

Invoke-Btc15mTest -Name '20_MANIFEST_HASH_SIZE_AND_LINE_COUNT_EXACTNESS' -Body {
    $root = Join-Path ([System.IO.Path]::GetTempPath()) ('btc15m-bars-manifest-' + [Guid]::NewGuid().ToString('N'))
    [void][System.IO.Directory]::CreateDirectory($root)
    try {
        $rawPath = Join-Path $root 'raw.jsonl'
        $open = 1700000040000L
        $events = @(
            New-Btc15mTestRawEvent -SourceTimestampMs ($open + 1000) -CollectorReceiveTimestampMs ($open + 1100) -CollectorSequence 1 -Value '100.0' -HashCharacter 'a'
            New-Btc15mTestRawEvent -SourceTimestampMs ($open + 2000) -CollectorReceiveTimestampMs ($open + 2100) -CollectorSequence 2 -Value '101.0' -HashCharacter 'b'
        )
        Write-Btc15mTestRawFile -Path $rawPath -Events $events
        $output = Join-Path $root 'bundle'
        [void](Write-Btc15mBarBundle -RawEventsPath $rawPath -OutputDirectory $output -AllowedOutputRoot $root -DatasetId 'TEST_DATASET' -CutoffTimestampMs ($open + 60000))
        $manifest = (Get-Content -LiteralPath (Join-Path $output 'manifest.json') -Raw) | ConvertFrom-Json -Depth 20
        Assert-Btc15mEqual -Actual @($manifest.files).Count -Expected 3 -Message 'Manifest file count mismatch.'
        foreach ($entry in @($manifest.files)) {
            $path = Join-Path $output $entry.file_name
            Assert-Btc15mEqual -Actual $entry.sha256 -Expected (Get-Btc15mSha256File -Path $path) -Message "Manifest hash mismatch: $($entry.file_name)"
            Assert-Btc15mEqual -Actual ([long]$entry.bytes) -Expected ([System.IO.FileInfo]::new($path).Length) -Message "Manifest byte count mismatch: $($entry.file_name)"
            Assert-Btc15mEqual -Actual ([long]$entry.cr_count) -Expected 0L -Message "CR detected: $($entry.file_name)"
            Assert-Btc15mEqual -Actual ([bool]$entry.utf8_bom) -Expected $false -Message "BOM detected: $($entry.file_name)"
        }
    }
    finally {
        if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
    }
}

Invoke-Btc15mTest -Name '21_REPEATED_OFFLINE_BUILD_BYTE_IDENTICAL' -Body {
    $root = Join-Path ([System.IO.Path]::GetTempPath()) ('btc15m-bars-repeat-' + [Guid]::NewGuid().ToString('N'))
    [void][System.IO.Directory]::CreateDirectory($root)
    try {
        $rawPath = Join-Path $root 'raw.jsonl'
        $open = 1700000040000L
        $events = @(
            New-Btc15mTestRawEvent -SourceTimestampMs ($open + 1000) -CollectorReceiveTimestampMs ($open + 1100) -CollectorSequence 1 -Value '100.0' -HashCharacter 'a'
            New-Btc15mTestRawEvent -SourceTimestampMs ($open + 2000) -CollectorReceiveTimestampMs ($open + 2100) -CollectorSequence 2 -Value '101.0' -HashCharacter 'b'
        )
        Write-Btc15mTestRawFile -Path $rawPath -Events $events
        $outputA = Join-Path $root 'bundle-a'
        $outputB = Join-Path $root 'bundle-b'
        [void](Write-Btc15mBarBundle -RawEventsPath $rawPath -OutputDirectory $outputA -AllowedOutputRoot $root -DatasetId 'TEST_DATASET' -CutoffTimestampMs ($open + 60000))
        [void](Write-Btc15mBarBundle -RawEventsPath $rawPath -OutputDirectory $outputB -AllowedOutputRoot $root -DatasetId 'TEST_DATASET' -CutoffTimestampMs ($open + 60000))
        foreach ($name in @('underlying_1m_bars.csv', 'bar_schema.json', 'summary.json', 'manifest.json')) {
            Assert-Btc15mEqual -Actual (Get-Btc15mSha256File -Path (Join-Path $outputA $name)) -Expected (Get-Btc15mSha256File -Path (Join-Path $outputB $name)) -Message "Repeated build differs: $name"
        }
    }
    finally {
        if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
    }
}

Invoke-Btc15mTest -Name '22_OFFICIAL_SCORER_AND_REPLAY_HASHES_UNCHANGED' -Body {
    $definitions = @(
        [pscustomobject]@{ Path = (Join-Path $RepoRoot 'scripts\btc-15m-arena\offline-official-outcome-directional-scoring.ps1'); Hash = 'de7186d2e88ae7e89eb7c1edf67f1aad2b9eb39375f2bcec2128ecacd8577e2d' },
        [pscustomobject]@{ Path = (Join-Path $RepoRoot 'scripts\btc-15m-arena\offline-official-outcome-directional-scoring.tests.ps1'); Hash = '70bc52b050015c50a9838df0a4c51e5855aa7443a907ee01cd50170222d05e72' },
        [pscustomobject]@{ Path = (Join-Path $RepoRoot 'scripts\btc-15m-arena\offline-derived-replay-simulation.ps1'); Hash = '8de6297abda9ab14042f6a613bdbb5eec1575704e30a7e746f5b91cdfa310d02' },
        [pscustomobject]@{ Path = (Join-Path $RepoRoot 'scripts\btc-15m-arena\offline-derived-replay-simulation.tests.ps1'); Hash = 'bc509f3108ec591eccf4689a1b7d77b110e035020d826705970910be03610901' }
    )
    foreach ($definition in $definitions) {
        Assert-Btc15mTrue -Condition (Test-Path -LiteralPath $definition.Path -PathType Leaf) -Message "Protected file missing: $($definition.Path)"
        Assert-Btc15mEqual -Actual (Get-Btc15mSha256File -Path $definition.Path) -Expected $definition.Hash -Message "Protected file hash changed: $($definition.Path)"
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
