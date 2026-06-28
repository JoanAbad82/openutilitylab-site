<#
.SYNOPSIS
Self-contained tests for offline-derived-replay-simulation.ps1.
#>

#requires -Version 7.0

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot 'offline-derived-replay-simulation.ps1'
$testScriptPath = $PSCommandPath
$repositoryRoot = [System.IO.Path]::GetFullPath('C:\openutilitylab-site')
$expectedHead = '0bb554eebd57420ab14b3a49e7f72dfdd6aace8a'
$tempRootPath = Join-Path (Join-Path $repositoryRoot '.tmp') 'btc15m-replay-simulation-v1-tests'
$historicalDefectiveTempPath = $repositoryRoot + '.tmp\btc15m-replay-simulation-v1-tests'
$canonicalPointerPath = 'C:\Users\JoanAB\Documents\BTC_15M_ARENA_OPERATIONS\10_ACTIVE\INPUTS\DERIVED_FEATURE_DATASETS\CANONICAL_DERIVED_BASELINE.json'
$canonicalBundleDirectory = 'C:\Users\JoanAB\Documents\BTC_15M_ARENA_OPERATIONS\10_ACTIVE\INPUTS\DERIVED_FEATURE_DATASETS\BTC15M_DERIVED_FEATURES_FROM_V4_V2'
$protectedArtifacts = [ordered]@{
    'raw_canonical_v4_zip' = 'C:\Users\JoanAB\Documents\BTC_15M_ARENA_OPERATIONS\10_ACTIVE\INPUTS\MULTI_RUN_DATASETS\BTC15M_MULTI_RUN_20260626T231745Z_V4.zip'
    'raw_canonical_pointer' = 'C:\Users\JoanAB\Documents\BTC_15M_ARENA_OPERATIONS\10_ACTIVE\INPUTS\MULTI_RUN_DATASETS\CANONICAL_BASELINE.json'
    'raw_baseline_registry' = 'C:\Users\JoanAB\Documents\BTC_15M_ARENA_OPERATIONS\10_ACTIVE\INPUTS\MULTI_RUN_DATASETS\BASELINE_REGISTRY.csv'
    'artifact_registry' = 'C:\Users\JoanAB\Documents\BTC_15M_ARENA_OPERATIONS\10_ACTIVE\ARTIFACT_REGISTRY.csv'
    'canonical_derived_pointer' = $canonicalPointerPath
    'derived_baseline_registry' = 'C:\Users\JoanAB\Documents\BTC_15M_ARENA_OPERATIONS\10_ACTIVE\INPUTS\DERIVED_FEATURE_DATASETS\DERIVED_BASELINE_REGISTRY.csv'
    'derived_snapshot_features' = Join-Path $canonicalBundleDirectory 'derived_snapshot_features.csv'
    'derived_manifest' = Join-Path $canonicalBundleDirectory 'manifest.json'
    'derived_schema' = Join-Path $canonicalBundleDirectory 'schema.json'
    'derived_summary' = Join-Path $canonicalBundleDirectory 'summary.json'
}
$expectedRepairedSummarySha256 = '35aecb2988dc652b15ff492788a39b72a439f19b2fa0615f1ef19a82d18a327a'

$testRows = [System.Collections.Generic.List[object]]::new()

function Add-TestResult {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][bool]$Pass,
        [string]$Detail = ''
    )

    $script:testRows.Add([pscustomobject][ordered]@{
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
        [Parameter(Mandatory)][string]$Name,
        [AllowNull()][object]$Actual,
        [AllowNull()][object]$Expected
    )

    $actualText = [string]$Actual
    $expectedText = [string]$Expected
    $detailText = if (($actualText.Length + $expectedText.Length) -gt 500) {
        'actual_length={0};expected_length={1}' -f $actualText.Length, $expectedText.Length
    }
    else {
        'actual={0};expected={1}' -f $actualText, $expectedText
    }
    Add-TestResult -Name $Name -Pass ($actualText -ceq $expectedText) -Detail $detailText
}

function Assert-True {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][bool]$Condition,
        [string]$Detail = ''
    )

    Add-TestResult -Name $Name -Pass $Condition -Detail $Detail
}

function Assert-ThrowsLike {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][scriptblock]$ScriptBlock,
        [Parameter(Mandatory)][string]$ExpectedFragment
    )

    try {
        & $ScriptBlock | Out-Null
        Add-TestResult -Name $Name -Pass $false -Detail 'no exception'
    }
    catch {
        Add-TestResult -Name $Name -Pass ($_.Exception.Message.Contains($ExpectedFragment)) -Detail $_.Exception.Message
    }
}

function Get-FileHashLower {
    param([Parameter(Mandatory)][string]$Path)

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-TextFileProfile {
    param([Parameter(Mandatory)][string]$Path)

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    return [pscustomobject][ordered]@{
        bytes = $bytes.Length
        sha256 = Get-FileHashLower -Path $Path
        has_utf8_bom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xef -and $bytes[1] -eq 0xbb -and $bytes[2] -eq 0xbf)
        crlf_count = [regex]::Matches($text, "`r`n").Count
        cr_only_count = [regex]::Matches($text, "`r(?!`n)").Count
        lf_only_count = [regex]::Matches($text, "(?<!`r)`n").Count
        exactly_one_terminal_lf = ($bytes.Length -ge 1 -and $bytes[-1] -eq 10 -and ($bytes.Length -lt 2 -or $bytes[-2] -ne 10) -and ($bytes.Length -lt 2 -or $bytes[-2] -ne 13))
    }
}

function Get-ProtectedHashes {
    $hashes = [ordered]@{}
    foreach ($artifactName in $protectedArtifacts.Keys) {
        $hashes[$artifactName] = Get-FileHashLower -Path $protectedArtifacts[$artifactName]
    }
    return $hashes
}

function Test-PowerShellParse {
    param([Parameter(Mandatory)][string]$Path)

    $parseTokens = $null
    $parseProblems = $null
    [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$parseTokens, [ref]$parseProblems) | Out-Null
    return @($parseProblems)
}

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Content
    )

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Copy-CanonicalBundleForTest {
    param([Parameter(Mandatory)][string]$DestinationDirectory)

    New-Item -ItemType Directory -Path $DestinationDirectory | Out-Null
    foreach ($fileName in @('derived_snapshot_features.csv','manifest.json','schema.json','summary.json')) {
        Copy-Item -LiteralPath (Join-Path $canonicalBundleDirectory $fileName) -Destination (Join-Path $DestinationDirectory $fileName)
    }
}

function New-TestPointer {
    param(
        [Parameter(Mandatory)][string]$PointerPath,
        [Parameter(Mandatory)][string]$BundleDirectory,
        [scriptblock]$Mutator
    )

    $pointerObject = Get-Content -LiteralPath $canonicalPointerPath -Raw | ConvertFrom-Json -Depth 100
    $pointerObject.active_bundle_directory = $BundleDirectory
    if ($null -ne $Mutator) {
        & $Mutator $pointerObject
    }
    Write-Utf8NoBom -Path $PointerPath -Content (($pointerObject | ConvertTo-Json -Depth 100) + "`n")
}

function Invoke-EngineProcess {
    param(
        [Parameter(Mandatory)][string]$PointerPath,
        [Parameter(Mandatory)][string]$OutputDirectory
    )

    $stdoutPath = Join-Path $tempRootPath ('stdout-' + [System.IO.Path]::GetFileName($OutputDirectory) + '.json')
    $stderrPath = Join-Path $tempRootPath ('stderr-' + [System.IO.Path]::GetFileName($OutputDirectory) + '.txt')
    $processOutput = & pwsh -NoProfile -File $scriptPath -CanonicalDerivedPointerPath $PointerPath -OutputDirectory $OutputDirectory -PositionSize 10 -HoldCycles 1 -MaxSpread 0.05 -SlippagePerShare 0.01 -FeePerFill 0.02 2> $stderrPath
    $exitCode = $LASTEXITCODE
    $processOutput | Set-Content -LiteralPath $stdoutPath -Encoding utf8NoBOM
    return [pscustomobject]@{
        exit_code = $exitCode
        stdout_path = $stdoutPath
        stderr_path = $stderrPath
        stdout = [string](Get-Content -LiteralPath $stdoutPath -Raw)
        stderr = [string](Get-Content -LiteralPath $stderrPath -Raw)
    }
}

function Get-OutputHashes {
    param([Parameter(Mandatory)][string]$DirectoryPath)

    $hashes = [ordered]@{}
    foreach ($fileName in @('replay_cycles.csv','paper_trade_ledger.csv','simulation_summary.json')) {
        $hashes[$fileName] = Get-FileHashLower -Path (Join-Path $DirectoryPath $fileName)
    }
    return $hashes
}

function New-SyntheticRows {
    param([Parameter(Mandatory)][object[]]$SeedRows)

    return @(($SeedRows | ConvertTo-Json -Depth 20) | ConvertFrom-Json -Depth 20)
}

function Get-PropertyOrder {
    param([Parameter(Mandatory)][object]$ObjectValue)

    return @($ObjectValue.PSObject.Properties | ForEach-Object { $_.Name })
}

function Test-TempRootContained {
    param([Parameter(Mandatory)][string]$CandidatePath)

    $resolvedRepository = [System.IO.Path]::GetFullPath($repositoryRoot).TrimEnd('\')
    $resolvedCandidate = [System.IO.Path]::GetFullPath($CandidatePath).TrimEnd('\')
    if ($resolvedCandidate -ceq $resolvedRepository) { return $false }
    return $resolvedCandidate.StartsWith($resolvedRepository + '\', [System.StringComparison]::OrdinalIgnoreCase)
}

function Assert-AuthorizedTempRoot {
    param([Parameter(Mandatory)][string]$CandidatePath)

    $resolvedExpected = [System.IO.Path]::GetFullPath((Join-Path (Join-Path $repositoryRoot '.tmp') 'btc15m-replay-simulation-v1-tests')).TrimEnd('\')
    $resolvedCandidate = [System.IO.Path]::GetFullPath($CandidatePath).TrimEnd('\')
    if ($resolvedCandidate -cne $resolvedExpected) {
        throw ("UNAUTHORIZED_TEMP_ROOT:{0}" -f $resolvedCandidate)
    }
    if (-not (Test-TempRootContained -CandidatePath $CandidatePath)) {
        throw ("TEMP_ROOT_OUTSIDE_REPOSITORY:{0}" -f $resolvedCandidate)
    }
}

function Remove-AuthorizedTempRoot {
    Assert-AuthorizedTempRoot -CandidatePath $tempRootPath
    if (Test-Path -LiteralPath $tempRootPath) {
        Remove-Item -LiteralPath $tempRootPath -Recurse -Force
    }
    $tempParentPath = Join-Path $repositoryRoot '.tmp'
    $resolvedParent = [System.IO.Path]::GetFullPath($tempParentPath).TrimEnd('\')
    $expectedParent = [System.IO.Path]::GetFullPath((Join-Path $repositoryRoot '.tmp')).TrimEnd('\')
    if ($resolvedParent -ceq $expectedParent -and (Test-Path -LiteralPath $tempParentPath -PathType Container) -and @(Get-ChildItem -LiteralPath $tempParentPath -Force).Count -eq 0) {
        Remove-Item -LiteralPath $tempParentPath -Force
    }
}

function Assert-NoPositionOverlap {
    param(
        [Parameter(Mandatory)][object[]]$LedgerRows,
        [Parameter(Mandatory)][object[]]$ReplayCycleRows
    )

    $runEndByRun = @{}
    foreach ($cycleRow in $ReplayCycleRows) {
        $runKey = [string]$cycleRow.run_ordinal
        $orderValue = [int]$cycleRow.replay_order_index
        if (-not $runEndByRun.ContainsKey($runKey) -or $orderValue -gt [int]$runEndByRun[$runKey]) {
            $runEndByRun[$runKey] = $orderValue
        }
    }

    $intervals = [System.Collections.Generic.List[object]]::new()
    foreach ($ledgerRow in $LedgerRows) {
        $entryOrder = ConvertTo-Btc15mReplayInt $ledgerRow.entry_replay_order_index
        if ($null -eq $entryOrder) {
            throw ("LEDGER_ENTRY_REPLAY_ORDER_MISSING:{0}" -f $ledgerRow.trade_id)
        }
        $exitOrder = ConvertTo-Btc15mReplayInt $ledgerRow.exit_replay_order_index
        $runKey = [string]$ledgerRow.run_ordinal
        if ($null -eq $exitOrder) {
            if (-not $runEndByRun.ContainsKey($runKey)) {
                throw ("RUN_END_NOT_FOUND:{0}" -f $runKey)
            }
            $exitOrder = [int]$runEndByRun[$runKey]
        }
        if ($exitOrder -le $entryOrder -and [string]$ledgerRow.trade_status -ceq 'CLOSED') {
            throw ("SAME_OR_REVERSED_CLOSED_INTERVAL:{0}" -f $ledgerRow.trade_id)
        }
        $intervals.Add([pscustomobject]@{
            trade_id = [string]$ledgerRow.trade_id
            run_ordinal = $runKey
            token_id = [string]$ledgerRow.token_id
            status = [string]$ledgerRow.trade_status
            entry_order = [int]$entryOrder
            exit_order = [int]$exitOrder
        })
    }

    foreach ($groupItem in @($intervals | Group-Object run_ordinal, token_id)) {
        $groupIntervals = @($groupItem.Group | Sort-Object entry_order, trade_id)
        $unresolvedCount = @($groupIntervals | Where-Object { $_.status -ceq 'OPEN_MARK_TO_MARKET_ONLY' }).Count
        if ($unresolvedCount -gt 1) {
            throw ("MULTIPLE_UNRESOLVED_POSITIONS:{0}" -f $groupItem.Name)
        }
        for ($intervalIndex = 1; $intervalIndex -lt $groupIntervals.Count; $intervalIndex++) {
            $previousInterval = $groupIntervals[$intervalIndex - 1]
            $currentInterval = $groupIntervals[$intervalIndex]
            if ([int]$currentInterval.entry_order -lt [int]$previousInterval.exit_order) {
                throw ("OVERLAPPING_POSITION_INTERVAL:{0}:{1}" -f $previousInterval.trade_id, $currentInterval.trade_id)
            }
        }
    }
    return $true
}

function New-SyntheticReplayRows {
    param(
        [int[]]$Ordinals,
        [int[]]$RejectedOrdinals = @()
    )

    $rows = [System.Collections.Generic.List[object]]::new()
    $baseUp = $csvInfo.rows[0]
    $baseDown = $csvInfo.rows[1]
    foreach ($ordinalValue in $Ordinals) {
        foreach ($templateRow in @($baseUp, $baseDown)) {
            $newRow = $templateRow | ConvertTo-Json -Depth 20 | ConvertFrom-Json -Depth 20
            $newRow.run_ordinal = '1'
            $newRow.source_capture_run_id = 'SYNTHETIC_RUN'
            $newRow.synchronized_cycle_ordinal = [string]$ordinalValue
            $newRow.observation_timestamp_utc = ('2026-01-01T00:00:{0:00}.0000000Z' -f (($ordinalValue * 2) + $(if ($newRow.outcome -eq 'DOWN') { 1 } else { 0 })))
            $newRow.row_readiness = if ($ordinalValue -in $RejectedOrdinals) { 'FAIL' } else { 'PASS' }
            $rows.Add($newRow)
        }
    }
    return [object[]]$rows.ToArray()
}

Assert-AuthorizedTempRoot -CandidatePath $tempRootPath
Remove-AuthorizedTempRoot
$tempParent = Split-Path -Parent $tempRootPath
if (-not (Test-Path -LiteralPath $tempParent -PathType Container)) {
    New-Item -ItemType Directory -Path $tempParent | Out-Null
}
New-Item -ItemType Directory -Path $tempRootPath | Out-Null

$protectedBefore = $null
$protectedAfter = $null

try {
    $protectedBefore = Get-ProtectedHashes

    Assert-Equal -Name 'repository_root_exact' -Actual (Get-Location).Path -Expected $repositoryRoot
    Assert-True -Name 'authorized_temp_root_inside_repository' -Condition (Test-TempRootContained -CandidatePath $tempRootPath)
    Assert-True -Name 'historical_external_temp_path_rejected' -Condition (-not (Test-TempRootContained -CandidatePath $historicalDefectiveTempPath))
    Assert-True -Name 'sibling_temp_path_rejected' -Condition (-not (Test-TempRootContained -CandidatePath ($repositoryRoot + '-sibling\btc15m-replay-simulation-v1-tests')))
    Assert-True -Name 'repository_root_cleanup_target_rejected' -Condition (-not (Test-TempRootContained -CandidatePath $repositoryRoot))
    Assert-Equal -Name 'git_branch_main' -Actual (git branch --show-current) -Expected 'main'
    Assert-Equal -Name 'git_head_expected' -Actual (git rev-parse HEAD) -Expected $expectedHead
    Assert-Equal -Name 'git_origin_main_expected' -Actual (git rev-parse origin/main) -Expected $expectedHead
    Assert-Equal -Name 'git_head_equals_origin_main' -Actual (git rev-parse HEAD) -Expected (git rev-parse origin/main)
    Assert-Equal -Name 'no_staged_files' -Actual ((git diff --cached --name-only | Out-String).Trim()) -Expected ''

    $statusLines = @(git status --short --untracked-files=all)
    $expectedStatus = @(
        '?? scripts/btc-15m-arena/offline-derived-replay-simulation.ps1',
        '?? scripts/btc-15m-arena/offline-derived-replay-simulation.tests.ps1'
    )
    Assert-Equal -Name 'final_git_state_only_two_authorized_untracked' -Actual (($statusLines | Sort-Object) -join '|') -Expected (($expectedStatus | Sort-Object) -join '|')

    Assert-Equal -Name 'engine_ast_parse' -Actual (@(Test-PowerShellParse -Path $scriptPath).Count) -Expected 0
    Assert-Equal -Name 'tests_ast_parse' -Actual (@(Test-PowerShellParse -Path $testScriptPath).Count) -Expected 0

    . $scriptPath -LoadOnly

    $engineSource = Get-Content -LiteralPath $scriptPath -Raw
    $testSource = Get-Content -LiteralPath $testScriptPath -Raw
    $networkPatterns = @('Invoke' + '-WebRequest', 'Invoke' + '-RestMethod', 'Http' + 'Client', 'Web' + 'Client', 'cu' + 'rl', 'wg' + 'et')
    $tradingPatterns = @('private' + '_key', 'wall' + 'et', 'place' + '_order', 'create' + '_order', 'order' + '_sign', 'order' + '_cancel')
    $blockedReportPattern = '30' + '_REPORTS'
    $stalePointerPattern = 'active' + '_' + 'dataset' + '_' + 'zip'
    Assert-True -Name 'no_network_call_primitives' -Condition (-not (($engineSource + $testSource) -match ([string]::Join('|', @($networkPatterns | ForEach-Object { [regex]::Escape($_) })))))
    Assert-True -Name 'no_real_execution_primitives' -Condition (-not (($engineSource + $testSource) -match ([string]::Join('|', @($tradingPatterns | ForEach-Object { [regex]::Escape($_) })))))
    Assert-True -Name 'no_report_tree_data_source_literal' -Condition (-not ($engineSource -match [regex]::Escape($blockedReportPattern)))
    Assert-True -Name 'no_stale_raw_pointer_field_literal' -Condition (-not ($engineSource -match [regex]::Escape($stalePointerPattern)))

    $bundle = Resolve-Btc15mCanonicalDerivedBundle -PointerPath $canonicalPointerPath
    Assert-Equal -Name 'pointer_resolution_active_bundle' -Actual $bundle.active_bundle_id -Expected 'BTC15M_DERIVED_FEATURES_FROM_V4_V2'
    Assert-Equal -Name 'pointer_resolution_source_dataset' -Actual $bundle.source_dataset_id -Expected 'BTC15M_MULTI_RUN_20260626T231745Z_V4'
    Assert-Equal -Name 'exact_four_member_file_set' -Actual (($bundle.member_hashes.Keys | Sort-Object) -join '|') -Expected 'derived_snapshot_features.csv|manifest.json|schema.json|summary.json'

    $csvInfo = Read-Btc15mReplayCsvRows -CsvPath $bundle.csv_path
    Assert-Equal -Name 'canonical_csv_row_count_594' -Actual $csvInfo.row_count -Expected 594
    Assert-Equal -Name 'canonical_csv_column_count_30' -Actual $csvInfo.column_count -Expected 30
    Assert-Equal -Name 'complete_required_header' -Actual (($csvInfo.columns) -join '|') -Expected (($script:Btc15mReplayCsvColumns) -join '|')

    $replayModel = New-Btc15mReplayModel -RawRows $csvInfo.rows
    Assert-Equal -Name 'measured_cycle_count_not_assumed' -Actual $replayModel.measured_cycles -Expected (@($csvInfo.rows | Group-Object source_capture_run_id, run_ordinal, synchronized_cycle_ordinal).Count)
    Assert-Equal -Name 'valid_up_down_pairing' -Actual $replayModel.accepted_cycles -Expected 297
    Assert-Equal -Name 'no_row_reuse' -Actual $replayModel.rejected_cycles -Expected 0
    Assert-Equal -Name 'runs_count_9' -Actual $replayModel.runs -Expected 9

    $reversedRows = @($csvInfo.rows)
    [array]::Reverse($reversedRows)
    $reverseReplay = New-Btc15mReplayModel -RawRows $reversedRows
    $leftCycles = (ConvertTo-Btc15mReplayCsvContent -Rows (ConvertTo-Btc15mReplayCycleRows -ReplayModel $replayModel) -Columns @('source_dataset_id','source_capture_run_id','run_ordinal','synchronized_cycle_ordinal','up_timestamp','down_timestamp','cycle_status','rejection_reason','pair_mid_sum','pair_mid_gap_from_one','up_time_remaining_seconds','down_time_remaining_seconds','up_row_readiness','down_row_readiness','replay_order_index'))
    $rightCycles = (ConvertTo-Btc15mReplayCsvContent -Rows (ConvertTo-Btc15mReplayCycleRows -ReplayModel $reverseReplay) -Columns @('source_dataset_id','source_capture_run_id','run_ordinal','synchronized_cycle_ordinal','up_timestamp','down_timestamp','cycle_status','rejection_reason','pair_mid_sum','pair_mid_gap_from_one','up_time_remaining_seconds','down_time_remaining_seconds','up_row_readiness','down_row_readiness','replay_order_index'))
    Assert-Equal -Name 'reverse_input_replay_content_equal' -Actual $rightCycles -Expected $leftCycles

    $seedRows = @($csvInfo.rows | Select-Object -First 4)
    $incompleteRows = New-SyntheticRows -SeedRows $seedRows
    $incompleteRows = @($incompleteRows | Where-Object { -not ($_.synchronized_cycle_ordinal -eq '1' -and $_.outcome -eq 'DOWN') })
    Assert-True -Name 'detect_incomplete_cycle' -Condition ((New-Btc15mReplayModel -RawRows $incompleteRows).cycle_rejection_counts.Contains('MISSING_DOWN'))

    $duplicateUpRows = New-SyntheticRows -SeedRows $seedRows
    $duplicateUpRows += ($duplicateUpRows[0] | ConvertTo-Json -Depth 20 | ConvertFrom-Json -Depth 20)
    Assert-True -Name 'detect_duplicate_up' -Condition ((New-Btc15mReplayModel -RawRows $duplicateUpRows).cycle_rejection_counts.Contains('DUPLICATE_UP'))

    $duplicateDownRows = New-SyntheticRows -SeedRows $seedRows
    $duplicateDownRows += ($duplicateDownRows[1] | ConvertTo-Json -Depth 20 | ConvertFrom-Json -Depth 20)
    Assert-True -Name 'detect_duplicate_down' -Condition ((New-Btc15mReplayModel -RawRows $duplicateDownRows).cycle_rejection_counts.Contains('DUPLICATE_DOWN'))

    $invalidNumericRows = New-SyntheticRows -SeedRows $seedRows
    $invalidNumericRows[0].best_bid = 'not-a-number'
    Assert-True -Name 'reject_invalid_numeric' -Condition ((New-Btc15mReplayModel -RawRows $invalidNumericRows).row_rejection_counts.Contains('INVALID_BEST_BID'))

    $invalidTimestampRows = New-SyntheticRows -SeedRows $seedRows
    $invalidTimestampRows[0].observation_timestamp_utc = 'not-a-time'
    Assert-True -Name 'reject_invalid_timestamp' -Condition ((New-Btc15mReplayModel -RawRows $invalidTimestampRows).row_rejection_counts.Contains('INVALID_TIMESTAMP'))

    $readinessRows = New-SyntheticRows -SeedRows $seedRows
    $readinessRows[0].row_readiness = 'FAIL'
    Assert-True -Name 'row_readiness_enforced' -Condition ((New-Btc15mReplayModel -RawRows $readinessRows).row_rejection_counts.Contains('ROW_READINESS_NOT_PASS'))

    $configuration = New-Btc15mReplayConfiguration -PositionSize 10 -HoldCycles 1 -MaxSpread 0.05 -MinTimeRemainingSeconds 0 -MaxTimeRemainingSeconds 900 -SlippagePerShare 0.01 -FeePerFill 0.02 -RsiFilterMode Disabled
    $simulation = New-Btc15mPaperSimulation -ReplayModel $replayModel -Configuration $configuration
    $firstClosedTrade = @($simulation.ledger | Where-Object trade_status -eq 'CLOSED' | Sort-Object trade_id)[0]
    $expectedEntryFill = Format-Btc15mReplayDecimal (([decimal](ConvertTo-Btc15mReplayDecimal $firstClosedTrade.entry_best_ask)) + [decimal]0.01)
    $expectedExitFill = Format-Btc15mReplayDecimal (([decimal](ConvertTo-Btc15mReplayDecimal $firstClosedTrade.exit_best_bid)) - [decimal]0.01)
    $expectedGross = Format-Btc15mReplayDecimal ((([decimal](ConvertTo-Btc15mReplayDecimal $firstClosedTrade.exit_fill_price)) - ([decimal](ConvertTo-Btc15mReplayDecimal $firstClosedTrade.entry_fill_price))) * [decimal]10)
    $expectedNet = Format-Btc15mReplayDecimal (([decimal](ConvertTo-Btc15mReplayDecimal $expectedGross)) - [decimal]0.04)
    Assert-Equal -Name 'entry_fill_based_on_best_ask' -Actual $firstClosedTrade.entry_fill_price -Expected $expectedEntryFill
    Assert-Equal -Name 'exit_fill_based_on_best_bid' -Actual $firstClosedTrade.exit_fill_price -Expected $expectedExitFill
    Assert-True -Name 'mid_never_used_as_fill' -Condition ($firstClosedTrade.entry_fill_price -cne $csvInfo.rows[0].mid -and $firstClosedTrade.exit_fill_price -cne $csvInfo.rows[2].mid)
    Assert-Equal -Name 'explicit_slippage_behavior' -Actual $firstClosedTrade.slippage_per_share -Expected '0.01'
    Assert-Equal -Name 'explicit_fee_behavior' -Actual ($firstClosedTrade.entry_fee + '|' + $firstClosedTrade.exit_fee) -Expected '0.02|0.02'
    Assert-Equal -Name 'gross_pnl_formula' -Actual $firstClosedTrade.gross_pnl -Expected $expectedGross
    Assert-Equal -Name 'net_realized_pnl_formula' -Actual $firstClosedTrade.net_realized_pnl -Expected $expectedNet
    Assert-True -Name 'unclosed_position_mark_to_market_only' -Condition ($simulation.open_mark_to_market_trades -gt 0 -and @($simulation.ledger | Where-Object trade_status -eq 'OPEN_MARK_TO_MARKET_ONLY' | Where-Object { $_.net_realized_pnl -ne '' -or $_.exit_fill_price -ne '' }).Count -eq 0)
    Assert-True -Name 'final_settlement_not_evaluated' -Condition (@($simulation.ledger | Where-Object { $_.final_settlement_pnl_status -ne 'NOT_EVALUATED' }).Count -eq 0)

    $spreadReject = Test-Btc15mEntryEligibility -Row $replayModel.cycles[0].up_row -Configuration (New-Btc15mReplayConfiguration -PositionSize 1 -HoldCycles 1 -MaxSpread 0 -MinTimeRemainingSeconds 0 -MaxTimeRemainingSeconds 900 -SlippagePerShare 0 -FeePerFill 0 -RsiFilterMode Disabled)
    Assert-True -Name 'spread_filter_enforced' -Condition ($spreadReject.reason.Contains('SPREAD_FILTER_REJECTED'))
    $timeReject = Test-Btc15mEntryEligibility -Row $replayModel.cycles[0].up_row -Configuration (New-Btc15mReplayConfiguration -PositionSize 1 -HoldCycles 1 -MaxSpread 1 -MinTimeRemainingSeconds 800 -MaxTimeRemainingSeconds 900 -SlippagePerShare 0 -FeePerFill 0 -RsiFilterMode Disabled)
    Assert-True -Name 'time_remaining_filter_enforced' -Condition ($timeReject.reason.Contains('TIME_REMAINING_FILTER_REJECTED'))
    $rsiDisabled = Test-Btc15mEntryEligibility -Row $replayModel.cycles[0].up_row -Configuration (New-Btc15mReplayConfiguration -PositionSize 1 -HoldCycles 1 -MaxSpread 1 -MinTimeRemainingSeconds 0 -MaxTimeRemainingSeconds 900 -SlippagePerShare 0 -FeePerFill 0 -RsiFilterMode Disabled)
    Assert-True -Name 'rsi_filter_disabled_by_default' -Condition $rsiDisabled.eligible

    $futureMutationRowsA = New-SyntheticRows -SeedRows (@($csvInfo.rows | Select-Object -First 6))
    $futureMutationRowsB = New-SyntheticRows -SeedRows (@($csvInfo.rows | Select-Object -First 6))
    $futureMutationRowsB[4].best_ask = '0.99'
    $futureMutationRowsB[4].token_mid_rsi_14 = '99'
    $futureReplayA = New-Btc15mReplayModel -RawRows $futureMutationRowsA
    $futureReplayB = New-Btc15mReplayModel -RawRows $futureMutationRowsB
    $futureSimA = New-Btc15mPaperSimulation -ReplayModel $futureReplayA -Configuration $configuration
    $futureSimB = New-Btc15mPaperSimulation -ReplayModel $futureReplayB -Configuration $configuration
    $futureFirstA = @($futureSimA.ledger | Sort-Object trade_id)[0]
    $futureFirstB = @($futureSimB.ledger | Sort-Object trade_id)[0]
    Assert-Equal -Name 'no_lookahead_entry_invariance_future_mutation' -Actual ($futureFirstB.entry_cycle + '|' + $futureFirstB.entry_fill_price + '|' + $futureFirstB.decision_cutoff_timestamp) -Expected ($futureFirstA.entry_cycle + '|' + $futureFirstA.entry_fill_price + '|' + $futureFirstA.decision_cutoff_timestamp)
    Assert-True -Name 'exit_reaches_exit_row_after_entry' -Condition ([datetime]$firstClosedTrade.exit_timestamp -gt [datetime]$firstClosedTrade.entry_timestamp)
    Assert-Equal -Name 'decision_cutoff_matches_entry_timestamp' -Actual $firstClosedTrade.decision_cutoff_timestamp -Expected $firstClosedTrade.entry_timestamp
    Assert-Equal -Name 'no_lookahead_audit_status' -Actual $firstClosedTrade.no_lookahead_audit_status -Expected 'CURRENT_OR_PRIOR_ROWS_ONLY'

    $canonicalCycleRows = ConvertTo-Btc15mReplayCycleRows -ReplayModel $replayModel
    Assert-True -Name 'canonical_no_position_overlap' -Condition (Assert-NoPositionOverlap -LedgerRows $simulation.ledger -ReplayCycleRows $canonicalCycleRows)
    $validSyntheticLedger = @(
        [pscustomobject]@{ trade_id='A'; run_ordinal='1'; token_id='T'; trade_status='CLOSED'; entry_replay_order_index='1'; exit_replay_order_index='2' },
        [pscustomobject]@{ trade_id='B'; run_ordinal='1'; token_id='T'; trade_status='CLOSED'; entry_replay_order_index='3'; exit_replay_order_index='4' }
    )
    $validSyntheticCycles = @(
        [pscustomobject]@{ run_ordinal='1'; replay_order_index='1' },
        [pscustomobject]@{ run_ordinal='1'; replay_order_index='2' },
        [pscustomobject]@{ run_ordinal='1'; replay_order_index='3' },
        [pscustomobject]@{ run_ordinal='1'; replay_order_index='4' }
    )
    Assert-True -Name 'synthetic_non_overlapping_intervals_pass' -Condition (Assert-NoPositionOverlap -LedgerRows $validSyntheticLedger -ReplayCycleRows $validSyntheticCycles)
    $overlapLedger = @(
        [pscustomobject]@{ trade_id='A'; run_ordinal='1'; token_id='T'; trade_status='CLOSED'; entry_replay_order_index='1'; exit_replay_order_index='3' },
        [pscustomobject]@{ trade_id='B'; run_ordinal='1'; token_id='T'; trade_status='CLOSED'; entry_replay_order_index='2'; exit_replay_order_index='4' }
    )
    Assert-ThrowsLike -Name 'synthetic_overlapping_intervals_fail' -ScriptBlock { Assert-NoPositionOverlap -LedgerRows $overlapLedger -ReplayCycleRows $validSyntheticCycles } -ExpectedFragment 'OVERLAPPING_POSITION_INTERVAL'
    $twoOpenLedger = @(
        [pscustomobject]@{ trade_id='A'; run_ordinal='1'; token_id='T'; trade_status='OPEN_MARK_TO_MARKET_ONLY'; entry_replay_order_index='1'; exit_replay_order_index='' },
        [pscustomobject]@{ trade_id='B'; run_ordinal='1'; token_id='T'; trade_status='OPEN_MARK_TO_MARKET_ONLY'; entry_replay_order_index='3'; exit_replay_order_index='' }
    )
    Assert-ThrowsLike -Name 'synthetic_two_unresolved_positions_fail' -ScriptBlock { Assert-NoPositionOverlap -LedgerRows $twoOpenLedger -ReplayCycleRows $validSyntheticCycles } -ExpectedFragment 'MULTIPLE_UNRESOLVED_POSITIONS'

    $holdOneReplay = New-Btc15mReplayModel -RawRows (New-SyntheticReplayRows -Ordinals @(1,2))
    $holdOneSim = New-Btc15mPaperSimulation -ReplayModel $holdOneReplay -Configuration (New-Btc15mReplayConfiguration -PositionSize 1 -HoldCycles 1 -MaxSpread 1 -MinTimeRemainingSeconds 0 -MaxTimeRemainingSeconds 900 -SlippagePerShare 0 -FeePerFill 0 -RsiFilterMode Disabled)
    $holdOneClosed = @($holdOneSim.ledger | Where-Object { $_.trade_status -eq 'CLOSED' } | Sort-Object trade_id)[0]
    Assert-Equal -Name 'holdcycles_one_first_subsequent_accepted_cycle' -Actual ($holdOneClosed.entry_cycle + '|' + $holdOneClosed.exit_cycle + '|' + $holdOneClosed.accepted_hold_progress_at_exit) -Expected '1|2|1'
    Assert-True -Name 'holdcycles_no_same_cycle_exit' -Condition ($holdOneClosed.entry_cycle -ne $holdOneClosed.exit_cycle)

    $holdTwoReplay = New-Btc15mReplayModel -RawRows (New-SyntheticReplayRows -Ordinals @(1,2,3))
    $holdTwoSim = New-Btc15mPaperSimulation -ReplayModel $holdTwoReplay -Configuration (New-Btc15mReplayConfiguration -PositionSize 1 -HoldCycles 2 -MaxSpread 1 -MinTimeRemainingSeconds 0 -MaxTimeRemainingSeconds 900 -SlippagePerShare 0 -FeePerFill 0 -RsiFilterMode Disabled)
    $holdTwoClosed = @($holdTwoSim.ledger | Where-Object { $_.trade_status -eq 'CLOSED' } | Sort-Object trade_id)[0]
    Assert-Equal -Name 'holdcycles_two_contiguous_processed_cycles' -Actual ($holdTwoClosed.entry_cycle + '|' + $holdTwoClosed.exit_cycle + '|' + $holdTwoClosed.accepted_hold_progress_at_exit) -Expected '1|3|2'

    $gapReplay = New-Btc15mReplayModel -RawRows (New-SyntheticReplayRows -Ordinals @(1,3))
    $gapSim = New-Btc15mPaperSimulation -ReplayModel $gapReplay -Configuration (New-Btc15mReplayConfiguration -PositionSize 1 -HoldCycles 2 -MaxSpread 1 -MinTimeRemainingSeconds 0 -MaxTimeRemainingSeconds 900 -SlippagePerShare 0 -FeePerFill 0 -RsiFilterMode Disabled)
    Assert-Equal -Name 'noncontiguous_ordinals_do_not_create_synthetic_progress' -Actual (@($gapSim.ledger | Where-Object { $_.trade_status -eq 'CLOSED' }).Count) -Expected 0

    $rejectedMiddleReplay = New-Btc15mReplayModel -RawRows (New-SyntheticReplayRows -Ordinals @(1,2,3,4) -RejectedOrdinals @(2))
    $rejectedMiddleSim = New-Btc15mPaperSimulation -ReplayModel $rejectedMiddleReplay -Configuration (New-Btc15mReplayConfiguration -PositionSize 1 -HoldCycles 2 -MaxSpread 1 -MinTimeRemainingSeconds 0 -MaxTimeRemainingSeconds 900 -SlippagePerShare 0 -FeePerFill 0 -RsiFilterMode Disabled)
    $rejectedMiddleClosed = @($rejectedMiddleSim.ledger | Where-Object { $_.trade_status -eq 'CLOSED' } | Sort-Object trade_id)[0]
    Assert-Equal -Name 'rejected_cycle_does_not_increment_hold_progress' -Actual ($rejectedMiddleClosed.entry_cycle + '|' + $rejectedMiddleClosed.exit_cycle + '|' + $rejectedMiddleClosed.accepted_hold_progress_at_exit) -Expected '1|4|2'

    $testBundleDirectory = Join-Path $tempRootPath 'bundle-copy'
    Copy-CanonicalBundleForTest -DestinationDirectory $testBundleDirectory
    $testPointerPath = Join-Path $tempRootPath 'canonical-test-pointer.json'
    New-TestPointer -PointerPath $testPointerPath -BundleDirectory $testBundleDirectory -Mutator $null
    Assert-Equal -Name 'temp_pointer_resolves' -Actual (Resolve-Btc15mCanonicalDerivedBundle -PointerPath $testPointerPath).active_bundle_id -Expected 'BTC15M_DERIVED_FEATURES_FROM_V4_V2'

    $badSchemaPointer = Join-Path $tempRootPath 'bad-schema-pointer.json'
    New-TestPointer -PointerPath $badSchemaPointer -BundleDirectory $testBundleDirectory -Mutator { param($pointerValue) $pointerValue.schema_version = 'BAD_SCHEMA' }
    Assert-ThrowsLike -Name 'reject_invalid_pointer_schema' -ScriptBlock { Resolve-Btc15mCanonicalDerivedBundle -PointerPath $badSchemaPointer } -ExpectedFragment 'INVALID_POINTER_SCHEMA_VERSION'

    $badBundlePointer = Join-Path $tempRootPath 'bad-bundle-pointer.json'
    New-TestPointer -PointerPath $badBundlePointer -BundleDirectory $testBundleDirectory -Mutator { param($pointerValue) $pointerValue.active_bundle_id = 'BAD_BUNDLE' }
    Assert-ThrowsLike -Name 'reject_invalid_bundle_id' -ScriptBlock { Resolve-Btc15mCanonicalDerivedBundle -PointerPath $badBundlePointer } -ExpectedFragment 'INVALID_ACTIVE_BUNDLE_ID'

    $badSourcePointer = Join-Path $tempRootPath 'bad-source-pointer.json'
    New-TestPointer -PointerPath $badSourcePointer -BundleDirectory $testBundleDirectory -Mutator { param($pointerValue) $pointerValue.source_dataset_sha256 = '0' * 64 }
    Assert-ThrowsLike -Name 'reject_wrong_source_sha256' -ScriptBlock { Resolve-Btc15mCanonicalDerivedBundle -PointerPath $badSourcePointer } -ExpectedFragment 'INVALID_SOURCE_DATASET_SHA256'

    $missingBundleDirectory = Join-Path $tempRootPath 'bundle-missing-member'
    Copy-CanonicalBundleForTest -DestinationDirectory $missingBundleDirectory
    Remove-Item -LiteralPath (Join-Path $missingBundleDirectory 'summary.json') -Force
    $missingPointer = Join-Path $tempRootPath 'missing-member-pointer.json'
    New-TestPointer -PointerPath $missingPointer -BundleDirectory $missingBundleDirectory -Mutator $null
    Assert-ThrowsLike -Name 'reject_missing_member' -ScriptBlock { Resolve-Btc15mCanonicalDerivedBundle -PointerPath $missingPointer } -ExpectedFragment 'INVALID_PHYSICAL_BUNDLE_FILE_COUNT:3'

    $extraFileBundleDirectory = Join-Path $tempRootPath 'bundle-extra-file'
    Copy-CanonicalBundleForTest -DestinationDirectory $extraFileBundleDirectory
    Write-Utf8NoBom -Path (Join-Path $extraFileBundleDirectory 'unexpected.txt') -Content "x`n"
    $extraFilePointer = Join-Path $tempRootPath 'extra-file-pointer.json'
    New-TestPointer -PointerPath $extraFilePointer -BundleDirectory $extraFileBundleDirectory -Mutator $null
    Assert-ThrowsLike -Name 'reject_unexpected_fifth_bundle_file' -ScriptBlock { Resolve-Btc15mCanonicalDerivedBundle -PointerPath $extraFilePointer } -ExpectedFragment 'INVALID_PHYSICAL_BUNDLE_FILE_COUNT:5'

    $childDirectoryBundleDirectory = Join-Path $tempRootPath 'bundle-child-directory'
    Copy-CanonicalBundleForTest -DestinationDirectory $childDirectoryBundleDirectory
    New-Item -ItemType Directory -Path (Join-Path $childDirectoryBundleDirectory 'unexpected-dir') | Out-Null
    $childDirectoryPointer = Join-Path $tempRootPath 'child-directory-pointer.json'
    New-TestPointer -PointerPath $childDirectoryPointer -BundleDirectory $childDirectoryBundleDirectory -Mutator $null
    Assert-ThrowsLike -Name 'reject_unexpected_bundle_child_directory' -ScriptBlock { Resolve-Btc15mCanonicalDerivedBundle -PointerPath $childDirectoryPointer } -ExpectedFragment 'UNEXPECTED_BUNDLE_CHILD_DIRECTORY:unexpected-dir'

    $extraDeclaredPointer = Join-Path $tempRootPath 'extra-declared-pointer.json'
    New-TestPointer -PointerPath $extraDeclaredPointer -BundleDirectory $testBundleDirectory -Mutator {
        param($pointerValue)
        $members = @($pointerValue.members)
        $members += [pscustomobject]@{ name = 'unexpected.txt'; sha256 = '2' * 64; size_bytes = 1 }
        $pointerValue.members = $members
        $pointerValue.member_count = 5
    }
    Assert-ThrowsLike -Name 'reject_pointer_declared_extra_member' -ScriptBlock { Resolve-Btc15mCanonicalDerivedBundle -PointerPath $extraDeclaredPointer } -ExpectedFragment 'INVALID_MEMBER_COUNT'

    $missingDeclaredPointer = Join-Path $tempRootPath 'missing-declared-pointer.json'
    New-TestPointer -PointerPath $missingDeclaredPointer -BundleDirectory $testBundleDirectory -Mutator {
        param($pointerValue)
        $pointerValue.members = @($pointerValue.members | Where-Object { $_.name -ne 'summary.json' })
        $pointerValue.member_count = 3
    }
    Assert-ThrowsLike -Name 'reject_pointer_declared_missing_member' -ScriptBlock { Resolve-Btc15mCanonicalDerivedBundle -PointerPath $missingDeclaredPointer } -ExpectedFragment 'INVALID_MEMBER_COUNT'

    $wrongSetPointer = Join-Path $tempRootPath 'wrong-set-pointer.json'
    New-TestPointer -PointerPath $wrongSetPointer -BundleDirectory $testBundleDirectory -Mutator {
        param($pointerValue)
        foreach ($memberItem in $pointerValue.members) {
            if ($memberItem.name -eq 'summary.json') {
                $memberItem.name = 'unexpected.txt'
                $memberItem.sha256 = '3' * 64
            }
        }
        $pointerValue.member_count = 4
    }
    Assert-ThrowsLike -Name 'reject_pointer_declared_wrong_member_set' -ScriptBlock { Resolve-Btc15mCanonicalDerivedBundle -PointerPath $wrongSetPointer } -ExpectedFragment 'INVALID_POINTER_MEMBER_SET'

    $wrongHashBundleDirectory = Join-Path $tempRootPath 'bundle-wrong-hash'
    Copy-CanonicalBundleForTest -DestinationDirectory $wrongHashBundleDirectory
    Add-Content -LiteralPath (Join-Path $wrongHashBundleDirectory 'summary.json') -Value ' ' -Encoding utf8NoBOM
    $wrongHashPointer = Join-Path $tempRootPath 'wrong-hash-pointer.json'
    New-TestPointer -PointerPath $wrongHashPointer -BundleDirectory $wrongHashBundleDirectory -Mutator $null
    Assert-ThrowsLike -Name 'reject_wrong_member_hash' -ScriptBlock { Resolve-Btc15mCanonicalDerivedBundle -PointerPath $wrongHashPointer } -ExpectedFragment 'MEMBER_HASH_MISMATCH:summary.json'

    $wrongDeclaredPointer = Join-Path $tempRootPath 'wrong-declared-pointer.json'
    New-TestPointer -PointerPath $wrongDeclaredPointer -BundleDirectory $testBundleDirectory -Mutator { param($pointerValue) $pointerValue.members[0].sha256 = '1' * 64 }
    Assert-ThrowsLike -Name 'reject_declared_wrong_member_hash' -ScriptBlock { Resolve-Btc15mCanonicalDerivedBundle -PointerPath $wrongDeclaredPointer } -ExpectedFragment 'DECLARED_MEMBER_HASH_MISMATCH'

    $outOne = Join-Path $tempRootPath 'out-one'
    $outTwo = Join-Path $tempRootPath 'out-two'
    $resultOne = Invoke-EngineProcess -PointerPath $testPointerPath -OutputDirectory $outOne
    $resultTwo = Invoke-EngineProcess -PointerPath $testPointerPath -OutputDirectory $outTwo
    Assert-Equal -Name 'engine_process_exit_zero' -Actual $resultOne.exit_code -Expected 0
    Assert-Equal -Name 'second_engine_process_exit_zero' -Actual $resultTwo.exit_code -Expected 0
    Assert-Equal -Name 'engine_process_stderr_empty' -Actual ([string]$resultOne.stderr).Trim() -Expected ''
    $outputFiles = @(Get-ChildItem -LiteralPath $outOne -File | Sort-Object Name | ForEach-Object Name)
    Assert-Equal -Name 'normal_output_exact_three_files' -Actual ($outputFiles -join '|') -Expected 'paper_trade_ledger.csv|replay_cycles.csv|simulation_summary.json'

    $replayOutputRows = @((Get-Content -LiteralPath (Join-Path $outOne 'replay_cycles.csv') -Raw) | ConvertFrom-Csv)
    $ledgerOutputRows = @((Get-Content -LiteralPath (Join-Path $outOne 'paper_trade_ledger.csv') -Raw) | ConvertFrom-Csv)
    $summaryOutput = Get-Content -LiteralPath (Join-Path $outOne 'simulation_summary.json') -Raw | ConvertFrom-Json -Depth 100
    Assert-Equal -Name 'stable_replay_column_order' -Actual ((Get-Content -LiteralPath (Join-Path $outOne 'replay_cycles.csv') -First 1)) -Expected 'source_dataset_id,source_capture_run_id,run_ordinal,synchronized_cycle_ordinal,up_timestamp,down_timestamp,cycle_status,rejection_reason,pair_mid_sum,pair_mid_gap_from_one,up_time_remaining_seconds,down_time_remaining_seconds,up_row_readiness,down_row_readiness,replay_order_index'
    Assert-Equal -Name 'stable_ledger_column_order' -Actual ((Get-Content -LiteralPath (Join-Path $outOne 'paper_trade_ledger.csv') -First 1)) -Expected 'trade_id,source_dataset_id,run_ordinal,outcome,token_id,trade_status,entry_cycle,entry_replay_order_index,entry_timestamp,entry_best_ask,entry_fill_price,exit_cycle,exit_replay_order_index,exit_timestamp,exit_best_bid,exit_fill_price,position_size,configured_hold_cycles,accepted_hold_progress_at_exit,slippage_per_share,entry_fee,exit_fee,gross_pnl,net_realized_pnl,mark_to_market_pnl,entry_reason,exit_reason,decision_cutoff_timestamp,no_lookahead_audit_status,final_settlement_pnl_status'
    Assert-Equal -Name 'stable_json_property_order' -Actual ((Get-PropertyOrder -ObjectValue $summaryOutput) -join '|') -Expected 'schema_version|active_bundle_id|source_dataset_id|source_dataset_sha256|member_hashes|configuration|row_counts|measured_cycle_counts|run_counts|rejection_counts_by_reason|trade_counts|realized_pnl_aggregate|mark_to_market_aggregate|replay_cycles_csv_sha256|paper_trade_ledger_csv_sha256|no_lookahead_result|executable_price_semantics_result|final_settlement_status|replay_readiness|simulation_engineering_readiness|statistical_validation_readiness|statistical_readiness'
    Assert-Equal -Name 'summary_contract_readiness' -Actual ($summaryOutput.replay_readiness + '|' + $summaryOutput.simulation_engineering_readiness + '|' + $summaryOutput.statistical_validation_readiness + '|' + $summaryOutput.statistical_readiness) -Expected 'YES|YES|NO|PARTIAL'
    Assert-Equal -Name 'replay_cycles_output_rows' -Actual $replayOutputRows.Count -Expected 297
    Assert-True -Name 'trade_ledger_contract_nonempty' -Condition ($ledgerOutputRows.Count -gt 0 -and $ledgerOutputRows[0].final_settlement_pnl_status -eq 'NOT_EVALUATED')
    Assert-Equal -Name 'summary_output_hash_fields_match' -Actual ($summaryOutput.replay_cycles_csv_sha256 + '|' + $summaryOutput.paper_trade_ledger_csv_sha256) -Expected ((Get-FileHashLower -Path (Join-Path $outOne 'replay_cycles.csv')) + '|' + (Get-FileHashLower -Path (Join-Path $outOne 'paper_trade_ledger.csv')))

    $summaryPathOne = Join-Path $outOne 'simulation_summary.json'
    $summaryPathTwo = Join-Path $outTwo 'simulation_summary.json'
    $summaryProfileOne = Get-TextFileProfile -Path $summaryPathOne
    $summaryProfileTwo = Get-TextFileProfile -Path $summaryPathTwo
    Assert-True -Name 'summary_utf8_bom_absent' -Condition (-not $summaryProfileOne.has_utf8_bom)
    Assert-Equal -Name 'summary_crlf_count_zero' -Actual $summaryProfileOne.crlf_count -Expected 0
    Assert-Equal -Name 'summary_cr_only_count_zero' -Actual $summaryProfileOne.cr_only_count -Expected 0
    Assert-Equal -Name 'summary_lf_only_count_69' -Actual $summaryProfileOne.lf_only_count -Expected 69
    Assert-True -Name 'summary_eol_lf_only' -Condition ($summaryProfileOne.crlf_count -eq 0 -and $summaryProfileOne.cr_only_count -eq 0 -and $summaryProfileOne.lf_only_count -eq 69)
    Assert-True -Name 'summary_exactly_one_terminal_lf' -Condition $summaryProfileOne.exactly_one_terminal_lf
    Assert-True -Name 'summary_json_parseable' -Condition ($null -ne $summaryOutput)
    Assert-Equal -Name 'summary_size_2181' -Actual $summaryProfileOne.bytes -Expected 2181
    Assert-Equal -Name 'summary_sha256_measured_expected' -Actual $summaryProfileOne.sha256 -Expected $expectedRepairedSummarySha256
    Assert-Equal -Name 'summary_equals_normalized_pre_repair_reference_hash' -Actual $summaryProfileOne.sha256 -Expected $expectedRepairedSummarySha256
    Assert-True -Name 'summary_repaired_runs_byte_identical' -Condition ([Convert]::ToBase64String([System.IO.File]::ReadAllBytes($summaryPathOne)) -ceq [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($summaryPathTwo)))

    $hashesOne = Get-OutputHashes -DirectoryPath $outOne
    $hashesTwo = Get-OutputHashes -DirectoryPath $outTwo
    Assert-Equal -Name 'repeated_replay_byte_identical' -Actual $hashesTwo['replay_cycles.csv'] -Expected $hashesOne['replay_cycles.csv']
    Assert-Equal -Name 'repeated_ledger_byte_identical' -Actual $hashesTwo['paper_trade_ledger.csv'] -Expected $hashesOne['paper_trade_ledger.csv']
    Assert-Equal -Name 'repeated_summary_byte_identical' -Actual $hashesTwo['simulation_summary.json'] -Expected $hashesOne['simulation_summary.json']
    Assert-Equal -Name 'repeated_summary_profile_sha_expected' -Actual $summaryProfileTwo.sha256 -Expected $expectedRepairedSummarySha256

    $beforeNoWriteFiles = @(Get-ChildItem -LiteralPath $tempRootPath -Recurse -File | ForEach-Object FullName | Sort-Object)
    $noWriteResult = Invoke-Btc15mOfflineDerivedReplaySimulation -CanonicalDerivedPointerPath $testPointerPath -OutputDirectory '' -NoWrite $true -PositionSize 1 -HoldCycles 1 -MaxSpread 0.05 -MinTimeRemainingSeconds 0 -MaxTimeRemainingSeconds 900 -SlippagePerShare 0 -FeePerFill 0 -RsiFilterMode Disabled
    $afterNoWriteFiles = @(Get-ChildItem -LiteralPath $tempRootPath -Recurse -File | ForEach-Object FullName | Sort-Object)
    Assert-Equal -Name 'no_write_mode_pass' -Actual $noWriteResult.result -Expected 'PASS'
    Assert-Equal -Name 'no_write_mode_no_files' -Actual ($afterNoWriteFiles -join '|') -Expected ($beforeNoWriteFiles -join '|')

    Remove-AuthorizedTempRoot
    Assert-True -Name 'temporary_test_directory_removed' -Condition (-not (Test-Path -LiteralPath $tempRootPath))

    $protectedAfter = Get-ProtectedHashes
    foreach ($artifactName in $protectedArtifacts.Keys) {
        Assert-Equal -Name ('protected_hash_unchanged_' + $artifactName) -Actual $protectedAfter[$artifactName] -Expected $protectedBefore[$artifactName]
    }

    Assert-Equal -Name 'head_unchanged_no_commit' -Actual (git rev-parse HEAD) -Expected $expectedHead
    Assert-Equal -Name 'no_staged_files_after_tests' -Actual ((git diff --cached --name-only | Out-String).Trim()) -Expected ''
    Assert-Equal -Name 'git_status_scope_after_tests' -Actual ((git status --short --untracked-files=all | Sort-Object) -join '|') -Expected (($expectedStatus | Sort-Object) -join '|')

    [pscustomobject][ordered]@{
        schema_version = 'BTC15M_DERIVED_REPLAY_SIMULATION_TEST_RESULT_V1'
        result = 'PASS'
        test_count = $testRows.Count
        canonical_csv_rows = 594
        canonical_csv_columns = 30
        measured_cycles = $replayModel.measured_cycles
        accepted_cycles = $replayModel.accepted_cycles
        rejected_cycles = $replayModel.rejected_cycles
        trade_count = $simulation.total_trades
        closed_trades = $simulation.closed_trades
        open_mark_to_market_trades = $simulation.open_mark_to_market_trades
        output_hashes = $hashesOne
        protected_hashes_before = $protectedBefore
        protected_hashes_after = $protectedAfter
        tests = @($testRows)
    } | ConvertTo-Json -Depth 50
    exit 0
}
catch {
    if ($null -eq $protectedAfter) {
        try { $protectedAfter = Get-ProtectedHashes } catch { $protectedAfter = [ordered]@{} }
    }
    [pscustomobject][ordered]@{
        schema_version = 'BTC15M_DERIVED_REPLAY_SIMULATION_TEST_RESULT_V1'
        result = 'NO_PASS'
        error = $_.Exception.Message
        test_count = $testRows.Count
        protected_hashes_before = $protectedBefore
        protected_hashes_after = $protectedAfter
        tests = @($testRows)
    } | ConvertTo-Json -Depth 50
    exit 1
}
finally {
    Remove-AuthorizedTempRoot
}
