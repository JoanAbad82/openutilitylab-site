[CmdletBinding()]
param(
    [string]$RawEventsPath,
    [string]$OutputDirectory,
    [string]$AllowedOutputRoot,
    [string]$DatasetId = 'BTC15M_UNDERLYING_1M_MANUAL',
    [long]$CutoffTimestampMs = 0,
    [long]$AllowedLatenessMs = 5000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Btc15mRawSchemaVersion = 'BTC15M_UNDERLYING_RAW_EVENT_V1'
$script:Btc15mBarSchemaVersion = 'BTC15M_UNDERLYING_1M_BAR_V1'
$script:Btc15mBarBuilderVersion = 'BTC15M_OFFLINE_UNDERLYING_1M_BAR_BUILDER_V1'
$script:Btc15mUtf8NoBom = [System.Text.UTF8Encoding]::new($false)
$script:Btc15mMinuteMs = 60000L

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

function Get-Btc15mCanonicalBarReportRoot {
    [CmdletBinding()]
    param()

    return Join-Path $env:USERPROFILE 'Documents\BTC_15M_ARENA_OPERATIONS\30_REPORTS\CHAINLINK_BINANCE_1M_BARS'
}

function Get-Btc15mUtcMinuteStartMs {
    [CmdletBinding()]
    param([Parameter(Mandatory)][long]$TimestampMs)

    if ($TimestampMs -lt 0) {
        throw 'TimestampMs must be non-negative.'
    }
    return [long]([math]::Floor($TimestampMs / [double]$script:Btc15mMinuteMs) * $script:Btc15mMinuteMs)
}

function ConvertTo-Btc15mDecimal {
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
    return $parsed
}

function Get-Btc15mRawEventDedupKey {
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

function Select-Btc15mUniqueRawEvents {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Events)

    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $selected = @()
    foreach ($eventItem in @($Events | Sort-Object `
        @{ Expression = { [string]$_.source }; Ascending = $true },
        @{ Expression = { [string]$_.symbol }; Ascending = $true },
        @{ Expression = { [long]$_.source_timestamp_ms }; Ascending = $true },
        @{ Expression = { [long]$_.collector_sequence }; Ascending = $true },
        @{ Expression = { [string]$_.raw_payload_sha256 }; Ascending = $true })) {
        $key = Get-Btc15mRawEventDedupKey -Event $eventItem
        if ($seen.Add($key)) {
            $selected += $eventItem
        }
    }
    return @($selected)
}

function Test-Btc15mRawEventShape {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Event)

    $names = @($Event.PSObject.Properties.Name)
    foreach ($requiredName in @(
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
    )) {
        if ($names -notcontains $requiredName) {
            throw "Raw event missing property: $requiredName"
        }
    }
    if ([string]$Event.schema_version -cne $script:Btc15mRawSchemaVersion) {
        throw "Unsupported raw schema version: $($Event.schema_version)"
    }
    if ([string]$Event.source -notin @('CHAINLINK_BTC_USD', 'BINANCE_BTCUSDT')) {
        throw "Unsupported source: $($Event.source)"
    }
    if ([long]$Event.source_timestamp_ms -le 0 -or [long]$Event.collector_receive_timestamp_ms -le 0) {
        throw 'Raw event timestamps must be positive.'
    }
    if ([long]$Event.collector_sequence -le 0) {
        throw 'collector_sequence must be positive.'
    }
    [void](ConvertTo-Btc15mDecimal -Value ([string]$Event.value_decimal_string) -FieldName 'value_decimal_string')
    if ([string]$Event.raw_payload_sha256 -notmatch '^[0-9a-f]{64}$') {
        throw "Invalid raw payload SHA256: $($Event.raw_payload_sha256)"
    }
    return $true
}

function Read-Btc15mRawEvents {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Raw event file missing: $Path"
    }

    $events = @()
    $lineNumber = 0
    foreach ($line in [System.IO.File]::ReadLines($Path)) {
        $lineNumber++
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        try {
            $eventItem = $line | ConvertFrom-Json -Depth 30
            [void](Test-Btc15mRawEventShape -Event $eventItem)
            $events += $eventItem
        }
        catch {
            throw "Invalid raw event at line ${lineNumber}: $($_.Exception.Message)"
        }
    }
    return @($events)
}

function New-Btc15mUnderlyingBars {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Events,
        [Parameter(Mandatory)][long]$CutoffTimestampMs,
        [long]$AllowedLatenessMs = 5000,
        [string]$SourceRawSha256 = ('0' * 64),
        [string]$DatasetId = 'BTC15M_UNDERLYING_1M_MANUAL'
    )

    if ($CutoffTimestampMs -le 0) {
        throw 'CutoffTimestampMs must be positive.'
    }
    if ($AllowedLatenessMs -lt 0) {
        throw 'AllowedLatenessMs must be non-negative.'
    }

    $unique = @(Select-Btc15mUniqueRawEvents -Events $Events)
    $eligible = @()
    $partialExcluded = 0
    $lateExcluded = 0

    foreach ($eventItem in $unique) {
        [void](Test-Btc15mRawEventShape -Event $eventItem)
        $minuteOpen = Get-Btc15mUtcMinuteStartMs -TimestampMs ([long]$eventItem.source_timestamp_ms)
        $minuteClose = $minuteOpen + $script:Btc15mMinuteMs
        if ($minuteClose -gt $CutoffTimestampMs) {
            $partialExcluded++
            continue
        }
        if ([long]$eventItem.collector_receive_timestamp_ms -gt ($minuteClose + $AllowedLatenessMs)) {
            $lateExcluded++
            continue
        }
        $eligible += [pscustomobject][ordered]@{
            event = $eventItem
            minute_open_ms = $minuteOpen
        }
    }

    $ordered = @($eligible | Sort-Object `
        @{ Expression = { [string]$_.event.source }; Ascending = $true },
        @{ Expression = { [string]$_.event.symbol }; Ascending = $true },
        @{ Expression = { [long]$_.minute_open_ms }; Ascending = $true },
        @{ Expression = { [long]$_.event.source_timestamp_ms }; Ascending = $true },
        @{ Expression = { [long]$_.event.collector_sequence }; Ascending = $true },
        @{ Expression = { [string]$_.event.raw_payload_sha256 }; Ascending = $true })

    $bars = @()
    $index = 0
    $previousMinuteBySource = @{}
    while ($index -lt $ordered.Count) {
        $firstRecord = $ordered[$index]
        $source = [string]$firstRecord.event.source
        $symbol = [string]$firstRecord.event.symbol
        $minuteOpen = [long]$firstRecord.minute_open_ms
        $group = @()

        while (
            $index -lt $ordered.Count -and
            [string]$ordered[$index].event.source -ceq $source -and
            [string]$ordered[$index].event.symbol -ceq $symbol -and
            [long]$ordered[$index].minute_open_ms -eq $minuteOpen
        ) {
            $group += $ordered[$index].event
            $index++
        }

        $openValue = [string]$group[0].value_decimal_string
        $closeValue = [string]$group[$group.Count - 1].value_decimal_string
        $highValue = $openValue
        $lowValue = $openValue
        $highDecimal = ConvertTo-Btc15mDecimal -Value $highValue -FieldName 'high'
        $lowDecimal = $highDecimal
        $firstReceive = [long]$group[0].collector_receive_timestamp_ms
        $lastReceive = $firstReceive
        $maxLag = [long]::MinValue

        foreach ($eventItem in $group) {
            $valueDecimal = ConvertTo-Btc15mDecimal -Value ([string]$eventItem.value_decimal_string) -FieldName 'bar value'
            if ($valueDecimal -gt $highDecimal) {
                $highDecimal = $valueDecimal
                $highValue = [string]$eventItem.value_decimal_string
            }
            if ($valueDecimal -lt $lowDecimal) {
                $lowDecimal = $valueDecimal
                $lowValue = [string]$eventItem.value_decimal_string
            }
            $receive = [long]$eventItem.collector_receive_timestamp_ms
            if ($receive -lt $firstReceive) { $firstReceive = $receive }
            if ($receive -gt $lastReceive) { $lastReceive = $receive }
            $lag = $receive - [long]$eventItem.source_timestamp_ms
            if ($lag -gt $maxLag) { $maxLag = $lag }
        }

        $seriesKey = '{0}|{1}' -f $source, $symbol
        $gapStatus = 'START'
        if ($previousMinuteBySource.ContainsKey($seriesKey)) {
            $expected = [long]$previousMinuteBySource[$seriesKey] + $script:Btc15mMinuteMs
            $gapStatus = if ($minuteOpen -eq $expected) { 'OK' } else { 'GAP_BEFORE' }
        }
        $previousMinuteBySource[$seriesKey] = $minuteOpen

        $staleAfter = if ($source -ceq 'CHAINLINK_BTC_USD') { 10000L } else { 5000L }
        $stalenessStatus = if ($maxLag -ge 0 -and $maxLag -le $staleAfter) { 'FRESH' } else { 'STALE' }

        $bars += [pscustomobject][ordered]@{
            schema_version = $script:Btc15mBarSchemaVersion
            dataset_id = $DatasetId
            source = $source
            symbol = $symbol
            bar_open_timestamp_ms = $minuteOpen
            bar_close_exclusive_timestamp_ms = $minuteOpen + $script:Btc15mMinuteMs
            open_decimal_string = $openValue
            high_decimal_string = $highValue
            low_decimal_string = $lowValue
            close_decimal_string = $closeValue
            event_count = $group.Count
            first_source_timestamp_ms = [long]$group[0].source_timestamp_ms
            last_source_timestamp_ms = [long]$group[$group.Count - 1].source_timestamp_ms
            first_receive_timestamp_ms = $firstReceive
            last_receive_timestamp_ms = $lastReceive
            max_receive_lag_ms = $maxLag
            gap_status = $gapStatus
            staleness_status = $stalenessStatus
            bar_status = 'CLOSED'
            source_raw_sha256 = $SourceRawSha256
        }
    }

    $chainlinkBars = @($bars | Where-Object { $_.source -ceq 'CHAINLINK_BTC_USD' } | Sort-Object bar_open_timestamp_ms)
    $warmupReady = $false
    if ($chainlinkBars.Count -ge 120) {
        $last120 = @($chainlinkBars | Select-Object -Last 120)
        $contiguous = $true
        for ($warmupIndex = 1; $warmupIndex -lt $last120.Count; $warmupIndex++) {
            if ([long]$last120[$warmupIndex].bar_open_timestamp_ms -ne ([long]$last120[$warmupIndex - 1].bar_open_timestamp_ms + $script:Btc15mMinuteMs)) {
                $contiguous = $false
                break
            }
        }
        $warmupReady = $contiguous
    }

    return [pscustomobject][ordered]@{
        bars = @($bars)
        input_event_count = $Events.Count
        unique_event_count = $unique.Count
        duplicate_count = $Events.Count - $unique.Count
        partial_event_count_excluded = $partialExcluded
        late_event_count_excluded = $lateExcluded
        chainlink_bar_count = $chainlinkBars.Count
        chainlink_warmup_required_bars = 120
        chainlink_warmup_ready = $warmupReady
        cutoff_timestamp_ms = $CutoffTimestampMs
        allowed_lateness_ms = $AllowedLatenessMs
    }
}

function ConvertTo-Btc15mCsvField {
    [CmdletBinding()]
    param([AllowNull()]$Value)

    if ($null -eq $Value) { return '' }
    $text = [string]$Value
    if ($text.Contains('"')) {
        $text = $text.Replace('"', '""')
    }
    if ($text.IndexOfAny([char[]]@(',', '"', "`n", "`r")) -ge 0) {
        return '"{0}"' -f $text
    }
    return $text
}

function ConvertTo-Btc15mBarCsv {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Bars)

    $columns = @(
        'schema_version',
        'dataset_id',
        'source',
        'symbol',
        'bar_open_timestamp_ms',
        'bar_close_exclusive_timestamp_ms',
        'open_decimal_string',
        'high_decimal_string',
        'low_decimal_string',
        'close_decimal_string',
        'event_count',
        'first_source_timestamp_ms',
        'last_source_timestamp_ms',
        'first_receive_timestamp_ms',
        'last_receive_timestamp_ms',
        'max_receive_lag_ms',
        'gap_status',
        'staleness_status',
        'bar_status',
        'source_raw_sha256'
    )

    $lines = @($columns -join ',')
    foreach ($bar in @($Bars | Sort-Object source, symbol, bar_open_timestamp_ms)) {
        $values = @()
        foreach ($column in $columns) {
            $values += ConvertTo-Btc15mCsvField -Value $bar.$column
        }
        $lines += ($values -join ',')
    }
    return ($lines -join "`n") + "`n"
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

function Write-Btc15mBarBundle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RawEventsPath,
        [Parameter(Mandatory)][string]$OutputDirectory,
        [Parameter(Mandatory)][string]$AllowedOutputRoot,
        [Parameter(Mandatory)][string]$DatasetId,
        [Parameter(Mandatory)][long]$CutoffTimestampMs,
        [long]$AllowedLatenessMs = 5000
    )

    Assert-Btc15mOutputBoundary -CandidatePath $OutputDirectory -AllowedRoot $AllowedOutputRoot
    if (Test-Path -LiteralPath $OutputDirectory) {
        throw "Output directory already exists; deterministic bar bundles cannot be overwritten: $OutputDirectory"
    }
    [void][System.IO.Directory]::CreateDirectory($OutputDirectory)

    try {
        $rawHash = Get-Btc15mSha256File -Path $RawEventsPath
        $events = @(Read-Btc15mRawEvents -Path $RawEventsPath)
        $build = New-Btc15mUnderlyingBars `
            -Events $events `
            -CutoffTimestampMs $CutoffTimestampMs `
            -AllowedLatenessMs $AllowedLatenessMs `
            -SourceRawSha256 $rawHash `
            -DatasetId $DatasetId

        $schema = [ordered]@{
            schema_version = $script:Btc15mBarSchemaVersion
            builder_version = $script:Btc15mBarBuilderVersion
            format = 'UTF8_NO_BOM_LF_CSV'
            timeframe_seconds = 60
            timezone = 'UTC'
            timestamp_basis = 'SOURCE_TIMESTAMP'
            closed_bars_only = $true
            current_partial_minute = 'EXCLUDED'
            forward_fill = 'FORBIDDEN'
            missing_minute = 'MISSING_BAR'
            late_event_policy = 'EXCLUDE_IF_RECEIVED_AFTER_BAR_CLOSE_PLUS_ALLOWED_LATENESS'
            automatic_source_fallback = 'FORBIDDEN'
            warmup_complete_chainlink_bars = 120
            sources_remain_separate = $true
        }

        $summary = [ordered]@{
            builder_version = $script:Btc15mBarBuilderVersion
            schema_version = $script:Btc15mBarSchemaVersion
            dataset_id = $DatasetId
            source_raw_sha256 = $rawHash
            input_event_count = $build.input_event_count
            unique_event_count = $build.unique_event_count
            duplicate_count = $build.duplicate_count
            output_bar_count = $build.bars.Count
            chainlink_bar_count = $build.chainlink_bar_count
            binance_bar_count = @($build.bars | Where-Object { $_.source -ceq 'BINANCE_BTCUSDT' }).Count
            partial_event_count_excluded = $build.partial_event_count_excluded
            late_event_count_excluded = $build.late_event_count_excluded
            chainlink_warmup_required_bars = 120
            chainlink_warmup_ready = $build.chainlink_warmup_ready
            cutoff_timestamp_ms = $CutoffTimestampMs
            allowed_lateness_ms = $AllowedLatenessMs
            forward_fill = 'FORBIDDEN'
            partial_bar_usage = 'FORBIDDEN'
            automatic_source_fallback = 'FORBIDDEN'
        }

        $csvPath = Join-Path $OutputDirectory 'underlying_1m_bars.csv'
        $schemaPath = Join-Path $OutputDirectory 'bar_schema.json'
        $summaryPath = Join-Path $OutputDirectory 'summary.json'
        $manifestPath = Join-Path $OutputDirectory 'manifest.json'

        Write-Btc15mUtf8LfAtomic -Path $csvPath -Text (ConvertTo-Btc15mBarCsv -Bars $build.bars)
        Write-Btc15mUtf8LfAtomic -Path $schemaPath -Text ((ConvertTo-Btc15mCanonicalJson -InputObject $schema -Depth 20) + "`n")
        Write-Btc15mUtf8LfAtomic -Path $summaryPath -Text ((ConvertTo-Btc15mCanonicalJson -InputObject $summary -Depth 20) + "`n")

        $manifest = [ordered]@{
            manifest_version = 'BTC15M_UNDERLYING_1M_BAR_MANIFEST_V1'
            dataset_id = $DatasetId
            source_raw_sha256 = $rawHash
            files = @(
                Get-Btc15mFileEvidence -Path $csvPath
                Get-Btc15mFileEvidence -Path $schemaPath
                Get-Btc15mFileEvidence -Path $summaryPath
            )
        }
        Write-Btc15mUtf8LfAtomic -Path $manifestPath -Text ((ConvertTo-Btc15mCanonicalJson -InputObject $manifest -Depth 20) + "`n")

        return [pscustomobject][ordered]@{
            result = 'PASS'
            output_directory = [System.IO.Path]::GetFullPath($OutputDirectory)
            bar_count = $build.bars.Count
            chainlink_warmup_ready = $build.chainlink_warmup_ready
            csv_path = $csvPath
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

function Invoke-Btc15mBarBuilderCli {
    [CmdletBinding()]
    param()

    if ([string]::IsNullOrWhiteSpace($RawEventsPath)) {
        throw '-RawEventsPath is required.'
    }
    if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
        throw '-OutputDirectory is required.'
    }
    if ([string]::IsNullOrWhiteSpace($AllowedOutputRoot)) {
        throw '-AllowedOutputRoot is required.'
    }
    if ($CutoffTimestampMs -le 0) {
        throw '-CutoffTimestampMs must be positive and explicit to guarantee deterministic replay.'
    }
    $canonicalReportRoot = [System.IO.Path]::GetFullPath((Get-Btc15mCanonicalBarReportRoot))
    $suppliedAllowedRoot = [System.IO.Path]::GetFullPath($AllowedOutputRoot)
    if (-not $suppliedAllowedRoot.Equals($canonicalReportRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "CLI write root must equal the canonical 30_REPORTS bar root. expected=$canonicalReportRoot actual=$suppliedAllowedRoot"
    }

    $result = Write-Btc15mBarBundle `
        -RawEventsPath $RawEventsPath `
        -OutputDirectory $OutputDirectory `
        -AllowedOutputRoot $AllowedOutputRoot `
        -DatasetId $DatasetId `
        -CutoffTimestampMs $CutoffTimestampMs `
        -AllowedLatenessMs $AllowedLatenessMs
    $result | ConvertTo-Json -Depth 20
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-Btc15mBarBuilderCli
}
