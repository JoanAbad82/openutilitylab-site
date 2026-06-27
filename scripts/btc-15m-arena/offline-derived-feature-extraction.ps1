<#
.SYNOPSIS
Builds the BTC 15m Arena V4 offline derived snapshot feature dataset.

.DESCRIPTION
Reads the canonical V4 ZIP without mutation and writes one deterministic derived
feature bundle: CSV, schema, summary, and manifest.
#>

[CmdletBinding()]
param(
    [string]$InputZip,
    [string]$OutputDirectory,
    [switch]$LoadOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function ConvertTo-Btc15mInvariantDecimal {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) {
        return $null
    }

    $textValue = ([string]$Value).Trim()
    if ([string]::IsNullOrWhiteSpace($textValue)) {
        return $null
    }

    $decimalValue = [decimal]0
    $cultureInfo = [System.Globalization.CultureInfo]::InvariantCulture
    if ([decimal]::TryParse($textValue, [System.Globalization.NumberStyles]::Float, $cultureInfo, [ref]$decimalValue)) {
        return $decimalValue
    }

    $alternateText = $textValue.Replace(',', '.')
    if ([decimal]::TryParse($alternateText, [System.Globalization.NumberStyles]::Float, $cultureInfo, [ref]$decimalValue)) {
        return $decimalValue
    }

    return $null
}

function ConvertTo-Btc15mNullableInt {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) {
        return $null
    }

    $textValue = ([string]$Value).Trim()
    if ([string]::IsNullOrWhiteSpace($textValue)) {
        return $null
    }

    $intValue = 0
    if ([int]::TryParse($textValue, [System.Globalization.NumberStyles]::Integer, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$intValue)) {
        return $intValue
    }

    return $null
}

function Format-Btc15mDecimal {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) {
        return ''
    }

    $decimalValue = [decimal]$Value
    $textValue = $decimalValue.ToString('0.############################', [System.Globalization.CultureInfo]::InvariantCulture)
    if ($textValue -eq '-0') {
        return '0'
    }
    return $textValue
}

function Format-Btc15mInteger {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) {
        return ''
    }

    return ([int]$Value).ToString([System.Globalization.CultureInfo]::InvariantCulture)
}

function ConvertTo-Btc15mUtcText {
    param([Parameter(Mandatory)][string]$Value)

    $dateTimeOffsetValue = [System.DateTimeOffset]::Parse($Value, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None)
    return $dateTimeOffsetValue.ToUniversalTime().UtcDateTime.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ', [System.Globalization.CultureInfo]::InvariantCulture)
}

function ConvertTo-Btc15mUtcDate {
    param([Parameter(Mandatory)][string]$Value)

    $dateTimeOffsetValue = [System.DateTimeOffset]::Parse($Value, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None)
    return $dateTimeOffsetValue.ToUniversalTime().UtcDateTime
}

function Get-Btc15mProperty {
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

function Read-Btc15mZipEntryText {
    param(
        [Parameter(Mandatory)][string]$ZipPath,
        [Parameter(Mandatory)][string]$EntryName
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zipArchive = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
    try {
        $zipEntry = $zipArchive.GetEntry($EntryName)
        if ($null -eq $zipEntry) {
            throw ("ZIP_ENTRY_NOT_FOUND:{0}" -f $EntryName)
        }

        $entryReader = [System.IO.StreamReader]::new($zipEntry.Open())
        try {
            return $entryReader.ReadToEnd()
        }
        finally {
            $entryReader.Dispose()
        }
    }
    finally {
        $zipArchive.Dispose()
    }
}

function Get-Btc15mCsvColumns {
    return @(
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
}

function New-Btc15mSchemaColumns {
    $columnRows = @(
        @('source_dataset_id','string',$false,'identity_and_provenance','Canonical source dataset identifier.','dataset_report.dataset_id',''),
        @('source_zip_sha256','string',$false,'identity_and_provenance','SHA256 of the source ZIP observed before extraction.','Get-FileHash(InputZip)',''),
        @('source_capture_run_id','string',$false,'identity_and_provenance','Capture run identifier from the source snapshot.','dataset_snapshots.jsonl.source_capture_run_id',''),
        @('source_bundle_sha256','string',$false,'identity_and_provenance','Source bundle SHA256 for the capture run.','dataset_snapshots.jsonl.source_bundle_sha256',''),
        @('canonical_window_start_utc','datetime_utc',$false,'identity_and_provenance','Market window start normalized to UTC.','dataset_snapshots.jsonl.market_window_start_utc converted to UTC',''),
        @('canonical_window_end_utc','datetime_utc',$false,'identity_and_provenance','Market window end normalized to UTC.','dataset_snapshots.jsonl.market_window_end_utc converted to UTC',''),
        @('run_ordinal','integer',$false,'identity_and_provenance','One-based dataset run order.','dataset_snapshots.jsonl.dataset_run_order',''),
        @('synchronized_cycle_ordinal','integer',$false,'cross_outcome_coherence','One-based UP/DOWN cycle sequence inside the run.','dataset_snapshots.jsonl.cycle_sequence',''),
        @('observation_ordinal_within_outcome','integer',$false,'observation_timestamp','One-based chronological ordinal per run and outcome.','derived by source_capture_run_id/outcome chronological order',''),
        @('observation_timestamp_utc','datetime_utc',$false,'observation_timestamp','Response receive timestamp normalized to UTC.','dataset_snapshots.jsonl.response_received_utc converted to UTC',''),
        @('outcome','string',$false,'identity_and_provenance','Outcome side for the token.','dataset_snapshots.jsonl.token_side',''),
        @('token_id','string',$false,'identity_and_provenance','Polymarket token identifier.','dataset_snapshots.jsonl.token_id',''),
        @('best_bid','decimal',$false,'best_bid_best_ask','Best bid at observation time.','dataset_snapshots.jsonl.best_bid','probability'),
        @('best_ask','decimal',$false,'best_bid_best_ask','Best ask at observation time.','dataset_snapshots.jsonl.best_ask','probability'),
        @('spread','decimal',$false,'spread_and_mid','Top-of-book spread.','best_ask - best_bid','probability'),
        @('mid','decimal',$false,'spread_and_mid','Top-of-book midpoint.','(best_bid + best_ask) / 2','probability'),
        @('bid_level_count','integer',$false,'book_level_counts','Number of bid levels in the source book.','dataset_snapshots.jsonl.bid_level_count','levels'),
        @('ask_level_count','integer',$false,'book_level_counts','Number of ask levels in the source book.','dataset_snapshots.jsonl.ask_level_count','levels'),
        @('best_bid_size','decimal',$true,'top_level_depth','Displayed size at best bid.','dataset_snapshots.jsonl.best_bid_size','shares'),
        @('best_ask_size','decimal',$true,'top_level_depth','Displayed size at best ask.','dataset_snapshots.jsonl.best_ask_size','shares'),
        @('request_latency_ms','integer',$true,'request_latency','Request latency from source capture.','dataset_snapshots.jsonl.latency_ms','milliseconds'),
        @('counterpart_outcome','string',$false,'cross_outcome_coherence','Opposite outcome in the same synchronized cycle.','paired by source_capture_run_id and cycle_sequence',''),
        @('counterpart_mid','decimal',$false,'cross_outcome_coherence','Counterpart token midpoint in the same cycle.','counterpart row mid','probability'),
        @('pair_mid_sum','decimal',$false,'cross_outcome_coherence','UP and DOWN midpoint sum in the same cycle.','up_mid + down_mid','probability'),
        @('pair_mid_gap_from_one','decimal',$false,'cross_outcome_coherence','Absolute pair midpoint deviation from one.','abs(1 - pair_mid_sum)','probability'),
        @('token_mid_return_1','decimal',$true,'within_window_token_returns','One-step midpoint return inside the same run/outcome.','(current_mid / previous_mid) - 1','ratio'),
        @('token_mid_rsi_14','decimal',$true,'token_mid_rsi_14','Wilder RSI over token mid changes inside the same run/outcome.','standard Wilder RSI(14) over mid; resets per run/outcome','index'),
        @('token_mid_rsi_status','string',$false,'token_mid_rsi_14','RSI readiness status for the row.','INSUFFICIENT_HISTORY until ordinal 15, then EXPERIMENTAL_PER_RUN',''),
        @('time_remaining_seconds','decimal',$false,'observation_timestamp','Seconds from observation timestamp to canonical window end.','canonical_window_end_utc - observation_timestamp_utc','seconds'),
        @('row_readiness','string',$false,'identity_and_provenance','Row-level engineering readiness marker.','PASS when required source and derived fields are present','')
    )

    $schemaColumns = [System.Collections.Generic.List[object]]::new()
    foreach ($columnRow in $columnRows) {
        $schemaColumns.Add([pscustomobject]@{
            name = $columnRow[0]
            type = $columnRow[1]
            nullable = [bool]$columnRow[2]
            feature_family = $columnRow[3]
            description = $columnRow[4]
            formula_or_source_mapping = $columnRow[5]
            units = $columnRow[6]
        })
    }

    return [object[]]$schemaColumns.ToArray()
}

function ConvertTo-Btc15mCsvLine {
    param(
        [Parameter(Mandatory)][object]$RowObject,
        [Parameter(Mandatory)][string[]]$Columns
    )

    $cells = [System.Collections.Generic.List[string]]::new()
    foreach ($columnName in $Columns) {
        $propertyValue = Get-Btc15mProperty -SourceObject $RowObject -PropertyName $columnName
        $cellText = if ($null -eq $propertyValue) { '' } else { [string]$propertyValue }
        if ($cellText -match '[,"\r\n]') {
            $cellText = '"' + $cellText.Replace('"', '""') + '"'
        }
        $cells.Add($cellText)
    }

    return [string]::Join(',', $cells)
}

function Set-Btc15mUtf8NoBomFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Content
    )

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Get-Btc15mFileSha256Lower {
    param([Parameter(Mandatory)][string]$Path)

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-Btc15mFeatureFamilyStatus {
    return [ordered]@{
        identity_and_provenance = 'READY'
        observation_timestamp = 'READY'
        best_bid_best_ask = 'READY'
        spread_and_mid = 'READY'
        book_level_counts = 'READY'
        top_level_depth = 'READY'
        request_latency = 'READY'
        cross_outcome_coherence = 'READY'
        within_window_token_returns = 'READY'
        token_mid_rsi_14 = 'EXPERIMENTAL_PER_RUN'
        btc_spot_rsi = 'NOT_READY'
        btc_atr = 'NOT_READY'
        statistical_model_validation = 'PARTIAL'
    }
}

function Add-Btc15mSequentialFeatures {
    param([Parameter(Mandatory)][object[]]$Rows)

    $groups = @($Rows | Group-Object source_capture_run_id, outcome)
    foreach ($groupItem in $groups) {
        $groupRows = @($groupItem.Group | Sort-Object @{ Expression = { $_.observation_timestamp_utc }; Ascending = $true }, @{ Expression = { $_.synchronized_cycle_ordinal }; Ascending = $true })
        $previousMid = $null
        $averageGain = $null
        $averageLoss = $null
        $changes = [System.Collections.Generic.List[decimal]]::new()

        for ($rowIndex = 0; $rowIndex -lt $groupRows.Count; $rowIndex++) {
            $currentRow = $groupRows[$rowIndex]
            $currentOrdinal = $rowIndex + 1
            $currentRow.observation_ordinal_within_outcome = $currentOrdinal
            $currentMid = [decimal]$currentRow.mid_value

            if ($null -eq $previousMid) {
                $currentRow.token_mid_return_1 = ''
            }
            else {
                $returnValue = ($currentMid / $previousMid) - 1
                $currentRow.token_mid_return_1 = Format-Btc15mDecimal -Value $returnValue
                $changes.Add($currentMid - $previousMid)
            }

            if ($currentOrdinal -le 14) {
                $currentRow.token_mid_rsi_14 = ''
                $currentRow.token_mid_rsi_status = 'INSUFFICIENT_HISTORY'
            }
            else {
                if ($currentOrdinal -eq 15) {
                    $gainSum = [decimal]0
                    $lossSum = [decimal]0
                    foreach ($changeValue in $changes) {
                        if ($changeValue -gt 0) {
                            $gainSum += $changeValue
                        }
                        elseif ($changeValue -lt 0) {
                            $lossSum += [decimal]::Negate($changeValue)
                        }
                    }
                    $averageGain = $gainSum / 14
                    $averageLoss = $lossSum / 14
                }
                else {
                    $latestChange = $currentMid - $previousMid
                    $gainValue = if ($latestChange -gt 0) { $latestChange } else { [decimal]0 }
                    $lossValue = if ($latestChange -lt 0) { [decimal]::Negate($latestChange) } else { [decimal]0 }
                    $averageGain = (($averageGain * 13) + $gainValue) / 14
                    $averageLoss = (($averageLoss * 13) + $lossValue) / 14
                }

                if ($averageLoss -eq 0 -and $averageGain -eq 0) {
                    $rsiValue = [decimal]50
                }
                elseif ($averageLoss -eq 0) {
                    $rsiValue = [decimal]100
                }
                else {
                    $relativeStrength = $averageGain / $averageLoss
                    $rsiValue = [decimal](100 - (100 / (1 + [double]$relativeStrength)))
                }

                $currentRow.token_mid_rsi_14 = Format-Btc15mDecimal -Value $rsiValue
                $currentRow.token_mid_rsi_status = 'EXPERIMENTAL_PER_RUN'
            }

            $previousMid = $currentMid
        }
    }
}

function New-Btc15mDerivedRows {
    param(
        [Parameter(Mandatory)][string]$ZipPath,
        [Parameter(Mandatory)][string]$SourceZipSha256
    )

    $reportText = Read-Btc15mZipEntryText -ZipPath $ZipPath -EntryName 'dataset_report.json'
    $runsText = Read-Btc15mZipEntryText -ZipPath $ZipPath -EntryName 'dataset_runs.csv'
    $excludedText = Read-Btc15mZipEntryText -ZipPath $ZipPath -EntryName 'excluded_runs.csv'
    $snapshotsText = Read-Btc15mZipEntryText -ZipPath $ZipPath -EntryName 'dataset_snapshots.jsonl'

    $datasetReport = $reportText | ConvertFrom-Json -Depth 100
    $runRows = @($runsText | ConvertFrom-Csv)
    $excludedRows = @($excludedText | ConvertFrom-Csv)
    $snapshotLines = @($snapshotsText -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

    $snapshotRecords = [System.Collections.Generic.List[object]]::new()
    foreach ($snapshotLine in $snapshotLines) {
        $snapshotRecords.Add(($snapshotLine | ConvertFrom-Json -Depth 100 -DateKind String))
    }
    $snapshots = [object[]]$snapshotRecords.ToArray()

    $rows = [System.Collections.Generic.List[object]]::new()
    foreach ($snapshotRecord in $snapshots) {
        $bestBid = ConvertTo-Btc15mInvariantDecimal (Get-Btc15mProperty -SourceObject $snapshotRecord -PropertyName 'best_bid')
        $bestAsk = ConvertTo-Btc15mInvariantDecimal (Get-Btc15mProperty -SourceObject $snapshotRecord -PropertyName 'best_ask')
        $bestBidSize = ConvertTo-Btc15mInvariantDecimal (Get-Btc15mProperty -SourceObject $snapshotRecord -PropertyName 'best_bid_size')
        $bestAskSize = ConvertTo-Btc15mInvariantDecimal (Get-Btc15mProperty -SourceObject $snapshotRecord -PropertyName 'best_ask_size')
        $bidLevelCount = ConvertTo-Btc15mNullableInt (Get-Btc15mProperty -SourceObject $snapshotRecord -PropertyName 'bid_level_count')
        $askLevelCount = ConvertTo-Btc15mNullableInt (Get-Btc15mProperty -SourceObject $snapshotRecord -PropertyName 'ask_level_count')
        $latencyMs = ConvertTo-Btc15mNullableInt (Get-Btc15mProperty -SourceObject $snapshotRecord -PropertyName 'latency_ms')
        $cycleOrdinal = ConvertTo-Btc15mNullableInt (Get-Btc15mProperty -SourceObject $snapshotRecord -PropertyName 'cycle_sequence')
        $runOrdinal = ConvertTo-Btc15mNullableInt (Get-Btc15mProperty -SourceObject $snapshotRecord -PropertyName 'dataset_run_order')
        $spreadValue = $bestAsk - $bestBid
        $midValue = ($bestBid + $bestAsk) / 2
        $windowStartText = ConvertTo-Btc15mUtcText -Value ([string](Get-Btc15mProperty -SourceObject $snapshotRecord -PropertyName 'market_window_start_utc'))
        $windowEndText = ConvertTo-Btc15mUtcText -Value ([string](Get-Btc15mProperty -SourceObject $snapshotRecord -PropertyName 'market_window_end_utc'))
        $observationText = ConvertTo-Btc15mUtcText -Value ([string](Get-Btc15mProperty -SourceObject $snapshotRecord -PropertyName 'response_received_utc'))
        $windowEndDate = ConvertTo-Btc15mUtcDate -Value ([string](Get-Btc15mProperty -SourceObject $snapshotRecord -PropertyName 'market_window_end_utc'))
        $observationDate = ConvertTo-Btc15mUtcDate -Value ([string](Get-Btc15mProperty -SourceObject $snapshotRecord -PropertyName 'response_received_utc'))
        $secondsRemaining = [decimal]([Math]::Round(($windowEndDate - $observationDate).TotalSeconds, 6))
        $outcomeText = ([string](Get-Btc15mProperty -SourceObject $snapshotRecord -PropertyName 'token_side')).ToUpperInvariant()

        $rows.Add([pscustomobject]@{
            source_dataset_id = [string]$datasetReport.dataset_id
            source_zip_sha256 = $SourceZipSha256
            source_capture_run_id = [string](Get-Btc15mProperty -SourceObject $snapshotRecord -PropertyName 'source_capture_run_id')
            source_bundle_sha256 = [string](Get-Btc15mProperty -SourceObject $snapshotRecord -PropertyName 'source_bundle_sha256')
            canonical_window_start_utc = $windowStartText
            canonical_window_end_utc = $windowEndText
            run_ordinal = $runOrdinal
            synchronized_cycle_ordinal = $cycleOrdinal
            observation_ordinal_within_outcome = 0
            observation_timestamp_utc = $observationText
            outcome = $outcomeText
            token_id = [string](Get-Btc15mProperty -SourceObject $snapshotRecord -PropertyName 'token_id')
            best_bid = Format-Btc15mDecimal -Value $bestBid
            best_ask = Format-Btc15mDecimal -Value $bestAsk
            spread = Format-Btc15mDecimal -Value $spreadValue
            mid = Format-Btc15mDecimal -Value $midValue
            bid_level_count = Format-Btc15mInteger -Value $bidLevelCount
            ask_level_count = Format-Btc15mInteger -Value $askLevelCount
            best_bid_size = Format-Btc15mDecimal -Value $bestBidSize
            best_ask_size = Format-Btc15mDecimal -Value $bestAskSize
            request_latency_ms = Format-Btc15mInteger -Value $latencyMs
            counterpart_outcome = ''
            counterpart_mid = ''
            pair_mid_sum = ''
            pair_mid_gap_from_one = ''
            token_mid_return_1 = ''
            token_mid_rsi_14 = ''
            token_mid_rsi_status = ''
            time_remaining_seconds = Format-Btc15mDecimal -Value $secondsRemaining
            row_readiness = 'PASS'
            mid_value = $midValue
        })
    }

    $pairGroups = @($rows | Group-Object source_capture_run_id, synchronized_cycle_ordinal)
    foreach ($pairGroup in $pairGroups) {
        $pairRows = @($pairGroup.Group)
        if ($pairRows.Count -ne 2) {
            continue
        }

        $upRows = @($pairRows | Where-Object { $_.outcome -ceq 'UP' })
        $downRows = @($pairRows | Where-Object { $_.outcome -ceq 'DOWN' })
        if ($upRows.Count -ne 1 -or $downRows.Count -ne 1) {
            continue
        }

        $upRow = $upRows[0]
        $downRow = $downRows[0]
        $upMid = [decimal]$upRow.mid_value
        $downMid = [decimal]$downRow.mid_value
        $pairMidSum = $upMid + $downMid
        $pairGap = [Math]::Abs([double]([decimal]1 - $pairMidSum))
        $upRow.counterpart_outcome = 'DOWN'
        $upRow.counterpart_mid = Format-Btc15mDecimal -Value $downMid
        $upRow.pair_mid_sum = Format-Btc15mDecimal -Value $pairMidSum
        $upRow.pair_mid_gap_from_one = Format-Btc15mDecimal -Value ([decimal]$pairGap)
        $downRow.counterpart_outcome = 'UP'
        $downRow.counterpart_mid = Format-Btc15mDecimal -Value $upMid
        $downRow.pair_mid_sum = Format-Btc15mDecimal -Value $pairMidSum
        $downRow.pair_mid_gap_from_one = Format-Btc15mDecimal -Value ([decimal]$pairGap)
    }

    Add-Btc15mSequentialFeatures -Rows ([object[]]$rows.ToArray())

    $sortedRows = @($rows | Sort-Object `
        @{ Expression = { $_.canonical_window_start_utc }; Ascending = $true }, `
        @{ Expression = { $_.source_capture_run_id }; Ascending = $true }, `
        @{ Expression = { [int]$_.synchronized_cycle_ordinal }; Ascending = $true }, `
        @{ Expression = { if ($_.outcome -ceq 'UP') { 0 } else { 1 } }; Ascending = $true })

    return [pscustomobject]@{
        dataset_report = $datasetReport
        run_rows = @($runRows)
        excluded_rows = @($excludedRows)
        derived_rows = @($sortedRows)
    }
}

function Remove-Btc15mInternalProperties {
    param([Parameter(Mandatory)][object[]]$Rows)

    $cleanRows = [System.Collections.Generic.List[object]]::new()
    foreach ($rowItem in $Rows) {
        $cleanRows.Add([pscustomobject]@{
            source_dataset_id = $rowItem.source_dataset_id
            source_zip_sha256 = $rowItem.source_zip_sha256
            source_capture_run_id = $rowItem.source_capture_run_id
            source_bundle_sha256 = $rowItem.source_bundle_sha256
            canonical_window_start_utc = $rowItem.canonical_window_start_utc
            canonical_window_end_utc = $rowItem.canonical_window_end_utc
            run_ordinal = $rowItem.run_ordinal
            synchronized_cycle_ordinal = $rowItem.synchronized_cycle_ordinal
            observation_ordinal_within_outcome = $rowItem.observation_ordinal_within_outcome
            observation_timestamp_utc = $rowItem.observation_timestamp_utc
            outcome = $rowItem.outcome
            token_id = $rowItem.token_id
            best_bid = $rowItem.best_bid
            best_ask = $rowItem.best_ask
            spread = $rowItem.spread
            mid = $rowItem.mid
            bid_level_count = $rowItem.bid_level_count
            ask_level_count = $rowItem.ask_level_count
            best_bid_size = $rowItem.best_bid_size
            best_ask_size = $rowItem.best_ask_size
            request_latency_ms = $rowItem.request_latency_ms
            counterpart_outcome = $rowItem.counterpart_outcome
            counterpart_mid = $rowItem.counterpart_mid
            pair_mid_sum = $rowItem.pair_mid_sum
            pair_mid_gap_from_one = $rowItem.pair_mid_gap_from_one
            token_mid_return_1 = $rowItem.token_mid_return_1
            token_mid_rsi_14 = $rowItem.token_mid_rsi_14
            token_mid_rsi_status = $rowItem.token_mid_rsi_status
            time_remaining_seconds = $rowItem.time_remaining_seconds
            row_readiness = $rowItem.row_readiness
        })
    }

    return [object[]]$cleanRows.ToArray()
}

function Get-Btc15mNullCounts {
    param(
        [Parameter(Mandatory)][object[]]$Rows,
        [Parameter(Mandatory)][string[]]$Columns
    )

    $nullCounts = [ordered]@{}
    foreach ($columnName in $Columns) {
        $nullCount = 0
        foreach ($rowItem in $Rows) {
            $propertyValue = Get-Btc15mProperty -SourceObject $rowItem -PropertyName $columnName
            if ($null -eq $propertyValue -or [string]::IsNullOrWhiteSpace([string]$propertyValue)) {
                $nullCount++
            }
        }
        $nullCounts[$columnName] = $nullCount
    }

    return $nullCounts
}

function Write-Btc15mDerivedBundle {
    param(
        [Parameter(Mandatory)][string]$ZipPath,
        [Parameter(Mandatory)][string]$DestinationDirectory
    )

    if ($PSVersionTable.PSVersion.Major -lt 7) {
        throw 'POWERSHELL_7_REQUIRED'
    }

    if (-not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) {
        throw ("INPUT_ZIP_NOT_FOUND:{0}" -f $ZipPath)
    }

    if (Test-Path -LiteralPath $DestinationDirectory) {
        throw ("OUTPUT_DIRECTORY_ALREADY_EXISTS:{0}" -f $DestinationDirectory)
    }

    $destinationParent = Split-Path -Parent $DestinationDirectory
    if ([string]::IsNullOrWhiteSpace($destinationParent)) {
        throw 'OUTPUT_PARENT_REQUIRED'
    }
    if (-not (Test-Path -LiteralPath $destinationParent -PathType Container)) {
        throw ("OUTPUT_PARENT_NOT_FOUND:{0}" -f $destinationParent)
    }

    $destinationLeaf = Split-Path -Leaf $DestinationDirectory
    $stagingDirectory = Join-Path $destinationParent ('.' + $destinationLeaf + '.staging')
    if (Test-Path -LiteralPath $stagingDirectory) {
        Remove-Item -LiteralPath $stagingDirectory -Recurse -Force
    }

    $sourceHashBefore = Get-Btc15mFileSha256Lower -Path $ZipPath
    New-Item -ItemType Directory -Path $stagingDirectory | Out-Null
    try {
        $bundleData = New-Btc15mDerivedRows -ZipPath $ZipPath -SourceZipSha256 $sourceHashBefore
        $rowsWithInternal = @($bundleData.derived_rows)
        $cleanRows = @(Remove-Btc15mInternalProperties -Rows $rowsWithInternal)
        $columns = @(Get-Btc15mCsvColumns)

        $csvLines = [System.Collections.Generic.List[string]]::new()
        $csvLines.Add([string]::Join(',', $columns))
        foreach ($rowItem in $cleanRows) {
            $csvLines.Add((ConvertTo-Btc15mCsvLine -RowObject $rowItem -Columns $columns))
        }

        $csvContent = [string]::Join("`n", @($csvLines)) + "`n"
        $csvPath = Join-Path $stagingDirectory 'derived_snapshot_features.csv'
        Set-Btc15mUtf8NoBomFile -Path $csvPath -Content $csvContent

        $schemaObject = [pscustomobject]@{
            schema_id = 'BTC15M_DERIVED_SNAPSHOT_FEATURES_SCHEMA_V1'
            column_count = $columns.Count
            columns = @(New-Btc15mSchemaColumns)
        }
        $schemaPath = Join-Path $stagingDirectory 'schema.json'
        Set-Btc15mUtf8NoBomFile -Path $schemaPath -Content (($schemaObject | ConvertTo-Json -Depth 20) + "`n")

        $runIds = @($cleanRows | ForEach-Object { $_.source_capture_run_id } | Sort-Object -Unique)
        $upRows = @($cleanRows | Where-Object { $_.outcome -ceq 'UP' })
        $downRows = @($cleanRows | Where-Object { $_.outcome -ceq 'DOWN' })
        $cycleKeys = @($cleanRows | ForEach-Object { '{0}|{1}' -f $_.source_capture_run_id, $_.synchronized_cycle_ordinal } | Sort-Object -Unique)
        $summaryObject = [pscustomobject]@{
            schema_id = 'BTC15M_DERIVED_SNAPSHOT_FEATURES_V1'
            result = 'PASS'
            source_dataset_id = [string]$bundleData.dataset_report.dataset_id
            source_zip_sha256 = $sourceHashBefore
            row_count = $cleanRows.Count
            run_count = $runIds.Count
            up_row_count = $upRows.Count
            down_row_count = $downRows.Count
            synchronized_cycle_count = $cycleKeys.Count
            column_count = $columns.Count
            excluded_run_count = @($bundleData.excluded_rows).Count
            null_counts = Get-Btc15mNullCounts -Rows $cleanRows -Columns $columns
            feature_family_status = Get-Btc15mFeatureFamilyStatus
            statistical_readiness = 'PARTIAL'
            simulation_engineering_ready = $true
            source_mutated = $false
        }
        $summaryPath = Join-Path $stagingDirectory 'summary.json'
        Set-Btc15mUtf8NoBomFile -Path $summaryPath -Content (($summaryObject | ConvertTo-Json -Depth 30) + "`n")

        $outputFilesBeforeManifest = @('derived_snapshot_features.csv', 'schema.json', 'summary.json')
        $fileRows = [System.Collections.Generic.List[object]]::new()
        foreach ($fileName in $outputFilesBeforeManifest) {
            $filePath = Join-Path $stagingDirectory $fileName
            $fileRows.Add([pscustomobject]@{
                name = $fileName
                sha256 = Get-Btc15mFileSha256Lower -Path $filePath
                size_bytes = (Get-Item -LiteralPath $filePath).Length
            })
        }

        $manifestObject = [pscustomobject]@{
            schema_id = 'BTC15M_DERIVED_FEATURE_BUNDLE_MANIFEST_V1'
            bundle_id = 'BTC15M_DERIVED_FEATURES_FROM_V4_V2'
            source_dataset_id = [string]$bundleData.dataset_report.dataset_id
            source_zip_sha256 = $sourceHashBefore
            extractor_version = 'offline-derived-feature-extraction-v1'
            deterministic_ordering_contract = @(
                'canonical_window_start_utc',
                'source_capture_run_id',
                'synchronized_cycle_ordinal',
                'outcome_UP_before_DOWN'
            )
            row_count = $cleanRows.Count
            run_count = $runIds.Count
            synchronized_cycle_count = $cycleKeys.Count
            csv_line_count = $csvLines.Count
            output_files = @($fileRows)
            feature_family_status = Get-Btc15mFeatureFamilyStatus
            guardrails = @(
                'offline_only',
                'source_zip_read_only',
                'no_network',
                'no_packages',
                'no_real_trading',
                'no_dynamic_generation_timestamps',
                'manifest_excludes_own_hash'
            )
            source_mutated = $false
        }
        $manifestPath = Join-Path $stagingDirectory 'manifest.json'
        Set-Btc15mUtf8NoBomFile -Path $manifestPath -Content (($manifestObject | ConvertTo-Json -Depth 30) + "`n")

        Move-Item -LiteralPath $stagingDirectory -Destination $DestinationDirectory
        $sourceHashAfter = Get-Btc15mFileSha256Lower -Path $ZipPath
        $resultObject = [pscustomobject]@{
            schema_id = 'BTC15M_DERIVED_FEATURE_EXTRACTION_RESULT_V1'
            result = 'PASS'
            output_directory = $DestinationDirectory
            source_dataset_id = [string]$bundleData.dataset_report.dataset_id
            source_zip_sha256_before = $sourceHashBefore
            source_zip_sha256_after = $sourceHashAfter
            row_count = $cleanRows.Count
            run_count = $runIds.Count
            up_row_count = $upRows.Count
            down_row_count = $downRows.Count
            synchronized_cycle_count = $cycleKeys.Count
            output_file_set = @('derived_snapshot_features.csv','manifest.json','schema.json','summary.json')
            source_mutated = ($sourceHashBefore -ne $sourceHashAfter)
        }

        return $resultObject
    }
    catch {
        if (Test-Path -LiteralPath $stagingDirectory) {
            Remove-Item -LiteralPath $stagingDirectory -Recurse -Force
        }
        throw
    }
}

if (-not $LoadOnly) {
    try {
        if ([string]::IsNullOrWhiteSpace($InputZip)) {
            throw 'INPUT_ZIP_REQUIRED'
        }
        if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
            throw 'OUTPUT_DIRECTORY_REQUIRED'
        }

        $result = Write-Btc15mDerivedBundle -ZipPath $InputZip -DestinationDirectory $OutputDirectory
        $result | ConvertTo-Json -Depth 20
        if ($result.result -ceq 'PASS' -and -not $result.source_mutated) {
            exit 0
        }
        exit 1
    }
    catch {
        $failureObject = [pscustomobject]@{
            schema_id = 'BTC15M_DERIVED_FEATURE_EXTRACTION_RESULT_V1'
            result = 'NO_PASS'
            error_code = 'EXTRACTION_FAILED'
            error_message = $_.Exception.Message
            source_mutated = $false
        }
        $failureObject | ConvertTo-Json -Depth 10
        exit 1
    }
}
