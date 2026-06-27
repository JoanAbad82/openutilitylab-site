<#
.SYNOPSIS
Self-contained tests for offline-derived-feature-extraction.ps1.
#>

[CmdletBinding()]
param(
    [string]$DatasetZipPath = 'C:\Users\JoanAB\Documents\BTC_15M_ARENA_OPERATIONS\10_ACTIVE\INPUTS\MULTI_RUN_DATASETS\BTC15M_MULTI_RUN_20260626T231745Z_V4.zip',
    [string]$ExpectedDatasetSha256 = 'dd4aa16e01b58fc52e49689fa14de11a805cc725917447314a2dc74a92a2a157'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot 'offline-derived-feature-extraction.ps1'
$tempRootPath = Join-Path $PSScriptRoot '.codex-tmp-derived-feature-extraction-v2'
$testRows = [System.Collections.Generic.List[object]]::new()

function Add-TestResult {
    param(
        [string]$Name,
        [bool]$Pass,
        [string]$Detail = ''
    )

    $testRows.Add([pscustomobject]@{
        name = $Name
        pass = $Pass
        detail = $Detail
    })
    if (-not $Pass) {
        throw ("TEST_FAILED:{0}:{1}" -f $Name, $Detail)
    }
}

function Assert-Equal {
    param(
        [string]$Name,
        [object]$Actual,
        [object]$Expected
    )

    Add-TestResult -Name $Name -Pass ([string]$Actual -ceq [string]$Expected) -Detail ("actual={0};expected={1}" -f $Actual, $Expected)
}

function Assert-True {
    param(
        [string]$Name,
        [bool]$Condition,
        [string]$Detail = ''
    )

    Add-TestResult -Name $Name -Pass $Condition -Detail $Detail
}

function Test-PowerShellParse {
    param([string]$Path)

    $parseTokens = $null
    $parseProblems = $null
    [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$parseTokens, [ref]$parseProblems) | Out-Null
    return @($parseProblems)
}

function Get-FileHashLower {
    param([string]$Path)

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Read-CsvRows {
    param([string]$Path)

    return @((Get-Content -LiteralPath $Path -Raw) | ConvertFrom-Csv)
}

function Get-OutputHashes {
    param([string]$DirectoryPath)

    $hashRows = [ordered]@{}
    foreach ($fileName in @('derived_snapshot_features.csv','manifest.json','schema.json','summary.json')) {
        $hashRows[$fileName] = Get-FileHashLower -Path (Join-Path $DirectoryPath $fileName)
    }
    return $hashRows
}

function Assert-OutputHashesEqual {
    param(
        [string]$Name,
        [object]$Left,
        [object]$Right
    )

    $allEqual = $true
    foreach ($fileName in @('derived_snapshot_features.csv','manifest.json','schema.json','summary.json')) {
        if ($Left[$fileName] -cne $Right[$fileName]) {
            $allEqual = $false
        }
    }
    Assert-True -Name $Name -Condition $allEqual
}

function Invoke-ExtractorForTest {
    param(
        [string]$OutputPath,
        [string]$StdoutPath,
        [string]$StderrPath
    )

    $extractorOutput = & pwsh -NoProfile -File $scriptPath -InputZip $DatasetZipPath -OutputDirectory $OutputPath 2> $StderrPath
    $extractorExitCode = $LASTEXITCODE
    $extractorOutput | Set-Content -LiteralPath $StdoutPath -Encoding utf8NoBOM
    return [pscustomobject]@{
        exit_code = $extractorExitCode
        stdout = [string](Get-Content -LiteralPath $StdoutPath -Raw)
        stderr = [string](Get-Content -LiteralPath $StderrPath -Raw)
    }
}

function ConvertTo-TestUtcText {
    param([string]$Value)

    $dateTimeOffsetValue = [System.DateTimeOffset]::Parse($Value, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None)
    return $dateTimeOffsetValue.ToUniversalTime().UtcDateTime.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ', [System.Globalization.CultureInfo]::InvariantCulture)
}

function ConvertTo-TestUtcDate {
    param([string]$Value)

    $dateTimeOffsetValue = [System.DateTimeOffset]::Parse($Value, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None)
    return $dateTimeOffsetValue.ToUniversalTime().UtcDateTime
}

function Get-SourceJoinKey {
    param([object]$SourceRow)

    $captureRunId = [string](Get-Btc15mProperty -SourceObject $SourceRow -PropertyName 'source_capture_run_id')
    if ([string]::IsNullOrWhiteSpace($captureRunId)) {
        $captureRunId = [string](Get-Btc15mProperty -SourceObject $SourceRow -PropertyName 'capture_run_id')
    }
    return '{0}|{1}|{2}|{3}' -f $captureRunId, $SourceRow.cycle_sequence, $SourceRow.token_side, $SourceRow.token_id
}

function Get-CandidateJoinKey {
    param([object]$CandidateRow)

    return '{0}|{1}|{2}|{3}' -f $CandidateRow.source_capture_run_id, $CandidateRow.synchronized_cycle_ordinal, $CandidateRow.outcome, $CandidateRow.token_id
}

function Get-CandidateV1Hashes {
    param([string]$CandidateRoot)

    $hashRows = [ordered]@{}
    foreach ($fileName in @('derived_snapshot_features.csv','manifest.json','schema.json','summary.json')) {
        $hashRows[$fileName] = Get-FileHashLower -Path (Join-Path $CandidateRoot $fileName)
    }
    return $hashRows
}

if (Test-Path -LiteralPath $tempRootPath) {
    Remove-Item -LiteralPath $tempRootPath -Recurse -Force
}
New-Item -ItemType Directory -Path $tempRootPath | Out-Null

try {
    . $scriptPath -LoadOnly

    $pointerPath = 'C:\Users\JoanAB\Documents\BTC_15M_ARENA_OPERATIONS\10_ACTIVE\INPUTS\MULTI_RUN_DATASETS\CANONICAL_BASELINE.json'
    $baselineRegistryPath = 'C:\Users\JoanAB\Documents\BTC_15M_ARENA_OPERATIONS\10_ACTIVE\INPUTS\MULTI_RUN_DATASETS\BASELINE_REGISTRY.csv'
    $artifactRegistryPath = 'C:\Users\JoanAB\Documents\BTC_15M_ARENA_OPERATIONS\10_ACTIVE\ARTIFACT_REGISTRY.csv'
    $candidateV1Root = 'C:\Users\JoanAB\Documents\BTC_15M_ARENA_OPERATIONS\30_REPORTS\DERIVED_FEATURE_DATASETS\BTC15M_DERIVED_FEATURES_FROM_V4_V1'
    $candidateV1ExpectedHashes = [ordered]@{
        'derived_snapshot_features.csv' = '200c7e4d5698623012a117490c80e9f6e415c17b1e4540339a45998920be42e0'
        'manifest.json' = '5c01bdf94afb49ba2cf0368e218eb59071498931f1dea84eb4beef2497c0f917'
        'schema.json' = '8ea2f80c667b0b40ac38b391f44614b5362521890b9c25001e8da8729f4acf5f'
        'summary.json' = '6e750dd5b2db67a24273dd5122208f124010ee0b123fcb7e9b0401d3b65eca2b'
    }
    $sourceHashBefore = Get-FileHashLower -Path $DatasetZipPath
    $pointerHashBefore = Get-FileHashLower -Path $pointerPath
    $baselineRegistryHashBefore = Get-FileHashLower -Path $baselineRegistryPath
    $artifactRegistryHashBefore = Get-FileHashLower -Path $artifactRegistryPath
    $candidateV1HashesBefore = Get-CandidateV1Hashes -CandidateRoot $candidateV1Root

    Assert-True -Name 'entrypoint_exists' -Condition (Test-Path -LiteralPath $scriptPath -PathType Leaf)
    Assert-Equal -Name 'entrypoint_ast_parse' -Actual (@(Test-PowerShellParse -Path $scriptPath).Count) -Expected 0
    Assert-Equal -Name 'tests_ast_parse' -Actual (@(Test-PowerShellParse -Path $PSCommandPath).Count) -Expected 0
    Assert-Equal -Name 'source_zip_expected_hash' -Actual $sourceHashBefore -Expected $ExpectedDatasetSha256

    $resolvedTempRootPath = [System.IO.Path]::GetFullPath($tempRootPath)
    $resolvedScriptRootPath = [System.IO.Path]::GetFullPath($PSScriptRoot)
    Assert-True -Name 'temp_root_exact_authorized_path' -Condition (
        [System.IO.Directory]::GetParent($resolvedTempRootPath).FullName -ceq $resolvedScriptRootPath -and
        [System.IO.Path]::GetFileName($resolvedTempRootPath) -ceq '.codex-tmp-derived-feature-extraction-v2'
    ) -Detail $resolvedTempRootPath

    $scriptSource = Get-Content -LiteralPath $scriptPath -Raw
    $testSource = Get-Content -LiteralPath $PSCommandPath -Raw
    $historicalPattern = @(
        '01' + '_RUNNER_BTC15M',
        'RUNNER' + '_BTC15M_V4',
        'Expected' + 'PreviousStandaloneRunnerSha256',
        'Down' + 'loads'
    ) | ForEach-Object { [regex]::Escape($_) }
    $networkPattern = @(
        'Invoke' + '-WebRequest',
        'Invoke' + '-RestMethod',
        'Http' + 'Client',
        'Web' + 'Client',
        'cu' + 'rl',
        'wg' + 'et'
    ) | ForEach-Object { [regex]::Escape($_) }
    $tradingPattern = @(
        'private' + '_key',
        'wall' + 'et',
        'place' + '_order',
        'create' + '_order',
        'authenticated'
    ) | ForEach-Object { [regex]::Escape($_) }
    Assert-True -Name 'no_historical_runner_dependencies' -Condition (-not ($scriptSource -match ([string]::Join('|', @($historicalPattern)))))
    Assert-True -Name 'no_network_calls' -Condition (-not ($scriptSource -match ([string]::Join('|', @($networkPattern)))))
    Assert-True -Name 'no_auth_or_trade_execution_logic' -Condition (-not ($scriptSource -match ([string]::Join('|', @($tradingPattern)))))
    Assert-True -Name 'suite_temp_assignment_exact' -Condition ($testSource.Contains('$tempRootPath = Join-Path $PSScriptRoot ''.codex-tmp-derived-feature-extraction-v2'''))
    $badTempVariable = [regex]::Escape(('$' + 'env' + ':TEMP'))
    $badTmpVariable = [regex]::Escape(('$' + 'env' + ':TMP'))
    $badTempApi = 'Get' + 'Temp' + 'Path'
    Assert-True -Name 'suite_no_external_temp_api' -Condition (-not ($testSource -match ($badTempVariable + '|' + $badTmpVariable + '|' + $badTempApi)))

    $outOne = Join-Path $tempRootPath 'out-one'
    $outTwo = Join-Path $tempRootPath 'out-two'
    $stdoutOne = Join-Path $tempRootPath 'extract-one.stdout.json'
    $stderrOne = Join-Path $tempRootPath 'extract-one.stderr.txt'
    $stdoutTwo = Join-Path $tempRootPath 'extract-two.stdout.json'
    $stderrTwo = Join-Path $tempRootPath 'extract-two.stderr.txt'
    $resultOne = Invoke-ExtractorForTest -OutputPath $outOne -StdoutPath $stdoutOne -StderrPath $stderrOne
    $jsonOne = $resultOne.stdout | ConvertFrom-Json -Depth 100
    $resultTwo = Invoke-ExtractorForTest -OutputPath $outTwo -StdoutPath $stdoutTwo -StderrPath $stderrTwo
    $jsonTwo = $resultTwo.stdout | ConvertFrom-Json -Depth 100

    Assert-Equal -Name 'real_v4_extraction_pass' -Actual $jsonOne.result -Expected 'PASS'
    Assert-Equal -Name 'extractor_exit_code_zero' -Actual $resultOne.exit_code -Expected 0
    Assert-True -Name 'stdout_single_json_stderr_empty' -Condition ($resultOne.stdout.TrimStart().StartsWith('{') -and $resultOne.stdout.TrimEnd().EndsWith('}') -and [string]::IsNullOrWhiteSpace($resultOne.stderr))
    Assert-True -Name 'second_stdout_single_json_stderr_empty' -Condition ($resultTwo.stdout.TrimStart().StartsWith('{') -and $resultTwo.stdout.TrimEnd().EndsWith('}') -and [string]::IsNullOrWhiteSpace($resultTwo.stderr))

    $csvPath = Join-Path $outOne 'derived_snapshot_features.csv'
    $schemaPath = Join-Path $outOne 'schema.json'
    $summaryPath = Join-Path $outOne 'summary.json'
    $manifestPath = Join-Path $outOne 'manifest.json'
    $csvText = Get-Content -LiteralPath $csvPath -Raw
    $csvLines = @($csvText -split "`n" | Where-Object { $_ -ne '' })
    $headerColumns = @($csvLines[0].Split(','))
    $rows = @(Read-CsvRows -Path $csvPath)
    $schema = Get-Content -LiteralPath $schemaPath -Raw | ConvertFrom-Json -Depth 100
    $summary = Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json -Depth 100
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json -Depth 100

    Assert-Equal -Name 'real_v4_row_count_594' -Actual $rows.Count -Expected 594
    Assert-Equal -Name 'real_v4_run_count_9' -Actual $summary.run_count -Expected 9
    Assert-True -Name 'real_v4_up_down_297_each' -Condition ((@($rows | Where-Object outcome -eq 'UP').Count -eq 297) -and (@($rows | Where-Object outcome -eq 'DOWN').Count -eq 297))
    Assert-Equal -Name 'real_v4_cycle_count_297' -Actual $summary.synchronized_cycle_count -Expected 297
    Assert-Equal -Name 'csv_30_columns' -Actual $headerColumns.Count -Expected 30
    Assert-Equal -Name 'csv_595_lines' -Actual $csvLines.Count -Expected 595
    Assert-Equal -Name 'schema_30_columns' -Actual $schema.columns.Count -Expected 30
    Assert-Equal -Name 'schema_id_expected' -Actual $schema.schema_id -Expected 'BTC15M_DERIVED_SNAPSHOT_FEATURES_SCHEMA_V1'
    Assert-Equal -Name 'summary_id_expected' -Actual $summary.schema_id -Expected 'BTC15M_DERIVED_SNAPSHOT_FEATURES_V1'
    Assert-Equal -Name 'manifest_id_expected' -Actual $manifest.schema_id -Expected 'BTC15M_DERIVED_FEATURE_BUNDLE_MANIFEST_V1'
    Assert-Equal -Name 'manifest_bundle_id_expected' -Actual $manifest.bundle_id -Expected 'BTC15M_DERIVED_FEATURES_FROM_V4_V2'
    Assert-Equal -Name 'four_outputs_exact' -Actual (@(Get-ChildItem -LiteralPath $outOne -File | Sort-Object Name | ForEach-Object Name) -join '|') -Expected 'derived_snapshot_features.csv|manifest.json|schema.json|summary.json'
    Assert-Equal -Name 'unique_runs_9' -Actual (@($rows | ForEach-Object source_capture_run_id | Sort-Object -Unique).Count) -Expected 9

    $cycleGroups = @($rows | Group-Object source_capture_run_id, synchronized_cycle_ordinal)
    Assert-True -Name 'cycles_two_rows_each' -Condition (@($cycleGroups | Where-Object { $_.Count -ne 2 }).Count -eq 0)
    Assert-True -Name 'outcomes_up_down_only' -Condition (@($rows | Where-Object { $_.outcome -notin @('UP','DOWN') }).Count -eq 0)
    Assert-True -Name 'deterministic_order' -Condition (($rows[0].outcome -eq 'UP') -and ($rows[1].outcome -eq 'DOWN') -and ([int]$rows[0].synchronized_cycle_ordinal -eq 1))

    $firstRow = $rows[0]
    $computedSpread = Format-Btc15mDecimal -Value ((ConvertTo-Btc15mInvariantDecimal $firstRow.best_ask) - (ConvertTo-Btc15mInvariantDecimal $firstRow.best_bid))
    $computedMid = Format-Btc15mDecimal -Value (((ConvertTo-Btc15mInvariantDecimal $firstRow.best_ask) + (ConvertTo-Btc15mInvariantDecimal $firstRow.best_bid)) / 2)
    Assert-Equal -Name 'spread_formula_first_row' -Actual $firstRow.spread -Expected $computedSpread
    Assert-Equal -Name 'mid_formula_first_row' -Actual $firstRow.mid -Expected $computedMid
    Assert-True -Name 'pair_coherence_first_cycle' -Condition ($rows[0].counterpart_outcome -eq 'DOWN' -and $rows[1].counterpart_outcome -eq 'UP' -and $rows[0].pair_mid_sum -eq $rows[1].pair_mid_sum)

    $groupedByRunOutcome = @($rows | Group-Object source_capture_run_id, outcome)
    Assert-True -Name 'returns_reset_per_run_and_outcome' -Condition (@($groupedByRunOutcome | Where-Object { @($_.Group | Sort-Object observation_ordinal_within_outcome)[0].token_mid_return_1 -ne '' }).Count -eq 0)
    Assert-True -Name 'rsi_resets_per_run_and_outcome' -Condition (@($groupedByRunOutcome | Where-Object { @($_.Group | Sort-Object @{ Expression = { [int]$_.observation_ordinal_within_outcome }; Ascending = $true } | Select-Object -First 14 | Where-Object { $_.token_mid_rsi_14 -ne '' }).Count -ne 0 }).Count -eq 0)
    Assert-True -Name 'first_14_rsi_null' -Condition (@($rows | Where-Object { [int]$_.observation_ordinal_within_outcome -le 14 -and $_.token_mid_rsi_14 -ne '' }).Count -eq 0)
    Assert-True -Name 'later_rsi_range_0_100' -Condition (@($rows | Where-Object { $_.token_mid_rsi_14 -ne '' -and ((ConvertTo-Btc15mInvariantDecimal $_.token_mid_rsi_14) -lt 0 -or (ConvertTo-Btc15mInvariantDecimal $_.token_mid_rsi_14) -gt 100) }).Count -eq 0)
    Assert-True -Name 'no_future_leakage' -Condition (@($groupedByRunOutcome | Where-Object { @($_.Group | Sort-Object observation_ordinal_within_outcome)[0].token_mid_return_1 -ne '' }).Count -eq 0)
    Assert-True -Name 'optional_nulls_permitted' -Condition ($summary.null_counts.token_mid_return_1 -eq 18 -and $summary.null_counts.token_mid_rsi_14 -eq 252)
    $numericColumns = @('best_bid','best_ask','spread','mid','best_bid_size','best_ask_size','counterpart_mid','pair_mid_sum','pair_mid_gap_from_one','token_mid_return_1','token_mid_rsi_14','time_remaining_seconds')
    $decimalCommaCount = 0
    foreach ($numericRow in $rows) {
        foreach ($numericColumn in $numericColumns) {
            $numericValue = [string](Get-Btc15mProperty -SourceObject $numericRow -PropertyName $numericColumn)
            if ($numericValue.Contains(',')) {
                $decimalCommaCount++
            }
        }
    }
    Assert-Equal -Name 'decimal_invariant' -Actual $decimalCommaCount -Expected 0
    Assert-True -Name 'timestamps_utc' -Condition (@($rows | Where-Object { $_.canonical_window_start_utc -notmatch 'Z$' -or $_.observation_timestamp_utc -notmatch 'Z$' }).Count -eq 0)

    $sourceSnapshotText = Read-Btc15mZipEntryText -ZipPath $DatasetZipPath -EntryName 'dataset_snapshots.jsonl'
    $sourceLines = @($sourceSnapshotText -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $sourceRows = [System.Collections.Generic.List[object]]::new()
    foreach ($sourceLine in $sourceLines) {
        $sourceRows.Add(($sourceLine | ConvertFrom-Json -Depth 100 -DateKind String))
    }
    $sourceRecords = [object[]]$sourceRows.ToArray()
    $sourceKeyGroups = @($sourceRecords | Group-Object { Get-SourceJoinKey -SourceRow $_ })
    $candidateKeyGroups = @($rows | Group-Object { Get-CandidateJoinKey -CandidateRow $_ })
    $sourceDuplicateKeyCount = @($sourceKeyGroups | Where-Object { $_.Count -ne 1 }).Count
    $candidateDuplicateKeyCount = @($candidateKeyGroups | Where-Object { $_.Count -ne 1 }).Count
    $sourceByKey = @{}
    foreach ($sourceGroup in $sourceKeyGroups) {
        if ($sourceGroup.Count -eq 1) {
            $sourceByKey[$sourceGroup.Name] = $sourceGroup.Group[0]
        }
    }
    $candidateByKey = @{}
    foreach ($candidateGroup in $candidateKeyGroups) {
        if ($candidateGroup.Count -eq 1) {
            $candidateByKey[$candidateGroup.Name] = $candidateGroup.Group[0]
        }
    }
    $joinedRows = [System.Collections.Generic.List[object]]::new()
    $candidateWithoutSourceCount = 0
    foreach ($candidateRow in $rows) {
        $joinKey = Get-CandidateJoinKey -CandidateRow $candidateRow
        if ($sourceByKey.ContainsKey($joinKey)) {
            $joinedRows.Add([pscustomobject]@{ source = $sourceByKey[$joinKey]; candidate = $candidateRow; key = $joinKey })
        }
        else {
            $candidateWithoutSourceCount++
        }
    }
    $sourceWithoutCandidateCount = 0
    foreach ($sourceRow in $sourceRecords) {
        $joinKey = Get-SourceJoinKey -SourceRow $sourceRow
        if (-not $candidateByKey.ContainsKey($joinKey)) {
            $sourceWithoutCandidateCount++
        }
    }

    $sourceInRangeCount = 0
    $sourceStoredSecondsMismatchCount = 0
    $candidateInRangeCount = 0
    $candidateNegativeCount = 0
    $candidateOver900Count = 0
    $windowStartMatchCount = 0
    $windowEndMatchCount = 0
    $observationMatchCount = 0
    $deltaToleranceCount = 0
    $offset7200SignatureCount = 0
    $observationOutsideWindowCount = 0
    $latencyMismatchCount = 0
    $fractionalObservationCount = 0
    $sourceMinSeconds = [double]::PositiveInfinity
    $sourceMaxSeconds = [double]::NegativeInfinity
    $candidateMinSeconds = [double]::PositiveInfinity
    $candidateMaxSeconds = [double]::NegativeInfinity

    foreach ($joinedRow in $joinedRows) {
        $sourceRow = $joinedRow.source
        $candidateRow = $joinedRow.candidate
        $sourceWindowStartText = ConvertTo-TestUtcText -Value ([string]$sourceRow.market_window_start_utc)
        $sourceWindowEndText = ConvertTo-TestUtcText -Value ([string]$sourceRow.market_window_end_utc)
        $sourceObservationText = ConvertTo-TestUtcText -Value ([string]$sourceRow.response_received_utc)
        $sourceWindowStartDate = ConvertTo-TestUtcDate -Value ([string]$sourceRow.market_window_start_utc)
        $sourceWindowEndDate = ConvertTo-TestUtcDate -Value ([string]$sourceRow.market_window_end_utc)
        $sourceObservationDate = ConvertTo-TestUtcDate -Value ([string]$sourceRow.response_received_utc)
        $candidateWindowStartDate = ConvertTo-TestUtcDate -Value ([string]$candidateRow.canonical_window_start_utc)
        $candidateWindowEndDate = ConvertTo-TestUtcDate -Value ([string]$candidateRow.canonical_window_end_utc)
        $candidateObservationDate = ConvertTo-TestUtcDate -Value ([string]$candidateRow.observation_timestamp_utc)
        $sourceSeconds = ($sourceWindowEndDate - $sourceObservationDate).TotalSeconds
        $candidateSeconds = [double](ConvertTo-Btc15mInvariantDecimal $candidateRow.time_remaining_seconds)
        if ($sourceSeconds -ge 0 -and $sourceSeconds -le 900) { $sourceInRangeCount++ }
        if ($candidateSeconds -ge 0 -and $candidateSeconds -le 900) { $candidateInRangeCount++ }
        if ($candidateSeconds -lt 0) { $candidateNegativeCount++ }
        if ($candidateSeconds -gt 900) { $candidateOver900Count++ }
        if ($sourceWindowStartText -ceq $candidateRow.canonical_window_start_utc) { $windowStartMatchCount++ }
        if ($sourceWindowEndText -ceq $candidateRow.canonical_window_end_utc) { $windowEndMatchCount++ }
        if ($sourceObservationText -ceq $candidateRow.observation_timestamp_utc) { $observationMatchCount++ }
        $timeDelta = [Math]::Abs($candidateSeconds - $sourceSeconds)
        if ($timeDelta -le 0.000001) { $deltaToleranceCount++ }
        if ([Math]::Abs([Math]::Abs($candidateSeconds - $sourceSeconds) - 7200) -le 1) { $offset7200SignatureCount++ }
        if ($candidateObservationDate -lt $candidateWindowStartDate -or $candidateObservationDate -gt $candidateWindowEndDate) { $observationOutsideWindowCount++ }
        if ([int]$candidateRow.request_latency_ms -ne [int]$sourceRow.latency_ms) { $latencyMismatchCount++ }
        $storedSeconds = ConvertTo-Btc15mInvariantDecimal $sourceRow.seconds_to_window_end
        if ([int][Math]::Floor($sourceSeconds) -ne [int]$storedSeconds) { $sourceStoredSecondsMismatchCount++ }
        if ($candidateRow.observation_timestamp_utc -match '\.\d+Z$') { $fractionalObservationCount++ }
        $sourceMinSeconds = [Math]::Min($sourceMinSeconds, $sourceSeconds)
        $sourceMaxSeconds = [Math]::Max($sourceMaxSeconds, $sourceSeconds)
        $candidateMinSeconds = [Math]::Min($candidateMinSeconds, $candidateSeconds)
        $candidateMaxSeconds = [Math]::Max($candidateMaxSeconds, $candidateSeconds)
    }

    Assert-Equal -Name 'source_candidate_join_count_594' -Actual $joinedRows.Count -Expected 594
    Assert-Equal -Name 'source_duplicate_join_keys_0' -Actual $sourceDuplicateKeyCount -Expected 0
    Assert-Equal -Name 'candidate_duplicate_join_keys_0' -Actual $candidateDuplicateKeyCount -Expected 0
    Assert-Equal -Name 'candidate_keys_without_source_0' -Actual $candidateWithoutSourceCount -Expected 0
    Assert-Equal -Name 'source_keys_without_candidate_0' -Actual $sourceWithoutCandidateCount -Expected 0
    Assert-Equal -Name 'source_offset_plus02_normalizes_to_utc' -Actual (ConvertTo-TestUtcText -Value '2026-06-24T19:15:00+02:00') -Expected '2026-06-24T17:15:00.0000000Z'
    Assert-True -Name 'source_offset_not_relabelled_as_utc' -Condition ((ConvertTo-TestUtcText -Value '2026-06-24T19:15:00+02:00') -cne '2026-06-24T19:15:00.0000000Z')
    Assert-Equal -Name 'response_fractional_seconds_preserved' -Actual $fractionalObservationCount -Expected 594
    Assert-Equal -Name 'source_candidate_window_start_instant_match_594' -Actual $windowStartMatchCount -Expected 594
    Assert-Equal -Name 'source_candidate_window_end_instant_match_594' -Actual $windowEndMatchCount -Expected 594
    Assert-Equal -Name 'source_candidate_observation_instant_match_594' -Actual $observationMatchCount -Expected 594
    Assert-Equal -Name 'candidate_time_in_range_594' -Actual $candidateInRangeCount -Expected 594
    Assert-Equal -Name 'candidate_time_negative_0' -Actual $candidateNegativeCount -Expected 0
    Assert-Equal -Name 'candidate_time_over_900_0' -Actual $candidateOver900Count -Expected 0
    Assert-Equal -Name 'candidate_source_time_delta_tolerance_594' -Actual $deltaToleranceCount -Expected 594
    Assert-Equal -Name 'offset_7200_signature_0' -Actual $offset7200SignatureCount -Expected 0
    Assert-Equal -Name 'observation_outside_window_0' -Actual $observationOutsideWindowCount -Expected 0
    Assert-Equal -Name 'source_stored_seconds_mismatch_0' -Actual $sourceStoredSecondsMismatchCount -Expected 0
    Assert-Equal -Name 'source_time_in_range_594' -Actual $sourceInRangeCount -Expected 594
    Assert-Equal -Name 'latency_mismatch_0' -Actual $latencyMismatchCount -Expected 0

    $hashesOne = Get-OutputHashes -DirectoryPath $outOne
    $hashesTwo = Get-OutputHashes -DirectoryPath $outTwo
    Assert-OutputHashesEqual -Name 'deterministic_outputs_byte_identical' -Left $hashesOne -Right $hashesTwo
    Assert-Equal -Name 'second_extraction_pass' -Actual $jsonTwo.result -Expected 'PASS'
    Assert-Equal -Name 'manifest_csv_line_count' -Actual $manifest.csv_line_count -Expected 595
    Assert-True -Name 'manifest_no_self_hash' -Condition (-not (($manifest | ConvertTo-Json -Depth 50) -match 'manifest\\.json.*sha256'))
    Assert-Equal -Name 'feature_status_btc_spot_rsi_not_ready' -Actual $summary.feature_family_status.btc_spot_rsi -Expected 'NOT_READY'
    Assert-Equal -Name 'feature_status_btc_atr_not_ready' -Actual $summary.feature_family_status.btc_atr -Expected 'NOT_READY'
    Assert-Equal -Name 'feature_status_statistical_partial' -Actual $summary.feature_family_status.statistical_model_validation -Expected 'PARTIAL'

    $existingNonempty = Join-Path $tempRootPath 'existing-nonempty'
    New-Item -ItemType Directory -Path $existingNonempty | Out-Null
    Set-Content -LiteralPath (Join-Path $existingNonempty 'sentinel.txt') -Value 'x' -Encoding utf8NoBOM
    $rejectStdout = Join-Path $tempRootPath 'reject.stdout.json'
    $rejectStderr = Join-Path $tempRootPath 'reject.stderr.txt'
    $rejectResult = Invoke-ExtractorForTest -OutputPath $existingNonempty -StdoutPath $rejectStdout -StderrPath $rejectStderr
    $rejectJson = $rejectResult.stdout | ConvertFrom-Json -Depth 20
    Assert-True -Name 'output_directory_existing_nonempty_rejected' -Condition ($rejectResult.exit_code -ne 0 -and $rejectJson.result -eq 'NO_PASS')
    Assert-True -Name 'staging_cleaned_after_error' -Condition (@(Get-ChildItem -LiteralPath $tempRootPath -Directory -Filter '.*.staging' -Force).Count -eq 0)

    $syntheticRows = @(
        [pscustomobject]@{ source_capture_run_id='A'; outcome='UP'; observation_timestamp_utc='2026-01-01T00:00:01.0000000Z'; synchronized_cycle_ordinal=1; mid_value=[decimal]1.00; observation_ordinal_within_outcome=0; token_mid_return_1=''; token_mid_rsi_14=''; token_mid_rsi_status='' },
        [pscustomobject]@{ source_capture_run_id='A'; outcome='UP'; observation_timestamp_utc='2026-01-01T00:00:02.0000000Z'; synchronized_cycle_ordinal=2; mid_value=[decimal]1.10; observation_ordinal_within_outcome=0; token_mid_return_1=''; token_mid_rsi_14=''; token_mid_rsi_status='' },
        [pscustomobject]@{ source_capture_run_id='B'; outcome='UP'; observation_timestamp_utc='2026-01-01T00:00:03.0000000Z'; synchronized_cycle_ordinal=1; mid_value=[decimal]2.00; observation_ordinal_within_outcome=0; token_mid_return_1=''; token_mid_rsi_14=''; token_mid_rsi_status='' }
    )
    Add-Btc15mSequentialFeatures -Rows $syntheticRows
    Assert-Equal -Name 'synthetic_return_formula' -Actual $syntheticRows[1].token_mid_return_1 -Expected '0.1'
    Assert-Equal -Name 'synthetic_return_resets_new_run' -Actual $syntheticRows[2].token_mid_return_1 -Expected ''

    $sourceHashAfter = Get-FileHashLower -Path $DatasetZipPath
    $pointerHashAfter = Get-FileHashLower -Path $pointerPath
    $baselineRegistryHashAfter = Get-FileHashLower -Path $baselineRegistryPath
    $artifactRegistryHashAfter = Get-FileHashLower -Path $artifactRegistryPath
    $candidateV1HashesAfter = Get-CandidateV1Hashes -CandidateRoot $candidateV1Root
    Assert-Equal -Name 'source_zip_unchanged' -Actual $sourceHashAfter -Expected $sourceHashBefore
    Assert-Equal -Name 'pointer_unchanged' -Actual $pointerHashAfter -Expected $pointerHashBefore
    Assert-Equal -Name 'baseline_registry_unchanged' -Actual $baselineRegistryHashAfter -Expected $baselineRegistryHashBefore
    Assert-Equal -Name 'artifact_registry_unchanged' -Actual $artifactRegistryHashAfter -Expected $artifactRegistryHashBefore
    $candidateV1Unchanged = $true
    foreach ($candidateFileName in @('derived_snapshot_features.csv','manifest.json','schema.json','summary.json')) {
        if ($candidateV1HashesBefore[$candidateFileName] -cne $candidateV1ExpectedHashes[$candidateFileName]) { $candidateV1Unchanged = $false }
        if ($candidateV1HashesAfter[$candidateFileName] -cne $candidateV1ExpectedHashes[$candidateFileName]) { $candidateV1Unchanged = $false }
        if ($candidateV1HashesAfter[$candidateFileName] -cne $candidateV1HashesBefore[$candidateFileName]) { $candidateV1Unchanged = $false }
    }
    Assert-True -Name 'v1_candidate_unchanged' -Condition $candidateV1Unchanged
    Assert-Equal -Name 'summary_source_mutated_false' -Actual $summary.source_mutated -Expected 'False'
    Assert-Equal -Name 'jsonOne_source_mutated_false' -Actual $jsonOne.source_mutated -Expected 'False'
    Assert-Equal -Name 'jsonOne_counts' -Actual ("{0}|{1}|{2}|{3}" -f $jsonOne.row_count,$jsonOne.up_row_count,$jsonOne.down_row_count,$jsonOne.synchronized_cycle_count) -Expected '594|297|297|297'

    $summaryResult = [pscustomobject]@{
        schema = 'BTC15M_DERIVED_FEATURE_EXTRACTION_TEST_RESULT_V1'
        result = 'PASS'
        test_count = $testRows.Count
        tests = @($testRows)
    }
    $summaryResult | ConvertTo-Json -Depth 20
    exit 0
}
catch {
    $failureSummary = [pscustomobject]@{
        schema = 'BTC15M_DERIVED_FEATURE_EXTRACTION_TEST_RESULT_V1'
        result = 'NO_PASS'
        error = $_.Exception.Message
        test_count = $testRows.Count
        tests = @($testRows)
    }
    $failureSummary | ConvertTo-Json -Depth 20
    exit 1
}
finally {
    if (Test-Path -LiteralPath $tempRootPath) {
        Remove-Item -LiteralPath $tempRootPath -Recurse -Force
    }
}
