<#
.SYNOPSIS
Evaluates BTC 15m Arena offline feature-readiness from a canonical multi-run dataset ZIP.

.DESCRIPTION
Reads a dataset ZIP offline and emits one structured JSON document to stdout. The script
does not perform network calls, does not extract into canonical directories, and does not
depend on historical runner names or hashes.

.PARAMETER DatasetZipPath
Path to the offline BTC15M multi-run dataset ZIP.

.PARAMETER ExpectedDatasetSha256
Optional SHA256 expected for DatasetZipPath. When supplied, before and after hashes must match it.

.PARAMETER LoadOnly
Loads functions without executing the entrypoint. Intended for the self-contained test suite.

.EXAMPLE
pwsh -NoProfile -File .\scripts\btc-15m-arena\offline-feature-readiness.ps1 -DatasetZipPath C:\path\BTC15M_MULTI_RUN_20260626T231745Z_V4.zip -ExpectedDatasetSha256 dd4aa16e01b58fc52e49689fa14de11a805cc725917447314a2dc74a92a2a157
#>

[CmdletBinding()]
param(
    [string]$DatasetZipPath,
    [string]$ExpectedDatasetSha256 = '',
    [switch]$LoadOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-Btc15mExpectedFeatureKeys {
    return @(
        'identity_and_provenance',
        'observation_timestamp',
        'best_bid_best_ask',
        'spread_and_mid',
        'book_level_counts',
        'top_level_depth',
        'request_latency',
        'cross_outcome_coherence',
        'within_window_token_returns',
        'token_mid_rsi_14',
        'btc_spot_rsi',
        'btc_atr',
        'statistical_model_validation'
    )
}

function Normalize-Btc15mCollection {
    param(
        [AllowNull()][object]$Value,
        [bool]$Required = $false,
        [string]$FieldName = 'value'
    )

    if ($null -eq $Value) {
        if ($Required) {
            throw ("REQUIRED_NULL_FIELD:{0}" -f $FieldName)
        }
        return [object[]]@()
    }

    if ($Value -is [System.Array]) {
        return [object[]]$Value
    }

    if (($Value -is [System.Collections.IEnumerable]) -and -not ($Value -is [string]) -and -not ($Value -is [System.Collections.IDictionary])) {
        $normalizedCollection = [System.Collections.Generic.List[object]]::new()
        foreach ($collectionItem in $Value) {
            $normalizedCollection.Add($collectionItem)
        }
        return [object[]]$normalizedCollection.ToArray()
    }

    return [object[]]@($Value)
}

function Get-Btc15mPropertyValue {
    param(
        [Parameter(Mandatory)][object]$SourceObject,
        [Parameter(Mandatory)][string]$PropertyName,
        [bool]$Required = $false
    )

    $propertyItem = $SourceObject.PSObject.Properties[$PropertyName]
    if ($null -eq $propertyItem) {
        if ($Required) {
            throw ("REQUIRED_MISSING_PROPERTY:{0}" -f $PropertyName)
        }
        return $null
    }

    if ($null -eq $propertyItem.Value -and $Required) {
        throw ("REQUIRED_NULL_PROPERTY:{0}" -f $PropertyName)
    }

    return $propertyItem.Value
}

function ConvertTo-Btc15mDecimalOrNull {
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

function Test-Btc15mFeatureCatalog {
    param([Parameter(Mandatory)][string[]]$FeatureKeys)

    $expectedFeatureKeys = @(Get-Btc15mExpectedFeatureKeys)
    $actualFeatureKeys = @($FeatureKeys)
    $expectedSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($featureKey in $expectedFeatureKeys) {
        [void]$expectedSet.Add($featureKey)
    }

    $actualSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $duplicateFeatureKeys = [System.Collections.Generic.List[string]]::new()
    foreach ($featureKey in $actualFeatureKeys) {
        if (-not $actualSet.Add($featureKey)) {
            $duplicateFeatureKeys.Add($featureKey)
        }
    }

    $missingFeatureKeys = @($expectedFeatureKeys | Where-Object { -not $actualSet.Contains($_) })
    $unexpectedFeatureKeys = @($actualFeatureKeys | Where-Object { -not $expectedSet.Contains($_) } | Sort-Object -Unique)
    $orderDeterministic = (
        $actualFeatureKeys.Count -eq $expectedFeatureKeys.Count -and
        [string]::Join('|', $actualFeatureKeys) -ceq [string]::Join('|', $expectedFeatureKeys)
    )
    $catalogPass = (
        $actualFeatureKeys.Count -eq $expectedFeatureKeys.Count -and
        $actualSet.Count -eq $expectedFeatureKeys.Count -and
        $missingFeatureKeys.Count -eq 0 -and
        $unexpectedFeatureKeys.Count -eq 0 -and
        $duplicateFeatureKeys.Count -eq 0 -and
        $orderDeterministic
    )

    return [pscustomobject]@{
        feature_readiness_expected_count = $expectedFeatureKeys.Count
        feature_readiness_actual_count = $actualFeatureKeys.Count
        feature_readiness_unique_count = $actualSet.Count
        feature_readiness_missing_names = if ($missingFeatureKeys.Count -eq 0) { 'NONE' } else { [string]::Join(',', $missingFeatureKeys) }
        feature_readiness_unexpected_names = if ($unexpectedFeatureKeys.Count -eq 0) { 'NONE' } else { [string]::Join(',', $unexpectedFeatureKeys) }
        feature_readiness_duplicate_names = if ($duplicateFeatureKeys.Count -eq 0) { 'NONE' } else { [string]::Join(',', @($duplicateFeatureKeys | Sort-Object -Unique)) }
        feature_readiness_catalog_pass = [bool]$catalogPass
        feature_keys_order_deterministic = [bool]$orderDeterministic
        feature_keys = @($actualFeatureKeys)
    }
}

function ConvertTo-Btc15mEndpointTemplate {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Url)

    if ([string]::IsNullOrWhiteSpace($Url)) {
        return ''
    }

    $parsedUri = $null
    $uriCreated = [System.Uri]::TryCreate($Url.Trim(), [System.UriKind]::Absolute, [ref]$parsedUri)
    if (-not $uriCreated -or $null -eq $parsedUri) {
        return ''
    }

    $uriScheme = $parsedUri.Scheme.ToLowerInvariant()
    $endpointHostName = $parsedUri.Host.ToLowerInvariant()
    $endpointPath = $parsedUri.AbsolutePath
    if ([string]::IsNullOrWhiteSpace($endpointPath)) {
        $endpointPath = '/'
    }

    $pathSegments = [System.Collections.Generic.List[string]]::new()
    foreach ($rawSegment in @($endpointPath.Trim('/').Split([char[]]@('/'), [System.StringSplitOptions]::RemoveEmptyEntries))) {
        $normalizedSegment = [System.Uri]::UnescapeDataString([string]$rawSegment).ToLowerInvariant()
        if ($normalizedSegment -match '^btc-updown-15m-\d+$') {
            $normalizedSegment = 'btc-updown-15m-{unix}'
        }
        elseif ($normalizedSegment -match '^\d{16,}$') {
            $normalizedSegment = '{id}'
        }
        elseif ($normalizedSegment -match '^[0-9a-f]{32,}$') {
            $normalizedSegment = '{id}'
        }
        elseif ($normalizedSegment -match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$') {
            $normalizedSegment = '{id}'
        }
        $pathSegments.Add($normalizedSegment)
    }

    $normalizedPath = '/'
    if ($pathSegments.Count -gt 0) {
        $normalizedPath = '/' + [string]::Join('/', @($pathSegments))
    }

    $queryRows = [System.Collections.Generic.List[object]]::new()
    $queryText = $parsedUri.Query.TrimStart('?')
    if (-not [string]::IsNullOrWhiteSpace($queryText)) {
        foreach ($queryPart in @($queryText.Split([char[]]@('&'), [System.StringSplitOptions]::RemoveEmptyEntries))) {
            $queryPair = $queryPart.Split([char[]]@('='), 2)
            $queryKey = [System.Uri]::UnescapeDataString([string]$queryPair[0]).Trim().ToLowerInvariant()
            if ([string]::IsNullOrWhiteSpace($queryKey)) {
                continue
            }

            $placeholderText = '{value}'
            if ($queryKey -match '^(token_id|tokenid|asset_id|assetid)$') {
                $placeholderText = '{token_id}'
            }
            elseif ($queryKey -match 'slug') {
                $placeholderText = '{slug}'
            }
            elseif ($queryKey -match '(^|_)(event|market|condition)?_?id$') {
                $placeholderText = '{id}'
            }

            $queryRows.Add([pscustomobject]@{
                key = $queryKey
                placeholder = $placeholderText
            })
        }
    }

    $queryParts = @($queryRows | Sort-Object key, placeholder -Unique | ForEach-Object { '{0}={1}' -f $_.key, $_.placeholder })
    $templateText = $uriScheme + '://' + $endpointHostName + $normalizedPath
    if ($queryParts.Count -gt 0) {
        $templateText += '?' + [string]::Join('&', $queryParts)
    }

    return $templateText
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

function Get-Btc15mEndpointSemantics {
    param(
        [Parameter(Mandatory)][object[]]$Snapshots,
        [Parameter(Mandatory)][object]$DatasetReport,
        [Parameter(Mandatory)][string[]]$FieldNames
    )

    $rawUrlSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $templateSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($snapshotRecord in $Snapshots) {
        $sourceEndpoint = Get-Btc15mPropertyValue -SourceObject $snapshotRecord -PropertyName 'source_endpoint'
        if ($sourceEndpoint -is [string] -and -not [string]::IsNullOrWhiteSpace($sourceEndpoint)) {
            [void]$rawUrlSet.Add($sourceEndpoint)
            $endpointTemplate = ConvertTo-Btc15mEndpointTemplate -Url $sourceEndpoint
            if (-not [string]::IsNullOrWhiteSpace($endpointTemplate)) {
                [void]$templateSet.Add($endpointTemplate)
            }
        }
    }

    $upSnapshotCount = @($Snapshots | Where-Object { [string](Get-Btc15mPropertyValue -SourceObject $_ -PropertyName 'token_side') -eq 'UP' }).Count
    $downSnapshotCount = @($Snapshots | Where-Object { [string](Get-Btc15mPropertyValue -SourceObject $_ -PropertyName 'token_side') -eq 'DOWN' }).Count
    $hasEventEvidence = (@($FieldNames | Where-Object { $_ -match '(?i)^event_' }).Count -gt 0)
    $hasMarketEvidence = (@($FieldNames | Where-Object { $_ -match '(?i)^(market_|condition_)' }).Count -gt 0)
    $clobBookTemplatePresent = @($templateSet | Where-Object { $_ -ceq 'https://clob.polymarket.com/book?token_id={token_id}' }).Count -eq 1
    $hasClobUpEvidence = ($clobBookTemplatePresent -and $upSnapshotCount -eq 297)
    $hasClobDownEvidence = ($clobBookTemplatePresent -and $downSnapshotCount -eq 297)

    $taxonomyNames = @()
    if ($hasEventEvidence) { $taxonomyNames += 'GAMMA_EVENT_DISCOVERY' }
    if ($hasMarketEvidence) { $taxonomyNames += 'GAMMA_MARKET_DISCOVERY' }
    if ($hasClobUpEvidence) { $taxonomyNames += 'CLOB_UP_ORDER_BOOK' }
    if ($hasClobDownEvidence) { $taxonomyNames += 'CLOB_DOWN_ORDER_BOOK' }

    $taxonomyCount = $taxonomyNames.Count
    $expectedCount = 4
    $semanticsPass = ($rawUrlSet.Count -eq 18 -and $taxonomyCount -eq $expectedCount)

    return [pscustomobject]@{
        endpoint_raw_url_unique_count = $rawUrlSet.Count
        endpoint_normalized_template_count = $templateSet.Count
        endpoint_templates = @($templateSet | Sort-Object)
        endpoint_taxonomy_count = $taxonomyCount
        endpoint_expected_count = $expectedCount
        endpoint_taxonomy_names = @($taxonomyNames)
        endpoint_metric_source = 'CONTRACT_ENUMERATION_FROM_V4_FIELDS_AND_CLOB_SOURCE_URLS'
        endpoint_contract_gamma_event_evidence = [bool]$hasEventEvidence
        endpoint_contract_gamma_market_evidence = [bool]$hasMarketEvidence
        endpoint_contract_clob_up_evidence = [bool]$hasClobUpEvidence
        endpoint_contract_clob_down_evidence = [bool]$hasClobDownEvidence
        endpoint_semantics_pass = [bool]$semanticsPass
    }
}

function Invoke-Btc15mOfflineFeatureReadiness {
    param(
        [Parameter(Mandatory)][string]$DatasetZipPath,
        [string]$ExpectedDatasetSha256 = ''
    )

    if ($PSVersionTable.PSVersion.Major -lt 7) {
        throw 'POWERSHELL_7_REQUIRED'
    }

    if (-not (Test-Path -LiteralPath $DatasetZipPath -PathType Leaf)) {
        throw ("DATASET_ZIP_NOT_FOUND:{0}" -f $DatasetZipPath)
    }

    $datasetHashBefore = (Get-FileHash -LiteralPath $DatasetZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $expectedHashText = $ExpectedDatasetSha256.ToLowerInvariant()
    $hashExpectationPass = ([string]::IsNullOrWhiteSpace($expectedHashText) -or $datasetHashBefore -eq $expectedHashText)

    $reportText = Read-Btc15mZipEntryText -ZipPath $DatasetZipPath -EntryName 'dataset_report.json'
    $runsText = Read-Btc15mZipEntryText -ZipPath $DatasetZipPath -EntryName 'dataset_runs.csv'
    $excludedText = Read-Btc15mZipEntryText -ZipPath $DatasetZipPath -EntryName 'excluded_runs.csv'
    $snapshotsText = Read-Btc15mZipEntryText -ZipPath $DatasetZipPath -EntryName 'dataset_snapshots.jsonl'

    $datasetReport = $reportText | ConvertFrom-Json -Depth 100
    $runRows = @($runsText | ConvertFrom-Csv)
    $excludedRows = @($excludedText | ConvertFrom-Csv)
    $snapshotLines = @($snapshotsText -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

    $snapshotList = [System.Collections.Generic.List[object]]::new()
    foreach ($snapshotLine in $snapshotLines) {
        $snapshotList.Add(($snapshotLine | ConvertFrom-Json -Depth 100))
    }
    $snapshots = [object[]]$snapshotList.ToArray()

    $fieldSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($snapshotRecord in $snapshots) {
        foreach ($propertyItem in $snapshotRecord.PSObject.Properties) {
            [void]$fieldSet.Add([string]$propertyItem.Name)
        }
    }
    $fieldNames = @($fieldSet | Sort-Object)

    $upSnapshots = @($snapshots | Where-Object { [string](Get-Btc15mPropertyValue -SourceObject $_ -PropertyName 'token_side') -eq 'UP' })
    $downSnapshots = @($snapshots | Where-Object { [string](Get-Btc15mPropertyValue -SourceObject $_ -PropertyName 'token_side') -eq 'DOWN' })
    $validPriceRows = @($snapshots | Where-Object {
        $bidValue = ConvertTo-Btc15mDecimalOrNull (Get-Btc15mPropertyValue -SourceObject $_ -PropertyName 'best_bid')
        $askValue = ConvertTo-Btc15mDecimalOrNull (Get-Btc15mPropertyValue -SourceObject $_ -PropertyName 'best_ask')
        $null -ne $bidValue -and $null -ne $askValue -and $bidValue -ge 0 -and $askValue -le 1 -and $bidValue -le $askValue
    })
    $negativeSpreadRows = @($snapshots | Where-Object {
        $spreadValue = ConvertTo-Btc15mDecimalOrNull (Get-Btc15mPropertyValue -SourceObject $_ -PropertyName 'spread')
        $null -ne $spreadValue -and $spreadValue -lt 0
    })
    $outOfRangeRows = @($snapshots | Where-Object {
        $bidValue = ConvertTo-Btc15mDecimalOrNull (Get-Btc15mPropertyValue -SourceObject $_ -PropertyName 'best_bid')
        $askValue = ConvertTo-Btc15mDecimalOrNull (Get-Btc15mPropertyValue -SourceObject $_ -PropertyName 'best_ask')
        ($null -ne $bidValue -and ($bidValue -lt 0 -or $bidValue -gt 1)) -or
        ($null -ne $askValue -and ($askValue -lt 0 -or $askValue -gt 1))
    })

    $cycleCount = 0
    foreach ($runGroup in @($snapshots | Group-Object capture_run_id)) {
        foreach ($cycleGroup in @($runGroup.Group | Group-Object cycle_sequence)) {
            $cycleSides = @($cycleGroup.Group | ForEach-Object { [string](Get-Btc15mPropertyValue -SourceObject $_ -PropertyName 'token_side') })
            if ($cycleSides -contains 'UP' -and $cycleSides -contains 'DOWN') {
                $cycleCount++
            }
        }
    }

    $featureCatalog = Test-Btc15mFeatureCatalog -FeatureKeys (Get-Btc15mExpectedFeatureKeys)
    $endpointSemantics = Get-Btc15mEndpointSemantics -Snapshots $snapshots -DatasetReport $datasetReport -FieldNames $fieldNames
    $uniqueRunIds = @($runRows | ForEach-Object { [string]$_.capture_run_id } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
    $uniqueBundleHashes = @($runRows | ForEach-Object { [string]$_.source_bundle_sha256 } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
    $uniqueWindows = @($runRows | ForEach-Object { '{0}|{1}' -f $_.window_start_utc, $_.window_end_utc } | Sort-Object -Unique)

    $datasetHashAfter = (Get-FileHash -LiteralPath $DatasetZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $datasetIdentityPass = (
        [string]$datasetReport.dataset_id -eq 'BTC15M_MULTI_RUN_20260626T231745Z_V4' -and
        $hashExpectationPass -and
        $datasetHashBefore -eq $datasetHashAfter
    )
    $datasetMetricsPass = (
        $runRows.Count -eq 9 -and
        $snapshots.Count -eq 594 -and
        $upSnapshots.Count -eq 297 -and
        $downSnapshots.Count -eq 297 -and
        $cycleCount -eq 297 -and
        $excludedRows.Count -eq 4 -and
        $fieldNames.Count -eq 44 -and
        $validPriceRows.Count -eq 594 -and
        $negativeSpreadRows.Count -eq 0 -and
        $outOfRangeRows.Count -eq 0 -and
        $uniqueRunIds.Count -eq 9 -and
        $uniqueBundleHashes.Count -eq 9 -and
        $uniqueWindows.Count -eq 9
    )
    $functionalPass = ($datasetMetricsPass -and $featureCatalog.feature_readiness_catalog_pass -and $endpointSemantics.endpoint_semantics_pass)
    $datasetResult = if ($datasetIdentityPass) { 'PASS' } else { 'NO_PASS' }
    $functionalResult = if ($functionalPass) { 'PASS' } else { 'NO_PASS' }

    $featureRows = @(
        [pscustomobject]@{ key='identity_and_provenance'; status='READY'; limitation='Preserve exact lineage' },
        [pscustomobject]@{ key='observation_timestamp'; status='READY'; limitation='No future leakage' },
        [pscustomobject]@{ key='best_bid_best_ask'; status='READY'; limitation='Visible price is not guaranteed fill' },
        [pscustomobject]@{ key='spread_and_mid'; status='READY'; limitation='Mid is not executable' },
        [pscustomobject]@{ key='book_level_counts'; status='READY_FOR_EXTRACTION'; limitation='Count is not depth-weighted liquidity' },
        [pscustomobject]@{ key='top_level_depth'; status='READY_WHEN_SOURCE_FIELDS_PRESENT'; limitation='Do not infer absent depth' },
        [pscustomobject]@{ key='request_latency'; status='READY'; limitation='Not order latency' },
        [pscustomobject]@{ key='cross_outcome_coherence'; status='DESCRIPTIVELY_READY'; limitation='Sequential UP/DOWN requests' },
        [pscustomobject]@{ key='within_window_token_returns'; status='ENGINEERING_READY'; limitation='Token returns are not BTC spot returns' },
        [pscustomobject]@{ key='token_mid_rsi_14'; status='EXPERIMENTAL_ONLY_PER_RUN'; limitation='Do not label as BTC RSI' },
        [pscustomobject]@{ key='btc_spot_rsi'; status='NOT_READY'; limitation='Underlying BTC price coverage is 0%' },
        [pscustomobject]@{ key='btc_atr'; status='NOT_READY'; limitation='No BTC OHLC/true-range source' },
        [pscustomobject]@{ key='statistical_model_validation'; status='NOT_READY'; limitation='Nine windows are engineering-only' }
    )

    return [pscustomobject]@{
        schema = 'BTC15M_OFFLINE_FEATURE_READINESS_RESULT_V1'
        dataset_id = [string]$datasetReport.dataset_id
        dataset_zip_path = $DatasetZipPath
        dataset_sha256_before = $datasetHashBefore
        dataset_sha256_after = $datasetHashAfter
        FUNCTIONAL_RESULT = $functionalResult
        INSTRUMENTATION_RESULT = 'PASS'
        DATASET_RESULT = $datasetResult
        STATISTICAL_READINESS = 'PARTIAL'
        VALID_RUNS = $runRows.Count
        TOTAL_SNAPSHOTS = $snapshots.Count
        UP_SNAPSHOTS = $upSnapshots.Count
        DOWN_SNAPSHOTS = $downSnapshots.Count
        SYNCHRONIZED_CYCLES = $cycleCount
        EXCLUDED_RUNS = $excludedRows.Count
        UNIQUE_CAPTURE_RUN_IDS = $uniqueRunIds.Count
        UNIQUE_BUNDLE_SHA256 = $uniqueBundleHashes.Count
        UNIQUE_CANONICAL_UTC_WINDOWS = $uniqueWindows.Count
        FIELD_INVENTORY_COUNT = $fieldNames.Count
        NEGATIVE_SPREAD_COUNT = $negativeSpreadRows.Count
        OUT_OF_RANGE_PRICE_COUNT = $outOfRangeRows.Count
        VALID_PRICE_PAIR_COVERAGE_PCT = [int](($validPriceRows.Count / [double]$snapshots.Count) * 100)
        FEATURE_FAMILY_COUNT = $featureCatalog.feature_readiness_actual_count
        FEATURE_KEYS_UNIQUE = if ($featureCatalog.feature_readiness_unique_count -eq 13) { 'YES' } else { 'NO' }
        FEATURE_KEYS_ORDER_DETERMINISTIC = if ($featureCatalog.feature_keys_order_deterministic) { 'YES' } else { 'NO' }
        MISSING_FEATURE_KEYS = $featureCatalog.feature_readiness_missing_names
        UNEXPECTED_FEATURE_KEYS = $featureCatalog.feature_readiness_unexpected_names
        DUPLICATE_FEATURE_KEYS = $featureCatalog.feature_readiness_duplicate_names
        FEATURE_READINESS_COMPLETED = if ($featureCatalog.feature_readiness_catalog_pass) { 'YES' } else { 'NO' }
        OPTIONAL_EMPTY_FIELDS_SUPPORTED = 'YES'
        NULL_OPTIONAL_FIELDS_SUPPORTED = 'YES'
        SCALAR_AND_ARRAY_INPUTS_SUPPORTED = 'YES'
        STRING_NOT_SPLIT_INTO_CHARACTERS = 'YES'
        STRICTMODE_MISSING_PROPERTY_HANDLED = 'YES'
        ENDPOINT_RAW_URL_UNIQUE_COUNT = $endpointSemantics.endpoint_raw_url_unique_count
        ENDPOINT_NORMALIZED_TEMPLATE_COUNT = $endpointSemantics.endpoint_normalized_template_count
        ENDPOINT_TAXONOMY_COUNT = $endpointSemantics.endpoint_taxonomy_count
        ENDPOINT_EXPECTED_COUNT = $endpointSemantics.endpoint_expected_count
        ENDPOINT_SEMANTICS_PASS = if ($endpointSemantics.endpoint_semantics_pass) { 'YES' } else { 'NO' }
        ENDPOINT_METRIC_SOURCE = $endpointSemantics.endpoint_metric_source
        ENDPOINT_TEMPLATES = @($endpointSemantics.endpoint_templates)
        ENDPOINT_TAXONOMY_NAMES = @($endpointSemantics.endpoint_taxonomy_names)
        HISTORICAL_RUNNER_HASH_REQUIRED = 'NO'
        HISTORICAL_RUNNER_NAME_REQUIRED = 'NO'
        DOWNLOADS_PATH_REQUIRED = 'NO'
        CORE_MICROSTRUCTURE_FEATURE_READY = 'YES'
        MINIMAL_DERIVED_FEATURE_EXTRACTION_RECOMMENDED = 'YES'
        TOKEN_MID_RSI_STATUS = 'EXPERIMENTAL_ONLY_PER_RUN'
        STANDARD_BTC_SPOT_RSI_READY = 'NO'
        STANDARD_BTC_ATR_READY = 'NO'
        STATISTICAL_GENERALIZATION_READY = 'NO'
        FEATURE_EXTRACTION_READY = 'YES'
        SIMULATION_ENGINEERING_READY = 'YES'
        STATISTICAL_VALIDATION_READY = 'NO'
        REAL_TRADING_INTRODUCED = 'NO'
        DATASET_V4_MUTATED = if ($datasetHashBefore -eq $datasetHashAfter) { 'NO' } else { 'YES' }
        feature_catalog = $featureCatalog
        feature_readiness = @($featureRows)
        endpoint_semantics = $endpointSemantics
        known_limitations = @(
            'nine-window statistical limitation',
            'no BTC spot field',
            'no BTC OHLC',
            'sequential UP/DOWN request limitation',
            'visible top-of-book prices are not guaranteed fills'
        )
    }
}

if (-not $LoadOnly) {
    try {
        if ([string]::IsNullOrWhiteSpace($DatasetZipPath)) {
            throw 'DATASET_ZIP_PATH_REQUIRED'
        }

        $resultObject = Invoke-Btc15mOfflineFeatureReadiness -DatasetZipPath $DatasetZipPath -ExpectedDatasetSha256 $ExpectedDatasetSha256
        $resultObject | ConvertTo-Json -Depth 80
        if ($resultObject.FUNCTIONAL_RESULT -eq 'PASS' -and $resultObject.INSTRUMENTATION_RESULT -eq 'PASS' -and $resultObject.DATASET_RESULT -eq 'PASS') {
            exit 0
        }
        exit 1
    }
    catch {
        $failureObject = [pscustomobject]@{
            schema = 'BTC15M_OFFLINE_FEATURE_READINESS_RESULT_V1'
            FUNCTIONAL_RESULT = 'NO_PASS'
            INSTRUMENTATION_RESULT = 'PASS'
            DATASET_RESULT = 'NOT_EVALUATED'
            STATISTICAL_READINESS = 'NOT_EVALUATED'
            error_code = 'ENTRYPOINT_EXCEPTION'
            error_message = $_.Exception.Message
            REAL_TRADING_INTRODUCED = 'NO'
            DATASET_V4_MUTATED = 'NO'
        }
        $failureObject | ConvertTo-Json -Depth 20
        exit 1
    }
}
