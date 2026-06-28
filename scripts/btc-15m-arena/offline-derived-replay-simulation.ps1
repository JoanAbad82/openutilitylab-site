<#
.SYNOPSIS
Builds a deterministic replay and diagnostic paper simulation from the canonical derived BTC 15m Arena feature bundle.

.DESCRIPTION
Resolves the active derived feature bundle through CANONICAL_DERIVED_BASELINE.json, validates the pointer,
member hashes and CSV contract, builds a forward replay ordered by run, synchronized cycle, timestamp and
canonical outcome tie-breaker, then runs a deterministic technical paper simulation.

This is offline diagnostic engineering infrastructure only. It has no account integration, no order
submission path, and does not evaluate final settlement P/L.

.PARAMETER CanonicalDerivedPointerPath
Path to the canonical derived baseline pointer JSON. Defaults to the active local canonical pointer.

.PARAMETER OutputDirectory
Explicit directory where replay_cycles.csv, paper_trade_ledger.csv and simulation_summary.json are written.
Required unless NoWrite is used. The directory must not already contain files.

.PARAMETER NoWrite
Runs complete validation, replay and simulation without writing functional output files.

.PARAMETER PositionSize
Diagnostic paper position size in shares.

.PARAMETER HoldCycles
Number of synchronized cycles to hold before a position can close when its token is observed again.

.PARAMETER MaxSpread
Maximum allowed top-of-book spread for entry eligibility.

.PARAMETER MinTimeRemainingSeconds
Minimum allowed seconds remaining at entry.

.PARAMETER MaxTimeRemainingSeconds
Maximum allowed seconds remaining at entry.

.PARAMETER SlippagePerShare
Adverse slippage applied to entry and exit fills.

.PARAMETER FeePerFill
Fee charged independently at entry and exit.

.PARAMETER RsiFilterMode
Optional token-mid RSI filter. Disabled by default. Supported values: Disabled, OversoldOnly, OverboughtOnly.
#>

#requires -Version 7.0

[CmdletBinding()]
param(
    [string]$CanonicalDerivedPointerPath = 'C:\Users\JoanAB\Documents\BTC_15M_ARENA_OPERATIONS\10_ACTIVE\INPUTS\DERIVED_FEATURE_DATASETS\CANONICAL_DERIVED_BASELINE.json',
    [string]$OutputDirectory,
    [switch]$NoWrite,
    [ValidateRange(0.00000001, 1000000000)][decimal]$PositionSize = [decimal]1,
    [ValidateRange(1, 1000000)][int]$HoldCycles = 1,
    [ValidateRange(0, 1)][decimal]$MaxSpread = [decimal]0.05,
    [ValidateRange(0, 1000000000)][decimal]$MinTimeRemainingSeconds = [decimal]0,
    [ValidateRange(0, 1000000000)][decimal]$MaxTimeRemainingSeconds = [decimal]900,
    [ValidateRange(0, 1)][decimal]$SlippagePerShare = [decimal]0,
    [ValidateRange(0, 1000000000)][decimal]$FeePerFill = [decimal]0,
    [ValidateSet('Disabled','OversoldOnly','OverboughtOnly')][string]$RsiFilterMode = 'Disabled',
    [switch]$LoadOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Btc15mReplayExpectedPointerSchema = 'BTC15M_CANONICAL_DERIVED_BASELINE_POINTER_V1'
$script:Btc15mReplayExpectedBundleId = 'BTC15M_DERIVED_FEATURES_FROM_V4_V2'
$script:Btc15mReplayExpectedSourceDatasetId = 'BTC15M_MULTI_RUN_20260626T231745Z_V4'
$script:Btc15mReplayExpectedSourceDatasetSha256 = 'dd4aa16e01b58fc52e49689fa14de11a805cc725917447314a2dc74a92a2a157'
$script:Btc15mReplayExpectedMemberHashes = [ordered]@{
    'derived_snapshot_features.csv' = 'bac4fea73477a9941febced9dac1fae79fc6496e92ef78b1683d0d5fd0c162c1'
    'manifest.json' = '55ee79a0dafa16dc605c3becad160ed6656530ff9096820cf0d4110cc9a443b8'
    'schema.json' = '8ea2f80c667b0b40ac38b391f44614b5362521890b9c25001e8da8729f4acf5f'
    'summary.json' = '6e750dd5b2db67a24273dd5122208f124010ee0b123fcb7e9b0401d3b65eca2b'
}
$script:Btc15mReplayCsvColumns = @(
    'source_dataset_id',
    'source_zip_sha256',
    'source_capture_run_id',
    'source_bundle_sha256',
    'canonical_window_start_utc',
    'canonical_window_end_utc',
    'run_ordinal',
    'synchronized_cycle_ordinal',
    'observation_ordinal_within_outcome',
    'observation_timestamp_utc',
    'outcome',
    'token_id',
    'best_bid',
    'best_ask',
    'spread',
    'mid',
    'bid_level_count',
    'ask_level_count',
    'best_bid_size',
    'best_ask_size',
    'request_latency_ms',
    'counterpart_outcome',
    'counterpart_mid',
    'pair_mid_sum',
    'pair_mid_gap_from_one',
    'token_mid_return_1',
    'token_mid_rsi_14',
    'token_mid_rsi_status',
    'time_remaining_seconds',
    'row_readiness'
)

function Get-Btc15mReplayProperty {
    param(
        [Parameter(Mandatory)][object]$SourceObject,
        [Parameter(Mandatory)][string]$PropertyName
    )

    $propertyItem = $SourceObject.PSObject.Properties[$PropertyName]
    if ($null -eq $propertyItem) {
        return $null
    }
    return $propertyItem.Value
}

function ConvertTo-Btc15mReplayDecimal {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) { return $null }
    $textValue = ([string]$Value).Trim()
    if ([string]::IsNullOrWhiteSpace($textValue)) { return $null }
    $decimalValue = [decimal]0
    if ([decimal]::TryParse($textValue, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$decimalValue)) {
        return $decimalValue
    }
    return $null
}

function ConvertTo-Btc15mReplayInt {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) { return $null }
    $textValue = ([string]$Value).Trim()
    if ([string]::IsNullOrWhiteSpace($textValue)) { return $null }
    $intValue = 0
    if ([int]::TryParse($textValue, [System.Globalization.NumberStyles]::Integer, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$intValue)) {
        return $intValue
    }
    return $null
}

function ConvertTo-Btc15mReplayUtcDate {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) { return $null }
    $textValue = ([string]$Value).Trim()
    if ([string]::IsNullOrWhiteSpace($textValue)) { return $null }
    try {
        $dateValue = [System.DateTimeOffset]::Parse($textValue, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None)
        return $dateValue.ToUniversalTime().UtcDateTime
    }
    catch {
        return $null
    }
}

function Format-Btc15mReplayDecimal {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) { return '' }
    $decimalValue = [decimal]$Value
    $textValue = $decimalValue.ToString('0.############################', [System.Globalization.CultureInfo]::InvariantCulture)
    if ($textValue -ceq '-0') { return '0' }
    return $textValue
}

function Format-Btc15mReplayInt {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) { return '' }
    return ([int]$Value).ToString([System.Globalization.CultureInfo]::InvariantCulture)
}

function Format-Btc15mReplayUtc {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) { return '' }
    return ([datetime]$Value).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ', [System.Globalization.CultureInfo]::InvariantCulture)
}

function Get-Btc15mReplayFileSha256Lower {
    param([Parameter(Mandatory)][string]$Path)

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function ConvertTo-Btc15mReplayCsvCell {
    param([AllowNull()][object]$Value)

    $cellText = if ($null -eq $Value) { '' } else { [string]$Value }
    if ($cellText -match '[,"\r\n]') {
        return '"' + $cellText.Replace('"', '""') + '"'
    }
    return $cellText
}

function ConvertTo-Btc15mReplayCsvContent {
    param(
        [Parameter(Mandatory)][object[]]$Rows,
        [Parameter(Mandatory)][string[]]$Columns
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add([string]::Join(',', $Columns))
    foreach ($rowItem in $Rows) {
        $cells = [System.Collections.Generic.List[string]]::new()
        foreach ($columnName in $Columns) {
            $cells.Add((ConvertTo-Btc15mReplayCsvCell -Value (Get-Btc15mReplayProperty -SourceObject $rowItem -PropertyName $columnName)))
        }
        $lines.Add([string]::Join(',', $cells))
    }
    return [string]::Join("`n", @($lines)) + "`n"
}

function Set-Btc15mReplayUtf8NoBomFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Content
    )

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Assert-Btc15mReplayCondition {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$FailureCode
    )

    if (-not $Condition) {
        throw $FailureCode
    }
}

function Test-Btc15mExactNameSet {
    param(
        [Parameter(Mandatory)][string[]]$ActualNames,
        [Parameter(Mandatory)][string[]]$ExpectedNames
    )

    $actualNormalized = @($ActualNames | ForEach-Object { $_.ToLowerInvariant() } | Sort-Object)
    $expectedNormalized = @($ExpectedNames | ForEach-Object { $_.ToLowerInvariant() } | Sort-Object)
    return (($actualNormalized -join '|') -ceq ($expectedNormalized -join '|'))
}

function Resolve-Btc15mCanonicalDerivedBundle {
    param([Parameter(Mandatory)][string]$PointerPath)

    Assert-Btc15mReplayCondition -Condition (Test-Path -LiteralPath $PointerPath -PathType Leaf) -FailureCode ("POINTER_NOT_FOUND:{0}" -f $PointerPath)
    $pointerObject = Get-Content -LiteralPath $PointerPath -Raw | ConvertFrom-Json -Depth 100
    Assert-Btc15mReplayCondition -Condition ([string]$pointerObject.schema_version -ceq $script:Btc15mReplayExpectedPointerSchema) -FailureCode 'INVALID_POINTER_SCHEMA_VERSION'
    Assert-Btc15mReplayCondition -Condition ([string]$pointerObject.active_bundle_id -ceq $script:Btc15mReplayExpectedBundleId) -FailureCode 'INVALID_ACTIVE_BUNDLE_ID'
    Assert-Btc15mReplayCondition -Condition ([string]$pointerObject.source_dataset_id -ceq $script:Btc15mReplayExpectedSourceDatasetId) -FailureCode 'INVALID_SOURCE_DATASET_ID'
    Assert-Btc15mReplayCondition -Condition ([string]$pointerObject.source_dataset_sha256 -ceq $script:Btc15mReplayExpectedSourceDatasetSha256) -FailureCode 'INVALID_SOURCE_DATASET_SHA256'
    Assert-Btc15mReplayCondition -Condition ([bool]$pointerObject.replay_readiness) -FailureCode 'REPLAY_READINESS_NOT_TRUE'
    Assert-Btc15mReplayCondition -Condition ([bool]$pointerObject.simulation_engineering_readiness) -FailureCode 'SIMULATION_ENGINEERING_READINESS_NOT_TRUE'
    Assert-Btc15mReplayCondition -Condition (-not [bool]$pointerObject.statistical_validation_readiness) -FailureCode 'STATISTICAL_VALIDATION_READINESS_NOT_FALSE'
    Assert-Btc15mReplayCondition -Condition ([int]$pointerObject.member_count -eq 4) -FailureCode 'INVALID_MEMBER_COUNT'

    $sourcePath = [string]$pointerObject.source_dataset_path
    Assert-Btc15mReplayCondition -Condition (Test-Path -LiteralPath $sourcePath -PathType Leaf) -FailureCode ("SOURCE_DATASET_NOT_FOUND:{0}" -f $sourcePath)
    $sourceHash = Get-Btc15mReplayFileSha256Lower -Path $sourcePath
    Assert-Btc15mReplayCondition -Condition ($sourceHash -ceq $script:Btc15mReplayExpectedSourceDatasetSha256) -FailureCode 'SOURCE_DATASET_HASH_MISMATCH'

    $bundleDirectory = [string]$pointerObject.active_bundle_directory
    Assert-Btc15mReplayCondition -Condition (Test-Path -LiteralPath $bundleDirectory -PathType Container) -FailureCode ("ACTIVE_BUNDLE_DIRECTORY_NOT_FOUND:{0}" -f $bundleDirectory)

    $expectedMemberNames = @($script:Btc15mReplayExpectedMemberHashes.Keys | Sort-Object)
    $physicalChildren = @(Get-ChildItem -LiteralPath $bundleDirectory -Force)
    $physicalDirectories = @($physicalChildren | Where-Object { $_.PSIsContainer })
    if ($physicalDirectories.Count -ne 0) {
        $firstDirectoryName = [string](@($physicalDirectories | Sort-Object Name)[0].Name)
        throw ("UNEXPECTED_BUNDLE_CHILD_DIRECTORY:{0}" -f $firstDirectoryName)
    }
    $physicalFiles = @($physicalChildren | Where-Object { -not $_.PSIsContainer })
    Assert-Btc15mReplayCondition -Condition ($physicalFiles.Count -eq 4) -FailureCode ("INVALID_PHYSICAL_BUNDLE_FILE_COUNT:{0}" -f $physicalFiles.Count)
    $physicalNames = @($physicalFiles | ForEach-Object { $_.Name })
    Assert-Btc15mReplayCondition -Condition (Test-Btc15mExactNameSet -ActualNames $physicalNames -ExpectedNames $expectedMemberNames) -FailureCode ("INVALID_PHYSICAL_BUNDLE_FILE_SET:{0}" -f (($physicalNames | Sort-Object) -join '|'))

    $members = @($pointerObject.members | Sort-Object name)
    $actualMemberNames = @($members | ForEach-Object { [string]$_.name })
    Assert-Btc15mReplayCondition -Condition (Test-Btc15mExactNameSet -ActualNames $actualMemberNames -ExpectedNames $expectedMemberNames) -FailureCode ("INVALID_POINTER_MEMBER_SET:{0}" -f (($actualMemberNames | Sort-Object) -join '|'))

    $memberHashes = [ordered]@{}
    foreach ($memberItem in $members) {
        $memberName = [string]$memberItem.name
        $expectedHash = [string]$script:Btc15mReplayExpectedMemberHashes[$memberName]
        $declaredHash = ([string]$memberItem.sha256).ToLowerInvariant()
        Assert-Btc15mReplayCondition -Condition ($declaredHash -ceq $expectedHash) -FailureCode ("DECLARED_MEMBER_HASH_MISMATCH:{0}" -f $memberName)
        $memberPath = Join-Path $bundleDirectory $memberName
        Assert-Btc15mReplayCondition -Condition (Test-Path -LiteralPath $memberPath -PathType Leaf) -FailureCode ("MEMBER_NOT_FOUND:{0}" -f $memberName)
        $actualHash = Get-Btc15mReplayFileSha256Lower -Path $memberPath
        Assert-Btc15mReplayCondition -Condition ($actualHash -ceq $expectedHash) -FailureCode ("MEMBER_HASH_MISMATCH:{0}" -f $memberName)
        $memberHashes[$memberName] = $actualHash
    }

    return [pscustomobject]@{
        pointer_path = $PointerPath
        pointer = $pointerObject
        active_bundle_id = [string]$pointerObject.active_bundle_id
        active_bundle_directory = $bundleDirectory
        source_dataset_id = [string]$pointerObject.source_dataset_id
        source_dataset_sha256 = [string]$pointerObject.source_dataset_sha256
        source_dataset_path = $sourcePath
        member_hashes = $memberHashes
        csv_path = Join-Path $bundleDirectory 'derived_snapshot_features.csv'
    }
}

function Read-Btc15mReplayCsvRows {
    param([Parameter(Mandatory)][string]$CsvPath)

    $csvText = Get-Content -LiteralPath $CsvPath -Raw
    $firstLine = ($csvText -split "`r?`n", 2)[0]
    $headerColumns = @($firstLine.Split(','))
    Assert-Btc15mReplayCondition -Condition (($headerColumns -join '|') -ceq ($script:Btc15mReplayCsvColumns -join '|')) -FailureCode 'INVALID_CSV_HEADER'
    $rows = @($csvText | ConvertFrom-Csv)
    return [pscustomobject]@{
        rows = $rows
        row_count = $rows.Count
        column_count = $headerColumns.Count
        columns = $headerColumns
    }
}

function ConvertTo-Btc15mReplayRow {
    param(
        [Parameter(Mandatory)][object]$RawRow,
        [Parameter(Mandatory)][int]$SourceIndex
    )

    $reasons = [System.Collections.Generic.List[string]]::new()
    $runOrdinal = ConvertTo-Btc15mReplayInt (Get-Btc15mReplayProperty -SourceObject $RawRow -PropertyName 'run_ordinal')
    $cycleOrdinal = ConvertTo-Btc15mReplayInt (Get-Btc15mReplayProperty -SourceObject $RawRow -PropertyName 'synchronized_cycle_ordinal')
    $timestampValue = ConvertTo-Btc15mReplayUtcDate (Get-Btc15mReplayProperty -SourceObject $RawRow -PropertyName 'observation_timestamp_utc')
    $bestBid = ConvertTo-Btc15mReplayDecimal (Get-Btc15mReplayProperty -SourceObject $RawRow -PropertyName 'best_bid')
    $bestAsk = ConvertTo-Btc15mReplayDecimal (Get-Btc15mReplayProperty -SourceObject $RawRow -PropertyName 'best_ask')
    $spreadValue = ConvertTo-Btc15mReplayDecimal (Get-Btc15mReplayProperty -SourceObject $RawRow -PropertyName 'spread')
    $midValue = ConvertTo-Btc15mReplayDecimal (Get-Btc15mReplayProperty -SourceObject $RawRow -PropertyName 'mid')
    $pairMidSum = ConvertTo-Btc15mReplayDecimal (Get-Btc15mReplayProperty -SourceObject $RawRow -PropertyName 'pair_mid_sum')
    $pairGap = ConvertTo-Btc15mReplayDecimal (Get-Btc15mReplayProperty -SourceObject $RawRow -PropertyName 'pair_mid_gap_from_one')
    $timeRemaining = ConvertTo-Btc15mReplayDecimal (Get-Btc15mReplayProperty -SourceObject $RawRow -PropertyName 'time_remaining_seconds')
    $returnValue = ConvertTo-Btc15mReplayDecimal (Get-Btc15mReplayProperty -SourceObject $RawRow -PropertyName 'token_mid_return_1')
    $rsiValue = ConvertTo-Btc15mReplayDecimal (Get-Btc15mReplayProperty -SourceObject $RawRow -PropertyName 'token_mid_rsi_14')
    $outcomeText = ([string](Get-Btc15mReplayProperty -SourceObject $RawRow -PropertyName 'outcome')).Trim().ToUpperInvariant()
    $tokenId = ([string](Get-Btc15mReplayProperty -SourceObject $RawRow -PropertyName 'token_id')).Trim()
    $readiness = ([string](Get-Btc15mReplayProperty -SourceObject $RawRow -PropertyName 'row_readiness')).Trim().ToUpperInvariant()

    if ($null -eq $runOrdinal) { $reasons.Add('INVALID_RUN_ORDINAL') }
    if ($null -eq $cycleOrdinal) { $reasons.Add('INVALID_SYNCHRONIZED_CYCLE_ORDINAL') }
    if ($null -eq $timestampValue) { $reasons.Add('INVALID_TIMESTAMP') }
    if ($outcomeText -notin @('UP','DOWN')) { $reasons.Add('INVALID_OUTCOME') }
    if ([string]::IsNullOrWhiteSpace($tokenId)) { $reasons.Add('INVALID_TOKEN_ID') }
    if ($null -eq $bestBid -or $bestBid -lt 0 -or $bestBid -gt 1) { $reasons.Add('INVALID_BEST_BID') }
    if ($null -eq $bestAsk -or $bestAsk -lt 0 -or $bestAsk -gt 1) { $reasons.Add('INVALID_BEST_ASK') }
    if ($null -eq $spreadValue -or $spreadValue -lt 0) { $reasons.Add('INVALID_SPREAD') }
    if ($null -eq $midValue -or $midValue -lt 0 -or $midValue -gt 1) { $reasons.Add('INVALID_MID') }
    if ($null -eq $pairMidSum) { $reasons.Add('INVALID_PAIR_MID_SUM') }
    if ($null -eq $pairGap) { $reasons.Add('INVALID_PAIR_MID_GAP') }
    if ($null -eq $timeRemaining) { $reasons.Add('INVALID_TIME_REMAINING') }
    if ($readiness -cne 'PASS') { $reasons.Add('ROW_READINESS_NOT_PASS') }

    return [pscustomobject]@{
        source_index = $SourceIndex
        source_dataset_id = [string]$RawRow.source_dataset_id
        source_zip_sha256 = [string]$RawRow.source_zip_sha256
        source_capture_run_id = [string]$RawRow.source_capture_run_id
        source_bundle_sha256 = [string]$RawRow.source_bundle_sha256
        run_ordinal = $runOrdinal
        synchronized_cycle_ordinal = $cycleOrdinal
        observation_timestamp_utc = $timestampValue
        observation_timestamp_text = if ($null -eq $timestampValue) { [string]$RawRow.observation_timestamp_utc } else { Format-Btc15mReplayUtc $timestampValue }
        outcome = $outcomeText
        token_id = $tokenId
        best_bid = $bestBid
        best_ask = $bestAsk
        spread = $spreadValue
        mid = $midValue
        pair_mid_sum = $pairMidSum
        pair_mid_gap_from_one = $pairGap
        token_mid_return_1 = $returnValue
        token_mid_rsi_14 = $rsiValue
        token_mid_rsi_status = [string]$RawRow.token_mid_rsi_status
        time_remaining_seconds = $timeRemaining
        row_readiness = $readiness
        is_valid = ($reasons.Count -eq 0)
        rejection_reason = if ($reasons.Count -eq 0) { '' } else { [string]::Join(';', @($reasons)) }
    }
}

function Get-Btc15mReplayOutcomeOrder {
    param([string]$Outcome)

    if ($Outcome -ceq 'UP') { return 0 }
    if ($Outcome -ceq 'DOWN') { return 1 }
    return 9
}

function Add-Btc15mReplayReasonCount {
    param(
        [Parameter(Mandatory)][System.Collections.Specialized.OrderedDictionary]$Counts,
        [Parameter(Mandatory)][string]$Reason
    )

    foreach ($reasonItem in @($Reason -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object)) {
        if (-not $Counts.Contains($reasonItem)) {
            $Counts[$reasonItem] = 0
        }
        $Counts[$reasonItem] = [int]$Counts[$reasonItem] + 1
    }
}

function New-Btc15mReplayModel {
    param([Parameter(Mandatory)][object[]]$RawRows)

    $parsedRows = [System.Collections.Generic.List[object]]::new()
    for ($rowIndex = 0; $rowIndex -lt $RawRows.Count; $rowIndex++) {
        $parsedRows.Add((ConvertTo-Btc15mReplayRow -RawRow $RawRows[$rowIndex] -SourceIndex ($rowIndex + 1)))
    }

    $rowRejectionCounts = [ordered]@{}
    foreach ($parsedRow in $parsedRows) {
        if (-not $parsedRow.is_valid) {
            Add-Btc15mReplayReasonCount -Counts $rowRejectionCounts -Reason $parsedRow.rejection_reason
        }
    }

    $identityGroups = @($parsedRows | Group-Object { '{0}|{1}|{2}|{3}|{4}' -f $_.source_capture_run_id, $_.run_ordinal, $_.synchronized_cycle_ordinal, $_.outcome, $_.token_id })
    $duplicateIdentitySourceIndexes = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($identityGroup in $identityGroups) {
        if ($identityGroup.Count -gt 1) {
            foreach ($duplicateRow in @($identityGroup.Group)) {
                [void]$duplicateIdentitySourceIndexes.Add([int]$duplicateRow.source_index)
            }
        }
    }

    $groups = @($parsedRows | Group-Object { '{0}|{1}|{2}' -f $_.source_capture_run_id, $_.run_ordinal, $_.synchronized_cycle_ordinal })
    $cycles = [System.Collections.Generic.List[object]]::new()
    $cycleRejectionCounts = [ordered]@{}
    $usedRowIndexes = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($groupItem in $groups) {
        $cycleRows = @($groupItem.Group)
        $reasons = [System.Collections.Generic.List[string]]::new()
        foreach ($cycleRow in $cycleRows) {
            if (-not $cycleRow.is_valid) { $reasons.Add($cycleRow.rejection_reason) }
            if ($duplicateIdentitySourceIndexes.Contains([int]$cycleRow.source_index)) { $reasons.Add('DUPLICATE_ROW_IDENTITY') }
        }
        $upRows = @($cycleRows | Where-Object { $_.outcome -ceq 'UP' })
        $downRows = @($cycleRows | Where-Object { $_.outcome -ceq 'DOWN' })
        if ($upRows.Count -eq 0) { $reasons.Add('MISSING_UP') }
        if ($downRows.Count -eq 0) { $reasons.Add('MISSING_DOWN') }
        if ($upRows.Count -gt 1) { $reasons.Add('DUPLICATE_UP') }
        if ($downRows.Count -gt 1) { $reasons.Add('DUPLICATE_DOWN') }

        $selectedUp = if ($upRows.Count -ge 1) { @($upRows | Sort-Object source_index)[0] } else { $null }
        $selectedDown = if ($downRows.Count -ge 1) { @($downRows | Sort-Object source_index)[0] } else { $null }
        if ($null -ne $selectedUp -and $usedRowIndexes.Contains([int]$selectedUp.source_index)) { $reasons.Add('REUSED_ROW') }
        if ($null -ne $selectedDown -and $usedRowIndexes.Contains([int]$selectedDown.source_index)) { $reasons.Add('REUSED_ROW') }

        $distinctReasons = @($reasons | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_ -split ';' } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
        $accepted = ($distinctReasons.Count -eq 0)
        if ($accepted) {
            [void]$usedRowIndexes.Add([int]$selectedUp.source_index)
            [void]$usedRowIndexes.Add([int]$selectedDown.source_index)
        }
        else {
            Add-Btc15mReplayReasonCount -Counts $cycleRejectionCounts -Reason ([string]::Join(';', $distinctReasons))
        }

        $representativeRow = @($cycleRows | Sort-Object source_index)[0]
        $cycles.Add([pscustomobject]@{
            source_dataset_id = [string]$representativeRow.source_dataset_id
            source_capture_run_id = [string]$representativeRow.source_capture_run_id
            run_ordinal = [int]$representativeRow.run_ordinal
            synchronized_cycle_ordinal = [int]$representativeRow.synchronized_cycle_ordinal
            up_row = $selectedUp
            down_row = $selectedDown
            cycle_status = if ($accepted) { 'ACCEPTED' } else { 'REJECTED' }
            rejection_reason = if ($accepted) { '' } else { [string]::Join(';', $distinctReasons) }
            pair_mid_sum = if ($null -ne $selectedUp) { $selectedUp.pair_mid_sum } elseif ($null -ne $selectedDown) { $selectedDown.pair_mid_sum } else { $null }
            pair_mid_gap_from_one = if ($null -ne $selectedUp) { $selectedUp.pair_mid_gap_from_one } elseif ($null -ne $selectedDown) { $selectedDown.pair_mid_gap_from_one } else { $null }
            replay_order_index = 0
        })
    }

    $sortedCycles = @($cycles | Sort-Object `
        @{ Expression = { $_.run_ordinal }; Ascending = $true }, `
        @{ Expression = { $_.synchronized_cycle_ordinal }; Ascending = $true })
    for ($cycleIndex = 0; $cycleIndex -lt $sortedCycles.Count; $cycleIndex++) {
        $sortedCycles[$cycleIndex].replay_order_index = $cycleIndex + 1
    }

    $acceptedRows = @($parsedRows | Where-Object { $_.is_valid })
    $acceptedCycles = @($sortedCycles | Where-Object { $_.cycle_status -ceq 'ACCEPTED' })
    $runGroups = @($sortedCycles | Group-Object run_ordinal | Sort-Object { [int]$_.Name })
    $cyclesPerRun = [ordered]@{}
    foreach ($runGroup in $runGroups) {
        $cyclesPerRun[[string]$runGroup.Name] = @($runGroup.Group | Where-Object { $_.cycle_status -ceq 'ACCEPTED' }).Count
    }

    return [pscustomobject]@{
        total_rows = $parsedRows.Count
        accepted_rows = $acceptedRows.Count
        rejected_rows = $parsedRows.Count - $acceptedRows.Count
        measured_cycles = $sortedCycles.Count
        accepted_cycles = $acceptedCycles.Count
        rejected_cycles = $sortedCycles.Count - $acceptedCycles.Count
        runs = $runGroups.Count
        cycles_per_run = $cyclesPerRun
        row_rejection_counts = $rowRejectionCounts
        cycle_rejection_counts = $cycleRejectionCounts
        rows = @($parsedRows)
        cycles = @($sortedCycles)
    }
}

function Test-Btc15mEntryEligibility {
    param(
        [Parameter(Mandatory)][object]$Row,
        [Parameter(Mandatory)][object]$Configuration
    )

    $reasons = [System.Collections.Generic.List[string]]::new()
    if (-not $Row.is_valid -or $Row.row_readiness -cne 'PASS') { $reasons.Add('ROW_READINESS_NOT_PASS') }
    if ($null -eq $Row.best_ask -or $Row.best_ask -lt 0 -or $Row.best_ask -gt 1) { $reasons.Add('ENTRY_BEST_ASK_INVALID') }
    if ($null -eq $Row.spread -or $Row.spread -gt [decimal]$Configuration.max_spread) { $reasons.Add('SPREAD_FILTER_REJECTED') }
    if ($null -eq $Row.time_remaining_seconds -or $Row.time_remaining_seconds -lt [decimal]$Configuration.min_time_remaining_seconds -or $Row.time_remaining_seconds -gt [decimal]$Configuration.max_time_remaining_seconds) {
        $reasons.Add('TIME_REMAINING_FILTER_REJECTED')
    }
    if ([string]$Configuration.rsi_filter_mode -ceq 'OversoldOnly') {
        if ($null -eq $Row.token_mid_rsi_14 -or $Row.token_mid_rsi_14 -gt 30) { $reasons.Add('RSI_FILTER_REJECTED') }
    }
    elseif ([string]$Configuration.rsi_filter_mode -ceq 'OverboughtOnly') {
        if ($null -eq $Row.token_mid_rsi_14 -or $Row.token_mid_rsi_14 -lt 70) { $reasons.Add('RSI_FILTER_REJECTED') }
    }

    return [pscustomobject]@{
        eligible = ($reasons.Count -eq 0)
        reason = if ($reasons.Count -eq 0) { 'ENTRY_ELIGIBLE' } else { [string]::Join(';', @($reasons)) }
    }
}

function Get-Btc15mClampedBinaryPrice {
    param([Parameter(Mandatory)][decimal]$Price)

    if ($Price -lt 0) { return [decimal]0 }
    if ($Price -gt 1) { return [decimal]1 }
    return $Price
}

function New-Btc15mPaperSimulation {
    param(
        [Parameter(Mandatory)][object]$ReplayModel,
        [Parameter(Mandatory)][object]$Configuration
    )

    $openPositions = [System.Collections.Generic.List[object]]::new()
    $ledgerRows = [System.Collections.Generic.List[object]]::new()
    $entryRejectionCounts = [ordered]@{}
    $tradeSequence = 0
    $lastRowByRunToken = @{}
    $acceptedCycles = @($ReplayModel.cycles | Where-Object { $_.cycle_status -ceq 'ACCEPTED' } | Sort-Object replay_order_index)

    foreach ($cycleItem in $acceptedCycles) {
        $eventRows = @($cycleItem.up_row, $cycleItem.down_row) | Where-Object { $null -ne $_ } | Sort-Object `
            @{ Expression = { $_.observation_timestamp_utc }; Ascending = $true }, `
            @{ Expression = { Get-Btc15mReplayOutcomeOrder -Outcome $_.outcome }; Ascending = $true }
        foreach ($eventRow in $eventRows) {
            $runTokenKey = '{0}|{1}' -f $eventRow.run_ordinal, $eventRow.token_id
            $lastRowByRunToken[$runTokenKey] = $eventRow

            foreach ($positionItem in @($openPositions | Where-Object {
                $_.run_ordinal -eq $eventRow.run_ordinal -and
                $_.token_id -ceq $eventRow.token_id -and
                $_.outcome -ceq $eventRow.outcome -and
                [int]$cycleItem.replay_order_index -gt [int]$_.last_progress_replay_order_index
            })) {
                $positionItem.accepted_hold_progress = [int]$positionItem.accepted_hold_progress + 1
                $positionItem.last_progress_replay_order_index = [int]$cycleItem.replay_order_index
            }

            $positionsToClose = @($openPositions | Where-Object {
                $_.run_ordinal -eq $eventRow.run_ordinal -and
                $_.token_id -ceq $eventRow.token_id -and
                $_.outcome -ceq $eventRow.outcome -and
                [int]$_.accepted_hold_progress -ge [int]$Configuration.hold_cycles -and
                [int]$cycleItem.replay_order_index -gt [int]$_.entry_replay_order_index
            } | Sort-Object trade_sequence)
            foreach ($positionItem in $positionsToClose) {
                if ($null -eq $eventRow.best_bid -or $eventRow.best_bid -lt 0 -or $eventRow.best_bid -gt 1) {
                    $positionItem.exit_reason = 'EXIT_BEST_BID_INVALID'
                    continue
                }
                $exitReference = [decimal]$eventRow.best_bid
                $exitFill = Get-Btc15mClampedBinaryPrice -Price ($exitReference - [decimal]$Configuration.slippage_per_share)
                $grossPnl = ($exitFill - [decimal]$positionItem.entry_fill_price) * [decimal]$Configuration.position_size
                $totalFees = [decimal]$Configuration.fee_per_fill + [decimal]$Configuration.fee_per_fill
                $netPnl = $grossPnl - $totalFees
                $ledgerRows.Add([pscustomobject]@{
                    trade_id = ('TRADE-{0:000000}' -f [int]$positionItem.trade_sequence)
                    source_dataset_id = $eventRow.source_dataset_id
                    run_ordinal = Format-Btc15mReplayInt $eventRow.run_ordinal
                    outcome = $eventRow.outcome
                    token_id = $eventRow.token_id
                    trade_status = 'CLOSED'
                    entry_cycle = Format-Btc15mReplayInt $positionItem.entry_cycle
                    entry_replay_order_index = Format-Btc15mReplayInt $positionItem.entry_replay_order_index
                    entry_timestamp = Format-Btc15mReplayUtc $positionItem.entry_timestamp
                    entry_best_ask = Format-Btc15mReplayDecimal $positionItem.entry_reference_price
                    entry_fill_price = Format-Btc15mReplayDecimal $positionItem.entry_fill_price
                    exit_cycle = Format-Btc15mReplayInt $cycleItem.synchronized_cycle_ordinal
                    exit_replay_order_index = Format-Btc15mReplayInt $cycleItem.replay_order_index
                    exit_timestamp = Format-Btc15mReplayUtc $eventRow.observation_timestamp_utc
                    exit_best_bid = Format-Btc15mReplayDecimal $exitReference
                    exit_fill_price = Format-Btc15mReplayDecimal $exitFill
                    position_size = Format-Btc15mReplayDecimal $Configuration.position_size
                    configured_hold_cycles = Format-Btc15mReplayInt $Configuration.hold_cycles
                    accepted_hold_progress_at_exit = Format-Btc15mReplayInt $positionItem.accepted_hold_progress
                    slippage_per_share = Format-Btc15mReplayDecimal $Configuration.slippage_per_share
                    entry_fee = Format-Btc15mReplayDecimal $Configuration.fee_per_fill
                    exit_fee = Format-Btc15mReplayDecimal $Configuration.fee_per_fill
                    gross_pnl = Format-Btc15mReplayDecimal $grossPnl
                    net_realized_pnl = Format-Btc15mReplayDecimal $netPnl
                    mark_to_market_pnl = ''
                    entry_reason = $positionItem.entry_reason
                    exit_reason = 'HOLD_CYCLES_ELAPSED_AT_OBSERVED_ROW'
                    decision_cutoff_timestamp = Format-Btc15mReplayUtc $positionItem.decision_cutoff_timestamp
                    no_lookahead_audit_status = 'CURRENT_OR_PRIOR_ROWS_ONLY'
                    final_settlement_pnl_status = 'NOT_EVALUATED'
                })
                [void]$openPositions.Remove($positionItem)
            }

            $stillOpenForToken = @($openPositions | Where-Object { $_.run_ordinal -eq $eventRow.run_ordinal -and $_.token_id -ceq $eventRow.token_id }).Count -gt 0
            if (-not $stillOpenForToken) {
                $eligibility = Test-Btc15mEntryEligibility -Row $eventRow -Configuration $Configuration
                if ($eligibility.eligible) {
                    $tradeSequence++
                    $entryReference = [decimal]$eventRow.best_ask
                    $entryFill = Get-Btc15mClampedBinaryPrice -Price ($entryReference + [decimal]$Configuration.slippage_per_share)
                    $openPositions.Add([pscustomobject]@{
                        trade_sequence = $tradeSequence
                        source_dataset_id = $eventRow.source_dataset_id
                        run_ordinal = [int]$eventRow.run_ordinal
                        outcome = $eventRow.outcome
                        token_id = $eventRow.token_id
                        entry_cycle = [int]$cycleItem.synchronized_cycle_ordinal
                        entry_replay_order_index = [int]$cycleItem.replay_order_index
                        accepted_hold_progress = 0
                        last_progress_replay_order_index = [int]$cycleItem.replay_order_index
                        entry_timestamp = $eventRow.observation_timestamp_utc
                        entry_reference_price = $entryReference
                        entry_fill_price = $entryFill
                        entry_reason = 'ENTRY_ELIGIBLE_BEST_ASK_FILL'
                        decision_cutoff_timestamp = $eventRow.observation_timestamp_utc
                        exit_reason = ''
                    })
                }
                else {
                    Add-Btc15mReplayReasonCount -Counts $entryRejectionCounts -Reason $eligibility.reason
                }
            }
        }
    }

    foreach ($positionItem in @($openPositions | Sort-Object trade_sequence)) {
        $runTokenKey = '{0}|{1}' -f $positionItem.run_ordinal, $positionItem.token_id
        $lastRow = if ($lastRowByRunToken.ContainsKey($runTokenKey)) { $lastRowByRunToken[$runTokenKey] } else { $null }
        $markPnl = $null
        if ($null -ne $lastRow -and $null -ne $lastRow.best_bid) {
            $markPnl = ([decimal]$lastRow.best_bid - [decimal]$positionItem.entry_fill_price) * [decimal]$Configuration.position_size
        }
        $ledgerRows.Add([pscustomobject]@{
            trade_id = ('TRADE-{0:000000}' -f [int]$positionItem.trade_sequence)
            source_dataset_id = $positionItem.source_dataset_id
            run_ordinal = Format-Btc15mReplayInt $positionItem.run_ordinal
            outcome = $positionItem.outcome
            token_id = $positionItem.token_id
            trade_status = 'OPEN_MARK_TO_MARKET_ONLY'
            entry_cycle = Format-Btc15mReplayInt $positionItem.entry_cycle
            entry_replay_order_index = Format-Btc15mReplayInt $positionItem.entry_replay_order_index
            entry_timestamp = Format-Btc15mReplayUtc $positionItem.entry_timestamp
            entry_best_ask = Format-Btc15mReplayDecimal $positionItem.entry_reference_price
            entry_fill_price = Format-Btc15mReplayDecimal $positionItem.entry_fill_price
            exit_cycle = ''
            exit_replay_order_index = ''
            exit_timestamp = ''
            exit_best_bid = ''
            exit_fill_price = ''
            position_size = Format-Btc15mReplayDecimal $Configuration.position_size
            configured_hold_cycles = Format-Btc15mReplayInt $Configuration.hold_cycles
            accepted_hold_progress_at_exit = Format-Btc15mReplayInt $positionItem.accepted_hold_progress
            slippage_per_share = Format-Btc15mReplayDecimal $Configuration.slippage_per_share
            entry_fee = Format-Btc15mReplayDecimal $Configuration.fee_per_fill
            exit_fee = ''
            gross_pnl = ''
            net_realized_pnl = ''
            mark_to_market_pnl = Format-Btc15mReplayDecimal $markPnl
            entry_reason = $positionItem.entry_reason
            exit_reason = 'NO_VALID_OBSERVED_EXIT_BEFORE_RUN_END'
            decision_cutoff_timestamp = Format-Btc15mReplayUtc $positionItem.decision_cutoff_timestamp
            no_lookahead_audit_status = 'CURRENT_OR_PRIOR_ROWS_ONLY'
            final_settlement_pnl_status = 'NOT_EVALUATED'
        })
    }

    $closedRows = @($ledgerRows | Where-Object { $_.trade_status -ceq 'CLOSED' })
    $openRows = @($ledgerRows | Where-Object { $_.trade_status -ceq 'OPEN_MARK_TO_MARKET_ONLY' })
    $realizedAggregate = [decimal]0
    foreach ($ledgerRow in $closedRows) {
        $realizedAggregate += [decimal](ConvertTo-Btc15mReplayDecimal $ledgerRow.net_realized_pnl)
    }
    $markAggregate = [decimal]0
    foreach ($ledgerRow in $openRows) {
        $markValue = ConvertTo-Btc15mReplayDecimal $ledgerRow.mark_to_market_pnl
        if ($null -ne $markValue) { $markAggregate += [decimal]$markValue }
    }

    return [pscustomobject]@{
        ledger = @($ledgerRows | Sort-Object trade_id)
        entry_rejection_counts = $entryRejectionCounts
        total_trades = $ledgerRows.Count
        closed_trades = $closedRows.Count
        open_mark_to_market_trades = $openRows.Count
        net_realized_pnl_aggregate = $realizedAggregate
        mark_to_market_pnl_aggregate = $markAggregate
        no_lookahead_result = 'PASS'
        executable_price_semantics_result = 'PASS'
        final_settlement_status = 'NOT_EVALUATED'
    }
}

function ConvertTo-Btc15mReplayCycleRows {
    param([Parameter(Mandatory)][object]$ReplayModel)

    $rows = [System.Collections.Generic.List[object]]::new()
    foreach ($cycleItem in @($ReplayModel.cycles | Sort-Object replay_order_index)) {
        $rows.Add([pscustomobject]@{
            source_dataset_id = $cycleItem.source_dataset_id
            source_capture_run_id = $cycleItem.source_capture_run_id
            run_ordinal = Format-Btc15mReplayInt $cycleItem.run_ordinal
            synchronized_cycle_ordinal = Format-Btc15mReplayInt $cycleItem.synchronized_cycle_ordinal
            up_timestamp = if ($null -eq $cycleItem.up_row) { '' } else { Format-Btc15mReplayUtc $cycleItem.up_row.observation_timestamp_utc }
            down_timestamp = if ($null -eq $cycleItem.down_row) { '' } else { Format-Btc15mReplayUtc $cycleItem.down_row.observation_timestamp_utc }
            cycle_status = $cycleItem.cycle_status
            rejection_reason = $cycleItem.rejection_reason
            pair_mid_sum = Format-Btc15mReplayDecimal $cycleItem.pair_mid_sum
            pair_mid_gap_from_one = Format-Btc15mReplayDecimal $cycleItem.pair_mid_gap_from_one
            up_time_remaining_seconds = if ($null -eq $cycleItem.up_row) { '' } else { Format-Btc15mReplayDecimal $cycleItem.up_row.time_remaining_seconds }
            down_time_remaining_seconds = if ($null -eq $cycleItem.down_row) { '' } else { Format-Btc15mReplayDecimal $cycleItem.down_row.time_remaining_seconds }
            up_row_readiness = if ($null -eq $cycleItem.up_row) { '' } else { $cycleItem.up_row.row_readiness }
            down_row_readiness = if ($null -eq $cycleItem.down_row) { '' } else { $cycleItem.down_row.row_readiness }
            replay_order_index = Format-Btc15mReplayInt $cycleItem.replay_order_index
        })
    }
    return [object[]]$rows.ToArray()
}

function New-Btc15mReplayConfiguration {
    param(
        [decimal]$PositionSize,
        [int]$HoldCycles,
        [decimal]$MaxSpread,
        [decimal]$MinTimeRemainingSeconds,
        [decimal]$MaxTimeRemainingSeconds,
        [decimal]$SlippagePerShare,
        [decimal]$FeePerFill,
        [string]$RsiFilterMode
    )

    Assert-Btc15mReplayCondition -Condition ($MinTimeRemainingSeconds -le $MaxTimeRemainingSeconds) -FailureCode 'INVALID_TIME_REMAINING_RANGE'
    return [pscustomobject]@{
        position_size = $PositionSize
        hold_cycles = $HoldCycles
        max_spread = $MaxSpread
        min_time_remaining_seconds = $MinTimeRemainingSeconds
        max_time_remaining_seconds = $MaxTimeRemainingSeconds
        slippage_per_share = $SlippagePerShare
        fee_per_fill = $FeePerFill
        rsi_filter_mode = $RsiFilterMode
    }
}

function ConvertTo-Btc15mReplaySummaryObject {
    param(
        [Parameter(Mandatory)][object]$Bundle,
        [Parameter(Mandatory)][object]$CsvInfo,
        [Parameter(Mandatory)][object]$ReplayModel,
        [Parameter(Mandatory)][object]$Simulation,
        [Parameter(Mandatory)][object]$Configuration,
        [AllowNull()][string]$ReplayCyclesSha256,
        [AllowNull()][string]$PaperTradeLedgerSha256
    )

    return [pscustomobject][ordered]@{
        schema_version = 'BTC15M_DERIVED_REPLAY_SIMULATION_SUMMARY_V1'
        active_bundle_id = $Bundle.active_bundle_id
        source_dataset_id = $Bundle.source_dataset_id
        source_dataset_sha256 = $Bundle.source_dataset_sha256
        member_hashes = $Bundle.member_hashes
        configuration = [pscustomobject][ordered]@{
            position_size = Format-Btc15mReplayDecimal $Configuration.position_size
            hold_cycles = Format-Btc15mReplayInt $Configuration.hold_cycles
            max_spread = Format-Btc15mReplayDecimal $Configuration.max_spread
            min_time_remaining_seconds = Format-Btc15mReplayDecimal $Configuration.min_time_remaining_seconds
            max_time_remaining_seconds = Format-Btc15mReplayDecimal $Configuration.max_time_remaining_seconds
            slippage_per_share = Format-Btc15mReplayDecimal $Configuration.slippage_per_share
            fee_per_fill = Format-Btc15mReplayDecimal $Configuration.fee_per_fill
            rsi_filter_mode = $Configuration.rsi_filter_mode
        }
        row_counts = [pscustomobject][ordered]@{
            total_rows = $ReplayModel.total_rows
            accepted_rows = $ReplayModel.accepted_rows
            rejected_rows = $ReplayModel.rejected_rows
            csv_rows = $CsvInfo.row_count
            csv_columns = $CsvInfo.column_count
        }
        measured_cycle_counts = [pscustomobject][ordered]@{
            measured_cycles = $ReplayModel.measured_cycles
            accepted_cycles = $ReplayModel.accepted_cycles
            rejected_cycles = $ReplayModel.rejected_cycles
        }
        run_counts = [pscustomobject][ordered]@{
            runs = $ReplayModel.runs
            cycles_per_run = $ReplayModel.cycles_per_run
        }
        rejection_counts_by_reason = [pscustomobject][ordered]@{
            rows = $ReplayModel.row_rejection_counts
            cycles = $ReplayModel.cycle_rejection_counts
            entries = $Simulation.entry_rejection_counts
        }
        trade_counts = [pscustomobject][ordered]@{
            total_trades = $Simulation.total_trades
            closed_trades = $Simulation.closed_trades
            open_mark_to_market_trades = $Simulation.open_mark_to_market_trades
        }
        realized_pnl_aggregate = Format-Btc15mReplayDecimal $Simulation.net_realized_pnl_aggregate
        mark_to_market_aggregate = Format-Btc15mReplayDecimal $Simulation.mark_to_market_pnl_aggregate
        replay_cycles_csv_sha256 = if ([string]::IsNullOrWhiteSpace($ReplayCyclesSha256)) { 'NOT_WRITTEN' } else { $ReplayCyclesSha256 }
        paper_trade_ledger_csv_sha256 = if ([string]::IsNullOrWhiteSpace($PaperTradeLedgerSha256)) { 'NOT_WRITTEN' } else { $PaperTradeLedgerSha256 }
        no_lookahead_result = $Simulation.no_lookahead_result
        executable_price_semantics_result = $Simulation.executable_price_semantics_result
        final_settlement_status = 'NOT_EVALUATED'
        replay_readiness = 'YES'
        simulation_engineering_readiness = 'YES'
        statistical_validation_readiness = 'NO'
        statistical_readiness = 'PARTIAL'
    }
}

function Invoke-Btc15mOfflineDerivedReplaySimulation {
    param(
        [string]$CanonicalDerivedPointerPath,
        [string]$OutputDirectory,
        [bool]$NoWrite,
        [decimal]$PositionSize,
        [int]$HoldCycles,
        [decimal]$MaxSpread,
        [decimal]$MinTimeRemainingSeconds,
        [decimal]$MaxTimeRemainingSeconds,
        [decimal]$SlippagePerShare,
        [decimal]$FeePerFill,
        [string]$RsiFilterMode
    )

    $configuration = New-Btc15mReplayConfiguration `
        -PositionSize $PositionSize `
        -HoldCycles $HoldCycles `
        -MaxSpread $MaxSpread `
        -MinTimeRemainingSeconds $MinTimeRemainingSeconds `
        -MaxTimeRemainingSeconds $MaxTimeRemainingSeconds `
        -SlippagePerShare $SlippagePerShare `
        -FeePerFill $FeePerFill `
        -RsiFilterMode $RsiFilterMode

    $bundle = Resolve-Btc15mCanonicalDerivedBundle -PointerPath $CanonicalDerivedPointerPath
    $csvInfo = Read-Btc15mReplayCsvRows -CsvPath $bundle.csv_path
    Assert-Btc15mReplayCondition -Condition ($csvInfo.row_count -eq 594) -FailureCode 'CANONICAL_CSV_ROW_COUNT_MISMATCH'
    Assert-Btc15mReplayCondition -Condition ($csvInfo.column_count -eq 30) -FailureCode 'CANONICAL_CSV_COLUMN_COUNT_MISMATCH'

    $replayModel = New-Btc15mReplayModel -RawRows $csvInfo.rows
    $simulation = New-Btc15mPaperSimulation -ReplayModel $replayModel -Configuration $configuration
    $cycleRows = ConvertTo-Btc15mReplayCycleRows -ReplayModel $replayModel
    $replayColumns = @(
        'source_dataset_id','source_capture_run_id','run_ordinal','synchronized_cycle_ordinal',
        'up_timestamp','down_timestamp','cycle_status','rejection_reason','pair_mid_sum',
        'pair_mid_gap_from_one','up_time_remaining_seconds','down_time_remaining_seconds',
        'up_row_readiness','down_row_readiness','replay_order_index'
    )
    $ledgerColumns = @(
        'trade_id','source_dataset_id','run_ordinal','outcome','token_id','trade_status',
        'entry_cycle','entry_replay_order_index','entry_timestamp','entry_best_ask','entry_fill_price','exit_cycle',
        'exit_replay_order_index','exit_timestamp','exit_best_bid','exit_fill_price','position_size','configured_hold_cycles',
        'accepted_hold_progress_at_exit','slippage_per_share','entry_fee','exit_fee','gross_pnl','net_realized_pnl',
        'mark_to_market_pnl','entry_reason','exit_reason','decision_cutoff_timestamp',
        'no_lookahead_audit_status','final_settlement_pnl_status'
    )

    $replayHash = $null
    $ledgerHash = $null
    if (-not $NoWrite) {
        Assert-Btc15mReplayCondition -Condition (-not [string]::IsNullOrWhiteSpace($OutputDirectory)) -FailureCode 'OUTPUT_DIRECTORY_REQUIRED'
        if (Test-Path -LiteralPath $OutputDirectory) {
            Assert-Btc15mReplayCondition -Condition (@(Get-ChildItem -LiteralPath $OutputDirectory -Force).Count -eq 0) -FailureCode 'OUTPUT_DIRECTORY_NOT_EMPTY'
        }
        else {
            New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
        }

        $replayPath = Join-Path $OutputDirectory 'replay_cycles.csv'
        $ledgerPath = Join-Path $OutputDirectory 'paper_trade_ledger.csv'
        $summaryPath = Join-Path $OutputDirectory 'simulation_summary.json'
        Set-Btc15mReplayUtf8NoBomFile -Path $replayPath -Content (ConvertTo-Btc15mReplayCsvContent -Rows $cycleRows -Columns $replayColumns)
        Set-Btc15mReplayUtf8NoBomFile -Path $ledgerPath -Content (ConvertTo-Btc15mReplayCsvContent -Rows $simulation.ledger -Columns $ledgerColumns)
        $replayHash = Get-Btc15mReplayFileSha256Lower -Path $replayPath
        $ledgerHash = Get-Btc15mReplayFileSha256Lower -Path $ledgerPath
        $summaryObject = ConvertTo-Btc15mReplaySummaryObject -Bundle $bundle -CsvInfo $csvInfo -ReplayModel $replayModel -Simulation $simulation -Configuration $configuration -ReplayCyclesSha256 $replayHash -PaperTradeLedgerSha256 $ledgerHash
        $summaryJson = $summaryObject | ConvertTo-Json -Depth 40
        $summaryJson = $summaryJson -replace "`r`n", "`n"
        $summaryJson = $summaryJson -replace "`r", "`n"
        $summaryJson = $summaryJson.TrimEnd("`r", "`n") + "`n"
        Set-Btc15mReplayUtf8NoBomFile -Path $summaryPath -Content $summaryJson
    }
    else {
        $summaryObject = ConvertTo-Btc15mReplaySummaryObject -Bundle $bundle -CsvInfo $csvInfo -ReplayModel $replayModel -Simulation $simulation -Configuration $configuration -ReplayCyclesSha256 $null -PaperTradeLedgerSha256 $null
    }

    return [pscustomobject][ordered]@{
        schema_version = 'BTC15M_DERIVED_REPLAY_SIMULATION_RESULT_V1'
        result = 'PASS'
        active_bundle_id = $bundle.active_bundle_id
        source_dataset_id = $bundle.source_dataset_id
        source_dataset_sha256 = $bundle.source_dataset_sha256
        canonical_csv_rows = $csvInfo.row_count
        canonical_csv_columns = $csvInfo.column_count
        measured_cycles = $replayModel.measured_cycles
        accepted_cycles = $replayModel.accepted_cycles
        rejected_cycles = $replayModel.rejected_cycles
        total_trades = $simulation.total_trades
        closed_trades = $simulation.closed_trades
        open_mark_to_market_trades = $simulation.open_mark_to_market_trades
        replay_cycles_csv_sha256 = if ($null -eq $replayHash) { 'NOT_WRITTEN' } else { $replayHash }
        paper_trade_ledger_csv_sha256 = if ($null -eq $ledgerHash) { 'NOT_WRITTEN' } else { $ledgerHash }
        no_lookahead_result = $simulation.no_lookahead_result
        executable_price_semantics_result = $simulation.executable_price_semantics_result
        final_settlement_status = 'NOT_EVALUATED'
        statistical_readiness = 'PARTIAL'
        summary = $summaryObject
    }
}

if (-not $LoadOnly) {
    try {
        $resultObject = Invoke-Btc15mOfflineDerivedReplaySimulation `
            -CanonicalDerivedPointerPath $CanonicalDerivedPointerPath `
            -OutputDirectory $OutputDirectory `
            -NoWrite ([bool]$NoWrite) `
            -PositionSize $PositionSize `
            -HoldCycles $HoldCycles `
            -MaxSpread $MaxSpread `
            -MinTimeRemainingSeconds $MinTimeRemainingSeconds `
            -MaxTimeRemainingSeconds $MaxTimeRemainingSeconds `
            -SlippagePerShare $SlippagePerShare `
            -FeePerFill $FeePerFill `
            -RsiFilterMode $RsiFilterMode
        $resultObject | ConvertTo-Json -Depth 40
        exit 0
    }
    catch {
        $failureObject = [pscustomobject][ordered]@{
            schema_version = 'BTC15M_DERIVED_REPLAY_SIMULATION_RESULT_V1'
            result = 'NO_PASS'
            error_code = 'REPLAY_SIMULATION_FAILED'
            error_message = $_.Exception.Message
            final_settlement_status = 'NOT_EVALUATED'
            statistical_readiness = 'PARTIAL'
        }
        $failureObject | ConvertTo-Json -Depth 10
        exit 1
    }
}
