<#
.SYNOPSIS
Self-contained regression suite for offline-feature-readiness.ps1.

.DESCRIPTION
Runs without Pester or installed dependencies. Temporary files are created only below
scripts\btc-15m-arena\.codex-tmp-root-cause-repair-v1 and removed before exit.
#>

[CmdletBinding()]
param(
    [string]$DatasetZipPath = 'C:\Users\JoanAB\Documents\BTC_15M_ARENA_OPERATIONS\10_ACTIVE\INPUTS\MULTI_RUN_DATASETS\BTC15M_MULTI_RUN_20260626T231745Z_V4.zip',
    [string]$ExpectedDatasetSha256 = 'dd4aa16e01b58fc52e49689fa14de11a805cc725917447314a2dc74a92a2a157'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot 'offline-feature-readiness.ps1'
$tempRootPath = Join-Path $PSScriptRoot '.codex-tmp-root-cause-repair-v1'
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
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$parseTokens, [ref]$parseErrors) | Out-Null
    return @($parseErrors)
}

function Test-NoForbiddenVariableAssignments {
    param([string[]]$Paths)

    $forbiddenNames = @('host', 'home', 'pid', 'error', 'args', 'input', 'matches', 'psversiontable')
    $violations = [System.Collections.Generic.List[string]]::new()
    foreach ($targetPath in $Paths) {
        $parseTokens = $null
        $parseErrors = $null
        $astRoot = [System.Management.Automation.Language.Parser]::ParseFile($targetPath, [ref]$parseTokens, [ref]$parseErrors)
        if (@($parseErrors).Count -ne 0) {
            $violations.Add(("parse:{0}" -f $targetPath))
            continue
        }

        $assignmentAsts = $astRoot.FindAll({
            param($astNode)
            $astNode -is [System.Management.Automation.Language.AssignmentStatementAst]
        }, $true)

        foreach ($assignmentAst in $assignmentAsts) {
            $variableExpression = $assignmentAst.Left.Find({
                param($leftNode)
                $leftNode -is [System.Management.Automation.Language.VariableExpressionAst]
            }, $true)
            if ($null -eq $variableExpression) {
                continue
            }

            $variableName = $variableExpression.VariablePath.UserPath.ToLowerInvariant()
            if ($forbiddenNames -contains $variableName) {
                $violations.Add(("{0}:{1}" -f $targetPath, $variableName))
            }
        }
    }

    return @($violations)
}

if (Test-Path -LiteralPath $tempRootPath) {
    Remove-Item -LiteralPath $tempRootPath -Recurse -Force
}
New-Item -ItemType Directory -Path $tempRootPath | Out-Null

try {
    . $scriptPath -LoadOnly -DatasetZipPath $DatasetZipPath -ExpectedDatasetSha256 $ExpectedDatasetSha256

    Assert-True -Name 'entrypoint_exists' -Condition (Test-Path -LiteralPath $scriptPath -PathType Leaf)
    Assert-Equal -Name 'entrypoint_ast_parse' -Actual (@(Test-PowerShellParse -Path $scriptPath).Count) -Expected 0
    Assert-Equal -Name 'tests_ast_parse' -Actual (@(Test-PowerShellParse -Path $PSCommandPath).Count) -Expected 0

    $resolvedTempRootPath = [System.IO.Path]::GetFullPath($tempRootPath)
    $resolvedScriptRootPath = [System.IO.Path]::GetFullPath($PSScriptRoot)
    $resolvedLegacyWrongTempRootPath = [System.IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $PSScriptRoot) 'btc-15m-arena.codex-tmp-root-cause-repair-v1'))
    Assert-True -Name 'temp_root_exact_authorized_path' -Condition (
        [System.IO.Directory]::GetParent($resolvedTempRootPath).FullName -ceq $resolvedScriptRootPath -and
        [System.IO.Path]::GetFileName($resolvedTempRootPath) -ceq '.codex-tmp-root-cause-repair-v1'
    ) -Detail $resolvedTempRootPath
    Assert-True -Name 'temp_root_within_authorized_scope' -Condition (
        $resolvedTempRootPath.StartsWith($resolvedScriptRootPath + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase) -and
        $resolvedTempRootPath -cne $resolvedLegacyWrongTempRootPath
    ) -Detail $resolvedTempRootPath

    $expectedFeatureKeys = @(Get-Btc15mExpectedFeatureKeys)
    $catalogResult = Test-Btc15mFeatureCatalog -FeatureKeys $expectedFeatureKeys
    Assert-Equal -Name 'catalog_exact_13_keys' -Actual $catalogResult.feature_readiness_actual_count -Expected 13
    Assert-True -Name 'catalog_order_deterministic' -Condition $catalogResult.feature_keys_order_deterministic
    Assert-True -Name 'catalog_unique' -Condition ($catalogResult.feature_readiness_unique_count -eq 13)

    $missingCatalog = Test-Btc15mFeatureCatalog -FeatureKeys @($expectedFeatureKeys | Where-Object { $_ -ne 'btc_atr' })
    Assert-True -Name 'catalog_missing_key_fails' -Condition (-not $missingCatalog.feature_readiness_catalog_pass)
    $unexpectedCatalog = Test-Btc15mFeatureCatalog -FeatureKeys @($expectedFeatureKeys + 'unexpected_feature')
    Assert-True -Name 'catalog_unexpected_key_fails' -Condition (-not $unexpectedCatalog.feature_readiness_catalog_pass)
    $duplicateCatalog = Test-Btc15mFeatureCatalog -FeatureKeys @($expectedFeatureKeys + 'btc_atr')
    Assert-True -Name 'catalog_duplicate_key_fails' -Condition (-not $duplicateCatalog.feature_readiness_catalog_pass)
    $duplicateMissingKeys = @($expectedFeatureKeys | Where-Object { $_ -ne 'btc_atr' }) + 'btc_spot_rsi'
    $duplicateMissingCatalog = Test-Btc15mFeatureCatalog -FeatureKeys $duplicateMissingKeys
    Assert-True -Name 'catalog_duplicate_plus_missing_fails' -Condition (-not $duplicateMissingCatalog.feature_readiness_catalog_pass)
    Assert-True -Name 'catalog_rejects_12_expected_count' -Condition ((Get-Btc15mExpectedFeatureKeys).Count -ne 12)
    Assert-True -Name 'catalog_requires_statistical_model_validation' -Condition ($expectedFeatureKeys -contains 'statistical_model_validation')

    Assert-Equal -Name 'normalize_null_optional' -Actual (@(Normalize-Btc15mCollection -Value $null).Count) -Expected 0
    $emptyArray = [object[]]@()
    Assert-Equal -Name 'normalize_empty_array' -Actual (@(Normalize-Btc15mCollection -Value $emptyArray).Count) -Expected 0
    Assert-Equal -Name 'normalize_scalar_string_one_item' -Actual (@(Normalize-Btc15mCollection -Value 'abc').Count) -Expected 1
    Assert-Equal -Name 'string_not_split_into_characters' -Actual ([string](@(Normalize-Btc15mCollection -Value 'abc')[0])) -Expected 'abc'
    Assert-Equal -Name 'normalize_scalar_number_one_item' -Actual (@(Normalize-Btc15mCollection -Value 7).Count) -Expected 1
    Assert-Equal -Name 'normalize_single_array' -Actual (@(Normalize-Btc15mCollection -Value @('one')).Count) -Expected 1
    Assert-Equal -Name 'normalize_multi_array' -Actual (@(Normalize-Btc15mCollection -Value @('one', 'two')).Count) -Expected 2
    $missingObject = [pscustomobject]@{ present = 'yes' }
    Assert-Equal -Name 'missing_optional_property_strictmode' -Actual (Get-Btc15mPropertyValue -SourceObject $missingObject -PropertyName 'absent') -Expected ''
    $requiredNullRejected = $false
    try { [void](Normalize-Btc15mCollection -Value $null -Required $true -FieldName 'required') } catch { $requiredNullRejected = $true }
    Assert-True -Name 'required_null_rejected' -Condition $requiredNullRejected
    $jsonWithEmptyArray = ([pscustomobject]@{ items = [object[]]@() } | ConvertTo-Json -Depth 5 -Compress)
    Assert-True -Name 'array_empty_serializes_as_brackets' -Condition ($jsonWithEmptyArray.Contains('"items":[]')) -Detail $jsonWithEmptyArray

    $clobTemplateA = ConvertTo-Btc15mEndpointTemplate -Url 'https://clob.polymarket.com/book?token_id=111'
    $clobTemplateB = ConvertTo-Btc15mEndpointTemplate -Url 'https://clob.polymarket.com/book?token_id=222'
    Assert-Equal -Name 'clob_url_normalizes' -Actual $clobTemplateA -Expected 'https://clob.polymarket.com/book?token_id={token_id}'
    Assert-Equal -Name 'multiple_raw_urls_same_template' -Actual $clobTemplateB -Expected $clobTemplateA
    $gammaTemplate = ConvertTo-Btc15mEndpointTemplate -Url 'https://gamma-api.polymarket.com/events/slug/btc-updown-15m-1780000000'
    Assert-Equal -Name 'gamma_slug_url_normalizes' -Actual $gammaTemplate -Expected 'https://gamma-api.polymarket.com/events/slug/btc-updown-15m-{unix}'
    $gammaQueryA = ConvertTo-Btc15mEndpointTemplate -Url 'https://gamma-api.polymarket.com/markets?active=true&closed=false&slug=btc-updown-15m-1780000000'
    $gammaQueryB = ConvertTo-Btc15mEndpointTemplate -Url 'https://gamma-api.polymarket.com/markets?slug=btc-updown-15m-1790000000&closed=false&active=true'
    Assert-Equal -Name 'query_parameter_values_do_not_create_new_families' -Actual $gammaQueryA -Expected $gammaQueryB
    Assert-True -Name 'raw_count_can_differ_from_taxonomy' -Condition (@('u1', 'u2').Count -ne @($clobTemplateA | Sort-Object -Unique).Count)

    $autoVariableViolations = @(Test-NoForbiddenVariableAssignments -Paths @($scriptPath, $PSCommandPath))
    Assert-Equal -Name 'no_forbidden_automatic_variable_assignments' -Actual $autoVariableViolations.Count -Expected 0
    $scriptSource = Get-Content -LiteralPath $scriptPath -Raw
    Assert-True -Name 'historical_runner_hash_not_required' -Condition (-not ($scriptSource -match 'ExpectedPreviousStandaloneRunnerSha256|previous_standalone|runner_sha256'))
    Assert-True -Name 'historical_runner_name_not_required' -Condition (-not ($scriptSource -match '01_RUNNER_BTC15M|RUNNER_BTC15M_V4'))
    Assert-True -Name 'downloads_path_not_required' -Condition (-not ($scriptSource -match '\\Downloads\\|C:\\Users\\JoanAB\\Downloads'))

    $pointerPath = 'C:\Users\JoanAB\Documents\BTC_15M_ARENA_OPERATIONS\10_ACTIVE\INPUTS\MULTI_RUN_DATASETS\CANONICAL_BASELINE.json'
    $baselineRegistryPath = 'C:\Users\JoanAB\Documents\BTC_15M_ARENA_OPERATIONS\10_ACTIVE\INPUTS\MULTI_RUN_DATASETS\BASELINE_REGISTRY.csv'
    $artifactRegistryPath = 'C:\Users\JoanAB\Documents\BTC_15M_ARENA_OPERATIONS\10_ACTIVE\ARTIFACT_REGISTRY.csv'
    $pointerHashBefore = (Get-FileHash -LiteralPath $pointerPath -Algorithm SHA256).Hash
    $baselineRegistryHashBefore = (Get-FileHash -LiteralPath $baselineRegistryPath -Algorithm SHA256).Hash
    $artifactRegistryHashBefore = (Get-FileHash -LiteralPath $artifactRegistryPath -Algorithm SHA256).Hash
    $hashBefore = (Get-FileHash -LiteralPath $DatasetZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $stdoutPath = Join-Path $tempRootPath 'entrypoint.stdout.json'
    $stderrPath = Join-Path $tempRootPath 'entrypoint.stderr.txt'
    $entryOutput = & pwsh -NoProfile -File $scriptPath -DatasetZipPath $DatasetZipPath -ExpectedDatasetSha256 $ExpectedDatasetSha256 2> $stderrPath
    $entryExitCode = $LASTEXITCODE
    $entryOutput | Set-Content -LiteralPath $stdoutPath -Encoding utf8NoBOM
    $stderrText = [string](Get-Content -LiteralPath $stderrPath -Raw)
    $stdoutText = [string](Get-Content -LiteralPath $stdoutPath -Raw)
    $entryJson = $stdoutText | ConvertFrom-Json -Depth 100
    $hashAfter = (Get-FileHash -LiteralPath $DatasetZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $pointerHashAfter = (Get-FileHash -LiteralPath $pointerPath -Algorithm SHA256).Hash
    $baselineRegistryHashAfter = (Get-FileHash -LiteralPath $baselineRegistryPath -Algorithm SHA256).Hash
    $artifactRegistryHashAfter = (Get-FileHash -LiteralPath $artifactRegistryPath -Algorithm SHA256).Hash

    Assert-Equal -Name 'entrypoint_exit_code_zero' -Actual $entryExitCode -Expected 0
    Assert-True -Name 'stdout_structured_json_valid' -Condition ($null -ne $entryJson)
    Assert-True -Name 'stdout_single_json_document' -Condition ($stdoutText.TrimStart().StartsWith('{') -and $stdoutText.TrimEnd().EndsWith('}'))
    Assert-True -Name 'stderr_empty' -Condition ([string]::IsNullOrWhiteSpace($stderrText)) -Detail $stderrText
    Assert-Equal -Name 'result_layers_functional_pass' -Actual $entryJson.FUNCTIONAL_RESULT -Expected 'PASS'
    Assert-Equal -Name 'result_layers_instrumentation_pass' -Actual $entryJson.INSTRUMENTATION_RESULT -Expected 'PASS'
    Assert-Equal -Name 'result_layers_dataset_pass' -Actual $entryJson.DATASET_RESULT -Expected 'PASS'
    Assert-Equal -Name 'result_layers_statistical_partial' -Actual $entryJson.STATISTICAL_READINESS -Expected 'PARTIAL'
    Assert-Equal -Name 'v4_valid_runs' -Actual $entryJson.VALID_RUNS -Expected 9
    Assert-Equal -Name 'v4_total_snapshots' -Actual $entryJson.TOTAL_SNAPSHOTS -Expected 594
    Assert-Equal -Name 'v4_up_snapshots' -Actual $entryJson.UP_SNAPSHOTS -Expected 297
    Assert-Equal -Name 'v4_down_snapshots' -Actual $entryJson.DOWN_SNAPSHOTS -Expected 297
    Assert-Equal -Name 'v4_synchronized_cycles' -Actual $entryJson.SYNCHRONIZED_CYCLES -Expected 297
    Assert-Equal -Name 'v4_excluded_runs' -Actual $entryJson.EXCLUDED_RUNS -Expected 4
    Assert-Equal -Name 'v4_field_inventory_count' -Actual $entryJson.FIELD_INVENTORY_COUNT -Expected 44
    Assert-Equal -Name 'endpoint_raw_unique_count_18' -Actual $entryJson.ENDPOINT_RAW_URL_UNIQUE_COUNT -Expected 18
    Assert-Equal -Name 'endpoint_taxonomy_count_4' -Actual $entryJson.ENDPOINT_TAXONOMY_COUNT -Expected 4
    Assert-Equal -Name 'endpoint_semantics_pass' -Actual $entryJson.ENDPOINT_SEMANTICS_PASS -Expected 'YES'
    Assert-Equal -Name 'feature_family_count_13' -Actual $entryJson.FEATURE_FAMILY_COUNT -Expected 13
    Assert-Equal -Name 'feature_keys_unique_yes' -Actual $entryJson.FEATURE_KEYS_UNIQUE -Expected 'YES'
    Assert-Equal -Name 'optional_empty_fields_supported' -Actual $entryJson.OPTIONAL_EMPTY_FIELDS_SUPPORTED -Expected 'YES'
    Assert-Equal -Name 'scalar_and_array_inputs_supported' -Actual $entryJson.SCALAR_AND_ARRAY_INPUTS_SUPPORTED -Expected 'YES'
    Assert-Equal -Name 'historical_runner_hash_required_no' -Actual $entryJson.HISTORICAL_RUNNER_HASH_REQUIRED -Expected 'NO'
    Assert-Equal -Name 'dataset_v4_mutated_no' -Actual $entryJson.DATASET_V4_MUTATED -Expected 'NO'
    Assert-Equal -Name 'v4_hash_before_after_identical' -Actual $hashAfter -Expected $hashBefore
    Assert-Equal -Name 'pointer_hash_unchanged_across_entrypoint' -Actual $pointerHashAfter -Expected $pointerHashBefore
    Assert-Equal -Name 'baseline_registry_hash_unchanged_across_entrypoint' -Actual $baselineRegistryHashAfter -Expected $baselineRegistryHashBefore
    Assert-Equal -Name 'artifact_registry_hash_unchanged_across_entrypoint' -Actual $artifactRegistryHashAfter -Expected $artifactRegistryHashBefore

    $summary = [pscustomobject]@{
        schema = 'BTC15M_OFFLINE_FEATURE_READINESS_TEST_RESULT_V1'
        result = 'PASS'
        test_count = $testRows.Count
        tests = @($testRows)
    }
    $summary | ConvertTo-Json -Depth 20
    exit 0
}
catch {
    $failureSummary = [pscustomobject]@{
        schema = 'BTC15M_OFFLINE_FEATURE_READINESS_TEST_RESULT_V1'
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
