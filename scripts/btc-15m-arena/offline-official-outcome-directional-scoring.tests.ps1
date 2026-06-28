<#
.SYNOPSIS
Self-contained tests for offline-official-outcome-directional-scoring.ps1.
#>

#requires -Version 7.0

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot 'offline-official-outcome-directional-scoring.ps1'
$repositoryRoot = [System.IO.Path]::GetFullPath('C:\openutilitylab-site')
$tempRootPath = Join-Path ([System.IO.Path]::GetTempPath()) 'btc15m-official-outcome-directional-scoring-v1-tests'
$protectedArtifacts = [ordered]@{
    replay_engine = Join-Path $PSScriptRoot 'offline-derived-replay-simulation.ps1'
    replay_tests = Join-Path $PSScriptRoot 'offline-derived-replay-simulation.tests.ps1'
}
$expectedProtectedHashes = [ordered]@{
    replay_engine = '8de6297abda9ab14042f6a613bdbb5eec1575704e30a7e746f5b91cdfa310d02'
    replay_tests = 'bc509f3108ec591eccf4689a1b7d77b110e035020d826705970910be03610901'
}
$testRows = [System.Collections.Generic.List[object]]::new()
$caseOrdinal = 0

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
    if ($Pass) {
        Write-Output ('TEST::{0}=PASS' -f $Name)
    }
    else {
        Write-Output ('TEST::{0}=NO_PASS::{1}' -f $Name, $Detail)
    }
}

function Invoke-TestCase {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][scriptblock]$ScriptBlock
    )

    try {
        & $ScriptBlock
        Add-TestResult -Name $Name -Pass $true
    }
    catch {
        Add-TestResult -Name $Name -Pass $false -Detail $_.Exception.Message
    }
}

function Assert-Equal {
    param(
        [AllowNull()][object]$Actual,
        [AllowNull()][object]$Expected,
        [string]$Detail = 'values differ'
    )

    $actualText = if ($null -eq $Actual) { '<null>' } else { [string]$Actual }
    $expectedText = if ($null -eq $Expected) { '<null>' } else { [string]$Expected }
    if ($actualText -cne $expectedText) {
        throw ('{0};actual={1};expected={2}' -f $Detail, $actualText, $expectedText)
    }
}

function Assert-True {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [string]$Detail = 'condition false'
    )

    if (-not $Condition) { throw $Detail }
}

function Get-FileHashLower {
    param([Parameter(Mandatory)][string]$Path)

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-ProtectedHashes {
    $hashes = [ordered]@{}
    foreach ($artifactName in $protectedArtifacts.Keys) {
        $hashes[$artifactName] = Get-FileHashLower -Path $protectedArtifacts[$artifactName]
    }
    return $hashes
}

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Content
    )

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function New-CaseDirectory {
    param([Parameter(Mandatory)][string]$Name)

    $script:caseOrdinal++
    $safeName = ('{0:000}-{1}' -f $script:caseOrdinal, ($Name -replace '[^A-Za-z0-9_.-]', '_'))
    $path = Join-Path $tempRootPath $safeName
    New-Item -ItemType Directory -Path $path | Out-Null
    return $path
}

function New-ScoringRecord {
    param(
        [int]$Index = 1,
        [string]$Prediction = 'UP',
        [string]$OfficialOutcome = 'UP',
        [string]$PredictionTimestamp = '2026-06-28T00:05:00Z',
        [AllowNull()][string]$NoTradeReason = $null,
        [AllowNull()][object]$ResolutionTimestamp = '2026-06-28T00:16:00Z',
        [AllowNull()][object]$StartPrice = $null,
        [AllowNull()][object]$FinalPrice = $null,
        [AllowNull()][string]$Source = $null
    )

    return [pscustomobject][ordered]@{
        schema_version = 'BTC15M_OFFICIAL_OUTCOME_DIRECTIONAL_INPUT_V1'
        market_slug = ('btc-updown-15m-{0:000}' -f $Index)
        event_id = ('event-{0:000}' -f $Index)
        market_id = ('market-{0:000}' -f $Index)
        condition_id = ('condition-{0:000}' -f $Index)
        up_token_id = ('up-token-{0:000}' -f $Index)
        down_token_id = ('down-token-{0:000}' -f $Index)
        canonical_url = ('https://example.invalid/markets/{0:000}' -f $Index)
        window_start_utc = '2026-06-28T00:00:00Z'
        window_end_utc = '2026-06-28T00:15:00Z'
        prediction = $Prediction
        prediction_timestamp_utc = $PredictionTimestamp
        primary_no_trade_reason = $NoTradeReason
        official_outcome = $OfficialOutcome
        official_outcome_source = if ($OfficialOutcome -eq 'PENDING') { $null } else { 'synthetic_official_fixture' }
        official_resolution_timestamp_utc = $ResolutionTimestamp
        reconstructed_start_price = $StartPrice
        reconstructed_final_price = $FinalPrice
        reconstructed_source = $Source
    }
}

function Write-JsonlFixture {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][object[]]$Records
    )

    $lines = foreach ($record in $Records) {
        ($record | ConvertTo-Json -Depth 50 -Compress)
    }
    Write-Utf8NoBom -Path $Path -Content ((@($lines) -join "`n") + "`n")
}

function Invoke-ScorerProcess {
    param(
        [Parameter(Mandatory)][string]$InputPath,
        [Parameter(Mandatory)][string]$OutputDirectory,
        [switch]$Overwrite
    )

    $arguments = @('-NoProfile','-File', $scriptPath, '-InputPath', $InputPath, '-OutputDirectory', $OutputDirectory)
    if ($Overwrite) { $arguments += '-Overwrite' }
    $stdout = & pwsh @arguments 2>&1
    return [pscustomobject][ordered]@{
        exit_code = $LASTEXITCODE
        output = (@($stdout) -join "`n")
    }
}

function Invoke-ScorerWithRecords {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][object[]]$Records
    )

    $caseDir = New-CaseDirectory -Name $Name
    $inputPath = Join-Path $caseDir 'input.jsonl'
    $outputDirectory = Join-Path $caseDir 'output'
    Write-JsonlFixture -Path $inputPath -Records $Records
    $result = Invoke-ScorerProcess -InputPath $inputPath -OutputDirectory $outputDirectory
    Assert-Equal -Actual $result.exit_code -Expected 0 -Detail $result.output
    return [pscustomobject][ordered]@{
        case_dir = $caseDir
        input_path = $inputPath
        output_directory = $outputDirectory
        process = $result
    }
}

function Get-FirstScoredMarket {
    param([Parameter(Mandatory)][string]$OutputDirectory)

    return (Get-Content -LiteralPath (Join-Path $OutputDirectory 'scored_markets.jsonl') | Select-Object -First 1 | ConvertFrom-Json -Depth 50)
}

function Get-ScoringSummary {
    param([Parameter(Mandatory)][string]$OutputDirectory)

    return (Get-Content -LiteralPath (Join-Path $OutputDirectory 'directional_summary.json') -Raw | ConvertFrom-Json -Depth 50)
}

function Get-OutputProfile {
    param([Parameter(Mandatory)][string]$Path)

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $lineCount = 0
    foreach ($byteValue in $bytes) {
        if ($byteValue -eq 10) { $lineCount++ }
    }
    return [pscustomobject][ordered]@{
        bytes = $bytes.Length
        sha256 = Get-FileHashLower -Path $Path
        line_count = $lineCount
        has_bom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xef -and $bytes[1] -eq 0xbb -and $bytes[2] -eq 0xbf)
        has_cr = ($bytes -contains 13)
    }
}

function Assert-Null {
    param([AllowNull()][object]$Value, [string]$Detail = 'expected null')

    if ($null -ne $Value) { throw ('{0};actual={1}' -f $Detail, $Value) }
}

function Assert-Rejected {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][object[]]$Records,
        [Parameter(Mandatory)][string]$ExpectedFragment
    )

    $caseDir = New-CaseDirectory -Name $Name
    $inputPath = Join-Path $caseDir 'input.jsonl'
    $outputDirectory = Join-Path $caseDir 'output'
    Write-JsonlFixture -Path $inputPath -Records $Records
    $result = Invoke-ScorerProcess -InputPath $inputPath -OutputDirectory $outputDirectory
    Assert-True -Condition ($result.exit_code -ne 0) -Detail 'expected rejection'
    Assert-True -Condition ($result.output.Contains($ExpectedFragment)) -Detail ('missing expected fragment;output={0}' -f $result.output)
}

if ([System.IO.Directory]::Exists($tempRootPath)) {
    $resolvedTemp = [System.IO.Path]::GetFullPath($tempRootPath)
    Assert-True -Condition ($resolvedTemp.StartsWith([System.IO.Path]::GetTempPath(), [System.StringComparison]::OrdinalIgnoreCase)) -Detail 'unsafe temp cleanup path'
    Remove-Item -LiteralPath $resolvedTemp -Recurse -Force
}
New-Item -ItemType Directory -Path $tempRootPath | Out-Null
$protectedHashesBefore = Get-ProtectedHashes

try {
    Invoke-TestCase -Name 'correct_UP_prediction' -ScriptBlock {
        $run = Invoke-ScorerWithRecords -Name 'correct-up' -Records @((New-ScoringRecord -Index 1 -Prediction 'UP' -OfficialOutcome 'UP'))
        $scored = Get-FirstScoredMarket -OutputDirectory $run.output_directory
        Assert-Equal -Actual $scored.prediction_status -Expected 'VALID'
        Assert-Equal -Actual $scored.prediction_correct -Expected 'True'
    }

    Invoke-TestCase -Name 'correct_DOWN_prediction' -ScriptBlock {
        $run = Invoke-ScorerWithRecords -Name 'correct-down' -Records @((New-ScoringRecord -Index 2 -Prediction 'DOWN' -OfficialOutcome 'DOWN'))
        $scored = Get-FirstScoredMarket -OutputDirectory $run.output_directory
        Assert-Equal -Actual $scored.prediction_status -Expected 'VALID'
        Assert-Equal -Actual $scored.prediction_correct -Expected 'True'
    }

    Invoke-TestCase -Name 'incorrect_UP_prediction' -ScriptBlock {
        $run = Invoke-ScorerWithRecords -Name 'incorrect-up' -Records @((New-ScoringRecord -Index 3 -Prediction 'UP' -OfficialOutcome 'DOWN'))
        $scored = Get-FirstScoredMarket -OutputDirectory $run.output_directory
        Assert-Equal -Actual $scored.prediction_correct -Expected 'False'
    }

    Invoke-TestCase -Name 'incorrect_DOWN_prediction' -ScriptBlock {
        $run = Invoke-ScorerWithRecords -Name 'incorrect-down' -Records @((New-ScoringRecord -Index 4 -Prediction 'DOWN' -OfficialOutcome 'UP'))
        $scored = Get-FirstScoredMarket -OutputDirectory $run.output_directory
        Assert-Equal -Actual $scored.prediction_correct -Expected 'False'
    }

    Invoke-TestCase -Name 'NO_TRADE_abstention' -ScriptBlock {
        $run = Invoke-ScorerWithRecords -Name 'abstention' -Records @((New-ScoringRecord -Index 5 -Prediction 'NO_TRADE' -OfficialOutcome 'UP' -NoTradeReason 'spread_too_wide'))
        $scored = Get-FirstScoredMarket -OutputDirectory $run.output_directory
        Assert-Equal -Actual $scored.prediction_status -Expected 'ABSTAINED'
        Assert-Null -Value $scored.prediction_correct
    }

    Invoke-TestCase -Name 'PENDING_resolution' -ScriptBlock {
        $run = Invoke-ScorerWithRecords -Name 'pending' -Records @((New-ScoringRecord -Index 6 -Prediction 'UP' -OfficialOutcome 'PENDING' -ResolutionTimestamp $null))
        $scored = Get-FirstScoredMarket -OutputDirectory $run.output_directory
        Assert-Equal -Actual $scored.prediction_status -Expected 'PENDING_RESOLUTION'
        Assert-Null -Value $scored.prediction_correct
    }

    Invoke-TestCase -Name 'equality_reconstruction_resolves_UP' -ScriptBlock {
        $run = Invoke-ScorerWithRecords -Name 'equality-reconstructs-up' -Records @((New-ScoringRecord -Index 7 -Prediction 'UP' -OfficialOutcome 'UP' -StartPrice 100 -FinalPrice 100 -Source 'synthetic_chainlink'))
        $scored = Get-FirstScoredMarket -OutputDirectory $run.output_directory
        Assert-Equal -Actual $scored.reconstructed_chainlink_outcome -Expected 'UP'
        Assert-Equal -Actual $scored.reconstruction_status -Expected 'MATCH'
    }

    Invoke-TestCase -Name 'reconstruction_mismatch_preserves_official_outcome' -ScriptBlock {
        $run = Invoke-ScorerWithRecords -Name 'mismatch-preserves-official' -Records @((New-ScoringRecord -Index 8 -Prediction 'DOWN' -OfficialOutcome 'DOWN' -StartPrice 100 -FinalPrice 100 -Source 'synthetic_chainlink'))
        $scored = Get-FirstScoredMarket -OutputDirectory $run.output_directory
        Assert-Equal -Actual $scored.official_outcome -Expected 'DOWN'
        Assert-Equal -Actual $scored.reconstructed_chainlink_outcome -Expected 'UP'
        Assert-Equal -Actual $scored.reconstruction_status -Expected 'MISMATCH'
        Assert-Equal -Actual $scored.prediction_correct -Expected 'True'
    }

    Invoke-TestCase -Name 'invalid_official_outcome_rejected' -ScriptBlock {
        Assert-Rejected -Name 'invalid-official' -Records @((New-ScoringRecord -Index 9 -Prediction 'UP' -OfficialOutcome 'SIDEWAYS')) -ExpectedFragment 'INVALID_OFFICIAL_OUTCOME'
    }

    Invoke-TestCase -Name 'malformed_JSON_rejected' -ScriptBlock {
        $caseDir = New-CaseDirectory -Name 'malformed-json'
        $inputPath = Join-Path $caseDir 'input.jsonl'
        $outputDirectory = Join-Path $caseDir 'output'
        Write-Utf8NoBom -Path $inputPath -Content "{bad json`n"
        $result = Invoke-ScorerProcess -InputPath $inputPath -OutputDirectory $outputDirectory
        Assert-True -Condition ($result.exit_code -ne 0) -Detail 'expected malformed JSON rejection'
        Assert-True -Condition ($result.output.Contains('MALFORMED_JSON')) -Detail $result.output
    }

    Invoke-TestCase -Name 'duplicate_market_identity_rejected' -ScriptBlock {
        $first = New-ScoringRecord -Index 11 -Prediction 'UP' -OfficialOutcome 'UP'
        $second = New-ScoringRecord -Index 12 -Prediction 'DOWN' -OfficialOutcome 'DOWN'
        $second.market_slug = $first.market_slug
        $second.event_id = $first.event_id
        $second.market_id = $first.market_id
        $second.condition_id = $first.condition_id
        Assert-Rejected -Name 'duplicate-market' -Records @($first, $second) -ExpectedFragment 'DUPLICATE_MARKET_IDENTITY'
    }

    Invoke-TestCase -Name 'identical_token_IDs_rejected' -ScriptBlock {
        $record = New-ScoringRecord -Index 12 -Prediction 'UP' -OfficialOutcome 'UP'
        $record.down_token_id = $record.up_token_id
        Assert-Rejected -Name 'identical-tokens' -Records @($record) -ExpectedFragment 'IDENTICAL_TOKEN_IDS'
    }

    Invoke-TestCase -Name 'missing_no_trade_reason_rejected' -ScriptBlock {
        Assert-Rejected -Name 'missing-no-trade-reason' -Records @((New-ScoringRecord -Index 13 -Prediction 'NO_TRADE' -OfficialOutcome 'UP')) -ExpectedFragment 'MISSING_NO_TRADE_REASON'
    }

    Invoke-TestCase -Name 'invalid_reconstructed_start_price_rejected' -ScriptBlock {
        Assert-Rejected -Name 'invalid-reconstructed-start-price' -Records @((New-ScoringRecord -Index 37 -Prediction 'UP' -OfficialOutcome 'UP' -StartPrice 'not-a-number' -FinalPrice 100 -Source 'synthetic_chainlink')) -ExpectedFragment 'INVALID_RECONSTRUCTED_PRICE:line=1;field=reconstructed_start_price'
    }

    Invoke-TestCase -Name 'invalid_reconstructed_final_price_rejected' -ScriptBlock {
        Assert-Rejected -Name 'invalid-reconstructed-final-price' -Records @((New-ScoringRecord -Index 38 -Prediction 'UP' -OfficialOutcome 'UP' -StartPrice 100 -FinalPrice 'not-a-number' -Source 'synthetic_chainlink')) -ExpectedFragment 'INVALID_RECONSTRUCTED_PRICE:line=1;field=reconstructed_final_price'
    }

    Invoke-TestCase -Name 'prediction_enum_is_case_sensitive' -ScriptBlock {
        Assert-Rejected -Name 'prediction-enum-case-sensitive' -Records @((New-ScoringRecord -Index 39 -Prediction 'up' -OfficialOutcome 'UP')) -ExpectedFragment 'INVALID_PREDICTION'
    }

    Invoke-TestCase -Name 'official_outcome_enum_is_case_sensitive' -ScriptBlock {
        Assert-Rejected -Name 'official-outcome-enum-case-sensitive' -Records @((New-ScoringRecord -Index 40 -Prediction 'UP' -OfficialOutcome 'up')) -ExpectedFragment 'INVALID_OFFICIAL_OUTCOME'
    }

    Invoke-TestCase -Name 'late_prediction_classified_LATE_INVALID' -ScriptBlock {
        $run = Invoke-ScorerWithRecords -Name 'late-invalid' -Records @((New-ScoringRecord -Index 14 -Prediction 'UP' -OfficialOutcome 'UP' -PredictionTimestamp '2026-06-28T00:15:01Z'))
        $scored = Get-FirstScoredMarket -OutputDirectory $run.output_directory
        Assert-Equal -Actual $scored.prediction_status -Expected 'LATE_INVALID'
        Assert-Null -Value $scored.prediction_correct
    }

    Invoke-TestCase -Name 'coverage_excludes_pending_and_counts_abstention' -ScriptBlock {
        $records = @(
            (New-ScoringRecord -Index 15 -Prediction 'UP' -OfficialOutcome 'UP'),
            (New-ScoringRecord -Index 16 -Prediction 'NO_TRADE' -OfficialOutcome 'DOWN' -NoTradeReason 'manual_abstain'),
            (New-ScoringRecord -Index 17 -Prediction 'UP' -OfficialOutcome 'PENDING' -ResolutionTimestamp $null)
        )
        $run = Invoke-ScorerWithRecords -Name 'coverage' -Records $records
        $summary = Get-ScoringSummary -OutputDirectory $run.output_directory
        Assert-Equal -Actual $summary.eligible_resolved_market_count -Expected 2
        Assert-Equal -Actual $summary.pending_resolution_count -Expected 1
        Assert-Equal -Actual $summary.valid_prediction_count -Expected 1
        Assert-Equal -Actual $summary.coverage -Expected 0.5
    }

    Invoke-TestCase -Name 'confusion_matrix_exactness' -ScriptBlock {
        $records = @(
            (New-ScoringRecord -Index 18 -Prediction 'UP' -OfficialOutcome 'UP'),
            (New-ScoringRecord -Index 19 -Prediction 'DOWN' -OfficialOutcome 'UP'),
            (New-ScoringRecord -Index 20 -Prediction 'UP' -OfficialOutcome 'DOWN'),
            (New-ScoringRecord -Index 21 -Prediction 'DOWN' -OfficialOutcome 'DOWN')
        )
        $run = Invoke-ScorerWithRecords -Name 'confusion' -Records $records
        $summary = Get-ScoringSummary -OutputDirectory $run.output_directory
        Assert-Equal -Actual $summary.actual_UP_predicted_UP -Expected 1
        Assert-Equal -Actual $summary.actual_UP_predicted_DOWN -Expected 1
        Assert-Equal -Actual $summary.actual_DOWN_predicted_UP -Expected 1
        Assert-Equal -Actual $summary.actual_DOWN_predicted_DOWN -Expected 1
        $csv = Get-Content -LiteralPath (Join-Path $run.output_directory 'confusion_matrix.csv') -Raw
        Assert-Equal -Actual $csv -Expected "actual_outcome,predicted_UP,predicted_DOWN`nUP,1,1`nDOWN,1,1`n"
    }

    Invoke-TestCase -Name 'accuracy_exactness' -ScriptBlock {
        $records = @(
            (New-ScoringRecord -Index 22 -Prediction 'UP' -OfficialOutcome 'UP'),
            (New-ScoringRecord -Index 23 -Prediction 'DOWN' -OfficialOutcome 'DOWN'),
            (New-ScoringRecord -Index 24 -Prediction 'UP' -OfficialOutcome 'DOWN'),
            (New-ScoringRecord -Index 25 -Prediction 'DOWN' -OfficialOutcome 'UP')
        )
        $run = Invoke-ScorerWithRecords -Name 'accuracy' -Records $records
        $summary = Get-ScoringSummary -OutputDirectory $run.output_directory
        Assert-Equal -Actual $summary.directional_accuracy -Expected 0.5
        Assert-Equal -Actual $summary.correct_prediction_count -Expected 2
        Assert-Equal -Actual $summary.incorrect_prediction_count -Expected 2
    }

    Invoke-TestCase -Name 'balanced_accuracy_exactness' -ScriptBlock {
        $records = @(
            (New-ScoringRecord -Index 26 -Prediction 'UP' -OfficialOutcome 'UP'),
            (New-ScoringRecord -Index 27 -Prediction 'DOWN' -OfficialOutcome 'UP'),
            (New-ScoringRecord -Index 28 -Prediction 'UP' -OfficialOutcome 'DOWN'),
            (New-ScoringRecord -Index 29 -Prediction 'DOWN' -OfficialOutcome 'DOWN')
        )
        $run = Invoke-ScorerWithRecords -Name 'balanced-accuracy' -Records $records
        $summary = Get-ScoringSummary -OutputDirectory $run.output_directory
        Assert-Equal -Actual $summary.UP_recall -Expected 0.5
        Assert-Equal -Actual $summary.DOWN_recall -Expected 0.5
        Assert-Equal -Actual $summary.balanced_accuracy -Expected 0.5
    }

    Invoke-TestCase -Name 'zero_denominator_metrics_serialized_null' -ScriptBlock {
        $records = @(
            (New-ScoringRecord -Index 30 -Prediction 'NO_TRADE' -OfficialOutcome 'UP' -NoTradeReason 'abstain'),
            (New-ScoringRecord -Index 31 -Prediction 'UP' -OfficialOutcome 'PENDING' -ResolutionTimestamp $null)
        )
        $run = Invoke-ScorerWithRecords -Name 'zero-denominator' -Records $records
        $summary = Get-ScoringSummary -OutputDirectory $run.output_directory
        Assert-Null -Value $summary.directional_accuracy
        Assert-Null -Value $summary.UP_precision
        Assert-Null -Value $summary.DOWN_precision
        Assert-Null -Value $summary.balanced_accuracy
        Assert-Equal -Actual $summary.directional_accuracy_status -Expected 'ZERO_VALID_PREDICTIONS'
    }

    Invoke-TestCase -Name 'deterministic_repeated_outputs_byte_identical' -ScriptBlock {
        $records = @(
            (New-ScoringRecord -Index 32 -Prediction 'DOWN' -OfficialOutcome 'DOWN'),
            (New-ScoringRecord -Index 33 -Prediction 'UP' -OfficialOutcome 'UP' -StartPrice 1 -FinalPrice 1)
        )
        $first = Invoke-ScorerWithRecords -Name 'determinism-one' -Records $records
        $second = Invoke-ScorerWithRecords -Name 'determinism-two' -Records $records
        foreach ($fileName in @('scored_markets.jsonl','directional_summary.json','confusion_matrix.csv','manifest.csv')) {
            Assert-Equal -Actual (Get-FileHashLower -Path (Join-Path $first.output_directory $fileName)) -Expected (Get-FileHashLower -Path (Join-Path $second.output_directory $fileName)) -Detail $fileName
        }
    }

    Invoke-TestCase -Name 'UTF8_no_BOM_and_LF_only_outputs' -ScriptBlock {
        $run = Invoke-ScorerWithRecords -Name 'encoding' -Records @((New-ScoringRecord -Index 34 -Prediction 'UP' -OfficialOutcome 'UP'))
        foreach ($fileName in @('scored_markets.jsonl','directional_summary.json','confusion_matrix.csv','manifest.csv')) {
            $profile = Get-OutputProfile -Path (Join-Path $run.output_directory $fileName)
            Assert-True -Condition (-not $profile.has_bom) -Detail ('BOM in {0}' -f $fileName)
            Assert-True -Condition (-not $profile.has_cr) -Detail ('CR byte in {0}' -f $fileName)
        }
    }

    Invoke-TestCase -Name 'manifest_hashes_sizes_line_counts_match' -ScriptBlock {
        $run = Invoke-ScorerWithRecords -Name 'manifest' -Records @((New-ScoringRecord -Index 35 -Prediction 'UP' -OfficialOutcome 'UP'))
        $manifest = Import-Csv -LiteralPath (Join-Path $run.output_directory 'manifest.csv')
        Assert-Equal -Actual $manifest.Count -Expected 3
        foreach ($row in $manifest) {
            $filePath = Join-Path $run.output_directory $row.relative_path
            $profile = Get-OutputProfile -Path $filePath
            Assert-Equal -Actual $row.bytes -Expected $profile.bytes -Detail ('bytes {0}' -f $row.relative_path)
            Assert-Equal -Actual $row.sha256 -Expected $profile.sha256 -Detail ('sha {0}' -f $row.relative_path)
            Assert-Equal -Actual $row.line_count -Expected $profile.line_count -Detail ('lines {0}' -f $row.relative_path)
        }
    }

    Invoke-TestCase -Name 'target_script_contains_no_network_or_trading_primitives' -ScriptBlock {
        $content = Get-Content -LiteralPath $scriptPath -Raw
        $forbidden = @(
            ('Invoke-' + 'Web' + 'Request'),
            ('Invoke-' + 'Rest' + 'Method'),
            ('System.' + 'Net.' + 'Http'),
            ('Http' + 'Client'),
            ('Web' + 'Socket'),
            ('cu' + 'rl'),
            ('wg' + 'et'),
            ('fet' + 'ch('),
            ('private' + '_key'),
            ('place' + '_order'),
            ('cancel' + '_order'),
            ('sign' + '_order'),
            ('git ' + 'add'),
            ('git ' + 'commit'),
            ('git ' + 'push'),
            ('npm ' + 'install')
        )
        foreach ($item in $forbidden) {
            Assert-True -Condition (-not $content.Contains($item)) -Detail ('forbidden primitive present: {0}' -f $item)
        }
    }

    Invoke-TestCase -Name 'target_script_writes_only_inside_OutputDirectory' -ScriptBlock {
        $caseDir = New-CaseDirectory -Name 'write-scope'
        $inputPath = Join-Path $caseDir 'input.jsonl'
        $outputDirectory = Join-Path $caseDir 'output'
        Write-JsonlFixture -Path $inputPath -Records @((New-ScoringRecord -Index 36 -Prediction 'UP' -OfficialOutcome 'UP'))
        $beforeFiles = @(Get-ChildItem -LiteralPath $caseDir -Recurse -File | ForEach-Object FullName | Sort-Object)
        $result = Invoke-ScorerProcess -InputPath $inputPath -OutputDirectory $outputDirectory
        Assert-Equal -Actual $result.exit_code -Expected 0 -Detail $result.output
        $afterFiles = @(Get-ChildItem -LiteralPath $caseDir -Recurse -File | ForEach-Object FullName | Sort-Object)
        $newFiles = @($afterFiles | Where-Object { $beforeFiles -notcontains $_ })
        Assert-Equal -Actual $newFiles.Count -Expected 4
        foreach ($path in $newFiles) {
            Assert-True -Condition ($path.StartsWith(([System.IO.Path]::GetFullPath($outputDirectory).TrimEnd('\') + '\'), [System.StringComparison]::OrdinalIgnoreCase)) -Detail ('outside output: {0}' -f $path)
        }
        $names = @(Get-ChildItem -LiteralPath $outputDirectory -File | Sort-Object Name | ForEach-Object Name)
        Assert-Equal -Actual ($names -join '|') -Expected 'confusion_matrix.csv|directional_summary.json|manifest.csv|scored_markets.jsonl'
    }

    Invoke-TestCase -Name 'stable_replay_engine_and_test_hashes_unchanged' -ScriptBlock {
        $after = Get-ProtectedHashes
        foreach ($artifactName in $expectedProtectedHashes.Keys) {
            Assert-Equal -Actual $protectedHashesBefore[$artifactName] -Expected $expectedProtectedHashes[$artifactName] -Detail ('before {0}' -f $artifactName)
            Assert-Equal -Actual $after[$artifactName] -Expected $expectedProtectedHashes[$artifactName] -Detail ('after {0}' -f $artifactName)
        }
    }
}
finally {
    $passed = @($testRows | Where-Object { $_.pass }).Count
    $failed = @($testRows | Where-Object { -not $_.pass }).Count
    Write-Output ('TOTAL_TESTS={0}' -f $testRows.Count)
    Write-Output ('PASSED_TESTS={0}' -f $passed)
    Write-Output ('FAILED_TESTS={0}' -f $failed)
    if ($failed -eq 0) {
        Write-Output 'TEST_SUITE_RESULT=PASS'
    }
    else {
        Write-Output 'TEST_SUITE_RESULT=NO_PASS'
    }
}

if (@($testRows | Where-Object { -not $_.pass }).Count -gt 0) {
    exit 1
}
exit 0
