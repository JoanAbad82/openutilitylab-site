[CmdletBinding()]
param(
    [ValidateSet('PlanOnly', 'Fixture', 'LiveBounded')]
    [string]$Mode = 'PlanOnly',

    [string]$OutputDirectory,
    [string]$AllowedOutputRoot,
    [string]$RunId = 'BTC15M_CAPTURE_MANUAL',
    [string]$ChainlinkFixturePath,
    [string]$BinanceFixturePath,
    [int]$MaxChainlinkEvents = 3,
    [int]$MaxBinanceEvents = 10,
    [int]$TimeoutSeconds = 25,
    [switch]$AllowNetwork
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Btc15mRawSchemaVersion = 'BTC15M_UNDERLYING_RAW_EVENT_V1'
$script:Btc15mCaptureContractVersion = 'BTC15M_CHAINLINK_BINANCE_CAPTURE_V1'
$script:Btc15mChainlinkEndpoint = 'wss://ws-live-data.polymarket.com'
$script:Btc15mBinanceEndpoint = 'wss://data-stream.binance.vision/ws/btcusdt@aggTrade'
$script:Btc15mBinanceRepairBaseUri = 'https://data-api.binance.vision/api/v3/aggTrades'
$script:Btc15mAutomaticFallback = 'FORBIDDEN'
$script:Btc15mUtf8NoBom = [System.Text.UTF8Encoding]::new($false)

function ConvertTo-Btc15mLf {
    [CmdletBinding()]
    param([AllowEmptyString()][string]$Text)

    if ($null -eq $Text) { return '' }
    return ($Text -replace "`r`n", "`n" -replace "`r", "`n")
}

function Get-Btc15mSha256Bytes {
    [CmdletBinding()]
    param([Parameter(Mandatory)][byte[]]$Bytes)

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([Convert]::ToHexString($sha.ComputeHash($Bytes))).ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
    }
}

function Get-Btc15mSha256Text {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)

    return Get-Btc15mSha256Bytes -Bytes ([System.Text.Encoding]::UTF8.GetBytes($Text))
}

function Get-Btc15mSha256File {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    $stream = [System.IO.File]::OpenRead($Path)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([Convert]::ToHexString($sha.ComputeHash($stream))).ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
        $stream.Dispose()
    }
}

function ConvertTo-Btc15mCanonicalJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$InputObject,
        [int]$Depth = 20
    )

    return ConvertTo-Btc15mLf -Text ($InputObject | ConvertTo-Json -Depth $Depth -Compress)
}

function Write-Btc15mUtf8LfAtomic {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Text
    )

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        [void][System.IO.Directory]::CreateDirectory($parent)
    }

    $normalized = ConvertTo-Btc15mLf -Text $Text
    $temporaryPath = '{0}.tmp-{1}' -f $Path, [Guid]::NewGuid().ToString('N')
    try {
        [System.IO.File]::WriteAllText($temporaryPath, $normalized, $script:Btc15mUtf8NoBom)
        if (Test-Path -LiteralPath $Path) {
            throw "Refusing to overwrite existing file: $Path"
        }
        [System.IO.File]::Move($temporaryPath, $Path)
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
}

function Test-Btc15mChildPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CandidatePath,
        [Parameter(Mandatory)][string]$AllowedRoot
    )

    $candidate = [System.IO.Path]::GetFullPath($CandidatePath)
    $root = [System.IO.Path]::GetFullPath($AllowedRoot)
    $separator = [System.IO.Path]::DirectorySeparatorChar
    $rootWithSeparator = $root.TrimEnd([char[]]@('/', '\')) + $separator

    return $candidate.StartsWith($rootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)
}

function Assert-Btc15mOutputBoundary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CandidatePath,
        [Parameter(Mandatory)][string]$AllowedRoot
    )

    if (-not (Test-Btc15mChildPath -CandidatePath $CandidatePath -AllowedRoot $AllowedRoot)) {
        throw "Output path is outside the authorized root. candidate=$CandidatePath root=$AllowedRoot"
    }
}

function Get-Btc15mCanonicalCaptureRoot {
    [CmdletBinding()]
    param()

    return Join-Path $env:USERPROFILE 'Documents\BTC_15M_ARENA_OPERATIONS\20_RUNS\CHAINLINK_BINANCE_CAPTURE'
}

function ConvertTo-Btc15mPositiveDecimalString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Value,
        [Parameter(Mandatory)][string]$FieldName
    )

    $parsed = [decimal]::Zero
    if (-not [decimal]::TryParse(
        $Value,
        [System.Globalization.NumberStyles]::Float,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [ref]$parsed
    )) {
        throw "Invalid decimal in ${FieldName}: $Value"
    }
    if ($parsed -le [decimal]::Zero) {
        throw "Expected positive decimal in ${FieldName}: $Value"
    }
    return $Value
}

function New-Btc15mChainlinkSubscriptionJson {
    [CmdletBinding()]
    param()

    $subscription = [ordered]@{
        action = 'subscribe'
        subscriptions = @(
            [ordered]@{
                topic = 'crypto_prices_chainlink'
                type = '*'
                filters = '{"symbol":"btc/usd"}'
            }
        )
    }
    return ConvertTo-Btc15mCanonicalJson -InputObject $subscription -Depth 6
}

function Get-Btc15mCaptureContract {
    [CmdletBinding()]
    param()

    return [pscustomobject][ordered]@{
        contract_version = $script:Btc15mCaptureContractVersion
        raw_schema_version = $script:Btc15mRawSchemaVersion
        primary_feature_source = 'CHAINLINK_BTC_USD'
        secondary_diagnostic_source = 'BINANCE_BTCUSDT'
        automatic_source_fallback = $script:Btc15mAutomaticFallback
        chainlink_endpoint = $script:Btc15mChainlinkEndpoint
        binance_endpoint = $script:Btc15mBinanceEndpoint
        chainlink_authentication = 'NONE'
        binance_authentication = 'NONE'
        direct_chainlink_data_streams_api = 'EXCLUDED_FROM_V1'
        binance_private_api_required = $false
        decimal_representation = 'STRING'
        timestamp_unit = 'UNIX_MILLISECONDS_UTC'
        raw_format = 'UTF8_NO_BOM_LF_JSONL'
        promotion = 'SEPARATE_EXPLICIT_PHASE_ONLY'
        canonical_output_root = Get-Btc15mCanonicalCaptureRoot
    }
}

function New-Btc15mRawEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Symbol,
        [Parameter(Mandatory)][long]$SourceTimestampMs,
        [Parameter(Mandatory)][long]$EventTimestampMs,
        [Parameter(Mandatory)][long]$CollectorReceiveTimestampMs,
        [Parameter(Mandatory)][long]$CollectorSequence,
        [Parameter(Mandatory)][string]$ConnectionId,
        [Parameter(Mandatory)][string]$ValueDecimalString,
        [Parameter(Mandatory)][string]$RawPayloadJson,
        [AllowNull()][AllowEmptyString()][string]$QuantityDecimalString,
        [AllowNull()][Nullable[long]]$AggregateTradeId,
        [AllowNull()][Nullable[long]]$FirstTradeId,
        [AllowNull()][Nullable[long]]$LastTradeId,
        [AllowNull()][Nullable[bool]]$BuyerIsMaker
    )

    if ($SourceTimestampMs -le 0 -or $EventTimestampMs -le 0 -or $CollectorReceiveTimestampMs -le 0) {
        throw 'All timestamps must be positive UNIX milliseconds.'
    }
    if ($CollectorSequence -le 0) {
        throw 'collector_sequence must be positive.'
    }

    [void](ConvertTo-Btc15mPositiveDecimalString -Value $ValueDecimalString -FieldName 'value_decimal_string')

    $normalizedQuantityDecimalString = $null
    if (-not [string]::IsNullOrWhiteSpace($QuantityDecimalString)) {
        [void](ConvertTo-Btc15mPositiveDecimalString -Value $QuantityDecimalString -FieldName 'quantity_decimal_string')
        $normalizedQuantityDecimalString = $QuantityDecimalString
    }
    elseif ($Source -ceq 'BINANCE_BTCUSDT') {
        throw 'quantity_decimal_string is required and must be positive for BINANCE_BTCUSDT.'
    }

    return [pscustomobject][ordered]@{
        schema_version = $script:Btc15mRawSchemaVersion
        run_id = $RunId
        source = $Source
        symbol = $Symbol
        source_timestamp_ms = $SourceTimestampMs
        event_timestamp_ms = $EventTimestampMs
        collector_receive_timestamp_ms = $CollectorReceiveTimestampMs
        collector_sequence = $CollectorSequence
        connection_id = $ConnectionId
        value_decimal_string = $ValueDecimalString
        raw_payload_sha256 = Get-Btc15mSha256Text -Text $RawPayloadJson
        raw_payload_json = $RawPayloadJson
        quantity_decimal_string = $normalizedQuantityDecimalString
        aggregate_trade_id = $AggregateTradeId
        first_trade_id = $FirstTradeId
        last_trade_id = $LastTradeId
        buyer_is_maker = $BuyerIsMaker
    }
}

function ConvertFrom-Btc15mChainlinkMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RawJson,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][long]$CollectorReceiveTimestampMs,
        [Parameter(Mandatory)][long]$CollectorSequence,
        [Parameter(Mandatory)][string]$ConnectionId
    )

    $parsed = $RawJson | ConvertFrom-Json -Depth 20
    $topNames = @($parsed.PSObject.Properties.Name)
    foreach ($requiredName in @('topic', 'type', 'timestamp', 'payload')) {
        if ($topNames -notcontains $requiredName) {
            throw "Chainlink message missing property: $requiredName"
        }
    }
    if ($null -eq $parsed.payload) {
        throw 'Chainlink payload is null.'
    }
    $payloadNames = @($parsed.payload.PSObject.Properties.Name)
    foreach ($requiredName in @('symbol', 'timestamp', 'value')) {
        if ($payloadNames -notcontains $requiredName) {
            throw "Chainlink payload missing property: $requiredName"
        }
    }
    if ([string]$parsed.topic -cne 'crypto_prices_chainlink') {
        throw "Unexpected Chainlink topic: $($parsed.topic)"
    }
    if ([string]$parsed.payload.symbol -ine 'btc/usd') {
        throw "Unexpected Chainlink symbol: $($parsed.payload.symbol)"
    }

    return New-Btc15mRawEvent `
        -RunId $RunId `
        -Source 'CHAINLINK_BTC_USD' `
        -Symbol 'btc/usd' `
        -SourceTimestampMs ([long]$parsed.payload.timestamp) `
        -EventTimestampMs ([long]$parsed.timestamp) `
        -CollectorReceiveTimestampMs $CollectorReceiveTimestampMs `
        -CollectorSequence $CollectorSequence `
        -ConnectionId $ConnectionId `
        -ValueDecimalString ([string]$parsed.payload.value) `
        -RawPayloadJson $RawJson
}

function ConvertFrom-Btc15mBinanceAggTradeMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RawJson,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][long]$CollectorReceiveTimestampMs,
        [Parameter(Mandatory)][long]$CollectorSequence,
        [Parameter(Mandatory)][string]$ConnectionId
    )

    $document = [System.Text.Json.JsonDocument]::Parse($RawJson)
    try {
        $root = $document.RootElement
        if ($root.ValueKind -ne [System.Text.Json.JsonValueKind]::Object) {
            throw 'Binance aggTrade root is not an object.'
        }

        $eventType = $root.GetProperty('e').GetString()
        $eventTimestampMs = $root.GetProperty('E').GetInt64()
        $symbol = $root.GetProperty('s').GetString()
        $aggregateTradeId = $root.GetProperty('a').GetInt64()
        $price = $root.GetProperty('p').GetString()
        $quantity = $root.GetProperty('q').GetString()
        $firstTradeId = $root.GetProperty('f').GetInt64()
        $lastTradeId = $root.GetProperty('l').GetInt64()
        $tradeTimestampMs = $root.GetProperty('T').GetInt64()
        $buyerIsMaker = $root.GetProperty('m').GetBoolean()
        [void]$root.GetProperty('M').GetBoolean()

        if ($eventType -cne 'aggTrade') {
            throw "Unexpected Binance event type: $eventType"
        }
        if ($symbol -cne 'BTCUSDT') {
            throw "Unexpected Binance symbol: $symbol"
        }
        if ($aggregateTradeId -lt 0 -or $firstTradeId -lt 0 -or $lastTradeId -lt $firstTradeId) {
            throw 'Invalid Binance aggregate trade identifiers.'
        }

        return New-Btc15mRawEvent `
            -RunId $RunId `
            -Source 'BINANCE_BTCUSDT' `
            -Symbol 'BTCUSDT' `
            -SourceTimestampMs $tradeTimestampMs `
            -EventTimestampMs $eventTimestampMs `
            -CollectorReceiveTimestampMs $CollectorReceiveTimestampMs `
            -CollectorSequence $CollectorSequence `
            -ConnectionId $ConnectionId `
            -ValueDecimalString $price `
            -RawPayloadJson $RawJson `
            -QuantityDecimalString $quantity `
            -AggregateTradeId $aggregateTradeId `
            -FirstTradeId $firstTradeId `
            -LastTradeId $lastTradeId `
            -BuyerIsMaker $buyerIsMaker
    }
    finally {
        $document.Dispose()
    }
}

function Get-Btc15mBinanceMessageDiagnostic {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RawJson,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][long]$CollectorReceiveTimestampMs,
        [Parameter(Mandatory)][long]$CollectorSequence,
        [Parameter(Mandatory)][string]$ConnectionId
    )

    $rawHash = Get-Btc15mSha256Text -Text $RawJson
    try {
        $event = ConvertFrom-Btc15mBinanceAggTradeMessage `
            -RawJson $RawJson `
            -RunId $RunId `
            -CollectorReceiveTimestampMs $CollectorReceiveTimestampMs `
            -CollectorSequence $CollectorSequence `
            -ConnectionId $ConnectionId

        return [pscustomobject][ordered]@{
            result = 'PASS'
            raw_payload_sha256 = $rawHash
            raw_payload_length_bytes = [System.Text.Encoding]::UTF8.GetByteCount($RawJson)
            parse_error_type = $null
            parse_error_message = $null
            event = $event
        }
    }
    catch {
        return [pscustomobject][ordered]@{
            result = 'NO_PASS'
            raw_payload_sha256 = $rawHash
            raw_payload_length_bytes = [System.Text.Encoding]::UTF8.GetByteCount($RawJson)
            parse_error_type = $_.Exception.GetType().FullName
            parse_error_message = $_.Exception.Message
            event = $null
        }
    }
}

function Get-Btc15mDedupKey {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Event)

    if ([string]$Event.source -ceq 'CHAINLINK_BTC_USD') {
        return 'CHAINLINK|{0}|{1}|{2}|{3}' -f `
            $Event.symbol,
            $Event.source_timestamp_ms,
            $Event.value_decimal_string,
            $Event.raw_payload_sha256
    }
    if ([string]$Event.source -ceq 'BINANCE_BTCUSDT') {
        return 'BINANCE|{0}|{1}' -f $Event.symbol, $Event.aggregate_trade_id
    }
    throw "Unsupported event source: $($Event.source)"
}

function Select-Btc15mUniqueEvents {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Events)

    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $selected = @()
    $orderedEvents = @($Events | Sort-Object `
        @{ Expression = { [string]$_.source }; Ascending = $true },
        @{ Expression = { [long]$_.source_timestamp_ms }; Ascending = $true },
        @{ Expression = { [long]$_.collector_sequence }; Ascending = $true },
        @{ Expression = { [string]$_.raw_payload_sha256 }; Ascending = $true })

    foreach ($eventItem in $orderedEvents) {
        $key = Get-Btc15mDedupKey -Event $eventItem
        if ($seen.Add($key)) {
            $selected += $eventItem
        }
    }
    return @($selected)
}

function Get-Btc15mStalenessDiagnostic {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Event,
        [long]$ChainlinkStaleAfterMs = 10000,
        [long]$BinanceStaleAfterMs = 5000
    )

    $lag = [long]$Event.collector_receive_timestamp_ms - [long]$Event.source_timestamp_ms
    $threshold = if ([string]$Event.source -ceq 'CHAINLINK_BTC_USD') {
        $ChainlinkStaleAfterMs
    }
    elseif ([string]$Event.source -ceq 'BINANCE_BTCUSDT') {
        $BinanceStaleAfterMs
    }
    else {
        throw "Unsupported source for staleness diagnostic: $($Event.source)"
    }

    return [pscustomobject][ordered]@{
        source = [string]$Event.source
        collector_receive_lag_ms = $lag
        stale_after_ms = $threshold
        status = if ($lag -ge 0 -and $lag -le $threshold) { 'FRESH' } else { 'STALE' }
    }
}

function Get-Btc15mBinanceGapDiagnostics {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Events)

    $binanceEvents = @($Events | Where-Object { [string]$_.source -ceq 'BINANCE_BTCUSDT' } | Sort-Object aggregate_trade_id)
    $diagnostics = @()
    for ($index = 1; $index -lt $binanceEvents.Count; $index++) {
        $previous = [long]$binanceEvents[$index - 1].aggregate_trade_id
        $current = [long]$binanceEvents[$index].aggregate_trade_id
        if ($current -gt ($previous + 1)) {
            $missingFrom = $previous + 1
            $missingTo = $current - 1
            $missingCount = $missingTo - $missingFrom + 1
            $diagnostics += [pscustomobject][ordered]@{
                status = 'GAP_DETECTED'
                previous_aggregate_trade_id = $previous
                current_aggregate_trade_id = $current
                missing_from_id = $missingFrom
                missing_to_id = $missingTo
                missing_count = $missingCount
                repair_request_uri = New-Btc15mBinanceAggTradesRepairUri -FromId $missingFrom -Limit ([int][math]::Min(1000, $missingCount))
            }
        }
    }
    return @($diagnostics)
}

function New-Btc15mBinanceAggTradesRepairUri {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][long]$FromId,
        [ValidateRange(1, 1000)][int]$Limit = 1000
    )

    if ($FromId -lt 0) {
        throw 'FromId must be non-negative.'
    }
    return '{0}?symbol=BTCUSDT&fromId={1}&limit={2}' -f $script:Btc15mBinanceRepairBaseUri, $FromId, $Limit
}

function Get-Btc15mFileEvidence {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $lfCount = 0
    $crCount = 0
    foreach ($item in $bytes) {
        if ($item -eq 10) { $lfCount++ }
        if ($item -eq 13) { $crCount++ }
    }
    return [pscustomobject][ordered]@{
        file_name = [System.IO.Path]::GetFileName($Path)
        sha256 = Get-Btc15mSha256Bytes -Bytes $bytes
        bytes = $bytes.Length
        lf_count = $lfCount
        cr_count = $crCount
        utf8_bom = ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191)
    }
}

function Write-Btc15mCaptureBundle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Events,
        [Parameter(Mandatory)][string]$OutputDirectory,
        [Parameter(Mandatory)][string]$AllowedOutputRoot,
        [Parameter(Mandatory)][string]$RunId
    )

    Assert-Btc15mOutputBoundary -CandidatePath $OutputDirectory -AllowedRoot $AllowedOutputRoot
    if (Test-Path -LiteralPath $OutputDirectory) {
        throw "Output directory already exists; immutable capture bundles cannot be overwritten: $OutputDirectory"
    }
    [void][System.IO.Directory]::CreateDirectory($OutputDirectory)

    try {
        $uniqueEvents = @(Select-Btc15mUniqueEvents -Events $Events)
        if ($uniqueEvents.Count -eq 0) {
            throw 'Capture bundle requires at least one valid event.'
        }

        $rawLines = @($uniqueEvents | ForEach-Object { ConvertTo-Btc15mCanonicalJson -InputObject $_ -Depth 20 })
        $rawText = ($rawLines -join "`n") + "`n"

        $schema = [ordered]@{
            schema_version = $script:Btc15mRawSchemaVersion
            format = 'UTF8_NO_BOM_LF_JSONL'
            immutable = $true
            timestamp_unit = 'UNIX_MILLISECONDS_UTC'
            deterministic_order = @('source', 'source_timestamp_ms', 'collector_sequence', 'raw_payload_sha256')
            required_fields = @(
                'schema_version',
                'run_id',
                'source',
                'symbol',
                'source_timestamp_ms',
                'event_timestamp_ms',
                'collector_receive_timestamp_ms',
                'collector_sequence',
                'connection_id',
                'value_decimal_string',
                'raw_payload_sha256',
                'raw_payload_json'
            )
            optional_binance_fields = @(
                'quantity_decimal_string',
                'aggregate_trade_id',
                'first_trade_id',
                'last_trade_id',
                'buyer_is_maker'
            )
            deduplication = [ordered]@{
                chainlink = @('source', 'symbol', 'source_timestamp_ms', 'value_decimal_string', 'raw_payload_sha256')
                binance = @('source', 'symbol', 'aggregate_trade_id')
            }
        }

        $staleness = @($uniqueEvents | ForEach-Object { Get-Btc15mStalenessDiagnostic -Event $_ })
        $gaps = @(Get-Btc15mBinanceGapDiagnostics -Events $uniqueEvents)
        $summary = [ordered]@{
            contract_version = $script:Btc15mCaptureContractVersion
            schema_version = $script:Btc15mRawSchemaVersion
            run_id = $RunId
            event_count_input = $Events.Count
            event_count_unique = $uniqueEvents.Count
            duplicate_count = $Events.Count - $uniqueEvents.Count
            chainlink_event_count = @($uniqueEvents | Where-Object { $_.source -ceq 'CHAINLINK_BTC_USD' }).Count
            binance_event_count = @($uniqueEvents | Where-Object { $_.source -ceq 'BINANCE_BTCUSDT' }).Count
            stale_event_count = @($staleness | Where-Object { $_.status -ceq 'STALE' }).Count
            binance_gap_count = $gaps.Count
            automatic_source_fallback = $script:Btc15mAutomaticFallback
            raw_before_derived = $true
            promotion = 'SEPARATE_EXPLICIT_PHASE_ONLY'
            staleness_diagnostics = $staleness
            binance_gap_diagnostics = $gaps
        }

        $rawPath = Join-Path $OutputDirectory 'raw_events.jsonl'
        $schemaPath = Join-Path $OutputDirectory 'raw_event_schema.json'
        $summaryPath = Join-Path $OutputDirectory 'summary.json'
        $manifestPath = Join-Path $OutputDirectory 'manifest.json'

        Write-Btc15mUtf8LfAtomic -Path $rawPath -Text $rawText
        Write-Btc15mUtf8LfAtomic -Path $schemaPath -Text ((ConvertTo-Btc15mCanonicalJson -InputObject $schema -Depth 20) + "`n")
        Write-Btc15mUtf8LfAtomic -Path $summaryPath -Text ((ConvertTo-Btc15mCanonicalJson -InputObject $summary -Depth 30) + "`n")

        $manifestEntries = @(
            Get-Btc15mFileEvidence -Path $rawPath
            Get-Btc15mFileEvidence -Path $schemaPath
            Get-Btc15mFileEvidence -Path $summaryPath
        )
        $manifest = [ordered]@{
            manifest_version = 'BTC15M_CAPTURE_MANIFEST_V1'
            run_id = $RunId
            files = $manifestEntries
        }
        Write-Btc15mUtf8LfAtomic -Path $manifestPath -Text ((ConvertTo-Btc15mCanonicalJson -InputObject $manifest -Depth 20) + "`n")

        return [pscustomobject][ordered]@{
            result = 'PASS'
            output_directory = [System.IO.Path]::GetFullPath($OutputDirectory)
            event_count = $uniqueEvents.Count
            raw_path = $rawPath
            schema_path = $schemaPath
            summary_path = $summaryPath
            manifest_path = $manifestPath
        }
    }
    catch {
        if (Test-Path -LiteralPath $OutputDirectory) {
            Remove-Item -LiteralPath $OutputDirectory -Recurse -Force
        }
        throw
    }
}

function Read-Btc15mFixtureLines {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Fixture file missing: $Path"
    }
    return @([System.IO.File]::ReadAllLines($Path) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Invoke-Btc15mFixtureCapture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ChainlinkFixturePath,
        [Parameter(Mandatory)][string]$BinanceFixturePath,
        [Parameter(Mandatory)][string]$OutputDirectory,
        [Parameter(Mandatory)][string]$AllowedOutputRoot,
        [Parameter(Mandatory)][string]$RunId
    )

    $events = @()
    $sequence = 0L
    foreach ($line in @(Read-Btc15mFixtureLines -Path $ChainlinkFixturePath)) {
        $sequence++
        $events += ConvertFrom-Btc15mChainlinkMessage `
            -RawJson $line `
            -RunId $RunId `
            -CollectorReceiveTimestampMs (1700000000000L + $sequence) `
            -CollectorSequence $sequence `
            -ConnectionId 'FIXTURE_CHAINLINK'
    }
    foreach ($line in @(Read-Btc15mFixtureLines -Path $BinanceFixturePath)) {
        $sequence++
        $events += ConvertFrom-Btc15mBinanceAggTradeMessage `
            -RawJson $line `
            -RunId $RunId `
            -CollectorReceiveTimestampMs (1700000000000L + $sequence) `
            -CollectorSequence $sequence `
            -ConnectionId 'FIXTURE_BINANCE'
    }

    return Write-Btc15mCaptureBundle `
        -Events $events `
        -OutputDirectory $OutputDirectory `
        -AllowedOutputRoot $AllowedOutputRoot `
        -RunId $RunId
}

function Send-Btc15mWebSocketText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Net.WebSockets.ClientWebSocket]$Client,
        [Parameter(Mandatory)][string]$Text
    )

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $segment = [ArraySegment[byte]]::new($bytes)
    $Client.SendAsync(
        $segment,
        [System.Net.WebSockets.WebSocketMessageType]::Text,
        $true,
        [System.Threading.CancellationToken]::None
    ).GetAwaiter().GetResult()
}

function Receive-Btc15mWebSocketText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Net.WebSockets.ClientWebSocket]$Client,
        [ValidateRange(1, 120)][int]$TimeoutSeconds
    )

    $buffer = [byte[]]::new(65536)
    $stream = [System.IO.MemoryStream]::new()
    $cts = [System.Threading.CancellationTokenSource]::new([TimeSpan]::FromSeconds($TimeoutSeconds))
    try {
        do {
            $segment = [ArraySegment[byte]]::new($buffer)
            $result = $Client.ReceiveAsync($segment, $cts.Token).GetAwaiter().GetResult()
            if ($result.MessageType -eq [System.Net.WebSockets.WebSocketMessageType]::Close) {
                throw "WebSocket closed before expected event. status=$($Client.CloseStatus) description=$($Client.CloseStatusDescription)"
            }
            if ($result.Count -gt 0) {
                $stream.Write($buffer, 0, $result.Count)
            }
        } while (-not $result.EndOfMessage)

        return [System.Text.Encoding]::UTF8.GetString($stream.ToArray())
    }
    finally {
        $cts.Dispose()
        $stream.Dispose()
    }
}

function Get-Btc15mLiveChainlinkEvents {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][long]$StartSequence,
        [ValidateRange(1, 100)][int]$MaximumEvents,
        [ValidateRange(5, 120)][int]$TimeoutSeconds
    )

    $events = @()
    $client = [System.Net.WebSockets.ClientWebSocket]::new()
    $client.Options.KeepAliveInterval = [TimeSpan]::FromSeconds(5)
    $connectionId = 'CHAINLINK-{0}' -f [Guid]::NewGuid().ToString('N')
    $connectCts = [System.Threading.CancellationTokenSource]::new([TimeSpan]::FromSeconds($TimeoutSeconds))
    try {
        [void]$client.ConnectAsync([Uri]$script:Btc15mChainlinkEndpoint, $connectCts.Token).GetAwaiter().GetResult()
        Send-Btc15mWebSocketText -Client $client -Text (New-Btc15mChainlinkSubscriptionJson)
        Send-Btc15mWebSocketText -Client $client -Text 'PING'

        $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
        while ($events.Count -lt $MaximumEvents -and [DateTime]::UtcNow -lt $deadline) {
            $remaining = [math]::Max(1, [int][math]::Ceiling(($deadline - [DateTime]::UtcNow).TotalSeconds))
            $message = Receive-Btc15mWebSocketText -Client $client -TimeoutSeconds $remaining
            if ([string]::IsNullOrWhiteSpace($message) -or $message -ceq 'PONG') { continue }
            try {
                $sequence = $StartSequence + $events.Count
                $events += ConvertFrom-Btc15mChainlinkMessage `
                    -RawJson $message `
                    -RunId $RunId `
                    -CollectorReceiveTimestampMs ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()) `
                    -CollectorSequence $sequence `
                    -ConnectionId $connectionId
            }
            catch {
                continue
            }
        }
        if ($events.Count -eq 0) {
            throw 'No valid Chainlink BTC/USD event received before timeout.'
        }
        return @($events)
    }
    finally {
        $connectCts.Dispose()
        if ($client.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
            try {
                $client.CloseAsync(
                    [System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure,
                    'bounded capture complete',
                    [System.Threading.CancellationToken]::None
                ).GetAwaiter().GetResult()
            }
            catch {
            }
        }
        $client.Dispose()
    }
}

function Get-Btc15mLiveBinanceEvents {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][long]$StartSequence,
        [ValidateRange(1, 1000)][int]$MaximumEvents,
        [ValidateRange(5, 120)][int]$TimeoutSeconds
    )

    $events = @()
    $client = [System.Net.WebSockets.ClientWebSocket]::new()
    $client.Options.KeepAliveInterval = [TimeSpan]::FromSeconds(5)
    $connectionId = 'BINANCE-{0}' -f [Guid]::NewGuid().ToString('N')
    $connectCts = [System.Threading.CancellationTokenSource]::new([TimeSpan]::FromSeconds($TimeoutSeconds))
    try {
        [void]$client.ConnectAsync([Uri]$script:Btc15mBinanceEndpoint, $connectCts.Token).GetAwaiter().GetResult()
        $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
        while ($events.Count -lt $MaximumEvents -and [DateTime]::UtcNow -lt $deadline) {
            $remaining = [math]::Max(1, [int][math]::Ceiling(($deadline - [DateTime]::UtcNow).TotalSeconds))
            $message = Receive-Btc15mWebSocketText -Client $client -TimeoutSeconds $remaining
            if ([string]::IsNullOrWhiteSpace($message)) { continue }
            $sequence = $StartSequence + $events.Count
            $diagnostic = Get-Btc15mBinanceMessageDiagnostic `
                -RawJson $message `
                -RunId $RunId `
                -CollectorReceiveTimestampMs ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()) `
                -CollectorSequence $sequence `
                -ConnectionId $connectionId
            if ($diagnostic.result -ceq 'PASS') {
                $events += $diagnostic.event
            }
        }
        if ($events.Count -eq 0) {
            throw 'No valid Binance BTCUSDT aggTrade received before timeout.'
        }
        return @($events)
    }
    finally {
        $connectCts.Dispose()
        if ($client.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
            try {
                $client.CloseAsync(
                    [System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure,
                    'bounded capture complete',
                    [System.Threading.CancellationToken]::None
                ).GetAwaiter().GetResult()
            }
            catch {
            }
        }
        $client.Dispose()
    }
}

function Invoke-Btc15mLiveBoundedCapture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$OutputDirectory,
        [Parameter(Mandatory)][string]$AllowedOutputRoot,
        [Parameter(Mandatory)][string]$RunId,
        [ValidateRange(1, 100)][int]$MaxChainlinkEvents,
        [ValidateRange(1, 1000)][int]$MaxBinanceEvents,
        [ValidateRange(5, 120)][int]$TimeoutSeconds,
        [switch]$AllowNetwork
    )

    if (-not $AllowNetwork) {
        throw 'LiveBounded mode requires explicit -AllowNetwork.'
    }

    $chainlinkEvents = @(Get-Btc15mLiveChainlinkEvents `
        -RunId $RunId `
        -StartSequence 1 `
        -MaximumEvents $MaxChainlinkEvents `
        -TimeoutSeconds $TimeoutSeconds)

    $binanceEvents = @(Get-Btc15mLiveBinanceEvents `
        -RunId $RunId `
        -StartSequence (1 + $chainlinkEvents.Count) `
        -MaximumEvents $MaxBinanceEvents `
        -TimeoutSeconds $TimeoutSeconds)

    return Write-Btc15mCaptureBundle `
        -Events @($chainlinkEvents + $binanceEvents) `
        -OutputDirectory $OutputDirectory `
        -AllowedOutputRoot $AllowedOutputRoot `
        -RunId $RunId
}

function Invoke-Btc15mCaptureCli {
    [CmdletBinding()]
    param()

    if ($Mode -ceq 'PlanOnly') {
        Get-Btc15mCaptureContract | ConvertTo-Json -Depth 20
        return
    }
    if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
        throw '-OutputDirectory is required outside PlanOnly mode.'
    }
    if ([string]::IsNullOrWhiteSpace($AllowedOutputRoot)) {
        throw '-AllowedOutputRoot is required outside PlanOnly mode.'
    }
    $canonicalCaptureRoot = [System.IO.Path]::GetFullPath((Get-Btc15mCanonicalCaptureRoot))
    $suppliedAllowedRoot = [System.IO.Path]::GetFullPath($AllowedOutputRoot)
    if (-not $suppliedAllowedRoot.Equals($canonicalCaptureRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "CLI write root must equal the canonical 20_RUNS capture root. expected=$canonicalCaptureRoot actual=$suppliedAllowedRoot"
    }

    if ($Mode -ceq 'Fixture') {
        if ([string]::IsNullOrWhiteSpace($ChainlinkFixturePath) -or [string]::IsNullOrWhiteSpace($BinanceFixturePath)) {
            throw 'Fixture mode requires -ChainlinkFixturePath and -BinanceFixturePath.'
        }
        $result = Invoke-Btc15mFixtureCapture `
            -ChainlinkFixturePath $ChainlinkFixturePath `
            -BinanceFixturePath $BinanceFixturePath `
            -OutputDirectory $OutputDirectory `
            -AllowedOutputRoot $AllowedOutputRoot `
            -RunId $RunId
        $result | ConvertTo-Json -Depth 20
        return
    }

    $liveResult = Invoke-Btc15mLiveBoundedCapture `
        -OutputDirectory $OutputDirectory `
        -AllowedOutputRoot $AllowedOutputRoot `
        -RunId $RunId `
        -MaxChainlinkEvents $MaxChainlinkEvents `
        -MaxBinanceEvents $MaxBinanceEvents `
        -TimeoutSeconds $TimeoutSeconds `
        -AllowNetwork:$AllowNetwork
    $liveResult | ConvertTo-Json -Depth 20
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-Btc15mCaptureCli
}
