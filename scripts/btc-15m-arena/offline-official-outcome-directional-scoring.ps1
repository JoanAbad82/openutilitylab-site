<#
.SYNOPSIS
Scores offline authoritative BTC 15m Arena UP/DOWN outcomes against directional predictions.
#>

#requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InputPath,
    [Parameter(Mandatory)][string]$OutputDirectory,
    [switch]$Overwrite
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:OutputFileNames = @(
    'scored_markets.jsonl',
    'directional_summary.json',
    'confusion_matrix.csv',
    'manifest.csv'
)
$script:ManifestMemberNames = @(
    'scored_markets.jsonl',
    'directional_summary.json',
    'confusion_matrix.csv'
)
$script:InvariantCulture = [System.Globalization.CultureInfo]::InvariantCulture

function Get-ScoringProperty {
    param(
        [Parameter(Mandatory)][object]$SourceObject,
        [Parameter(Mandatory)][string]$PropertyName
    )

    $propertyItem = $SourceObject.PSObject.Properties[$PropertyName]
    if ($null -eq $propertyItem) { return $null }
    return $propertyItem.Value
}

function Test-ScoringBlank {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) { return $true }
    return [string]::IsNullOrWhiteSpace([string]$Value)
}

function Assert-ScoringCondition {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$FailureCode,
        [string]$Detail = ''
    )

    if (-not $Condition) {
        if ([string]::IsNullOrWhiteSpace($Detail)) {
            throw $FailureCode
        }
        throw ('{0}:{1}' -f $FailureCode, $Detail)
    }
}

function ConvertTo-ScoringUtcDate {
    param(
        [AllowNull()][object]$Value,
        [Parameter(Mandatory)][string]$FieldName,
        [Parameter(Mandatory)][int]$LineNumber
    )

    Assert-ScoringCondition -Condition (-not (Test-ScoringBlank -Value $Value)) -FailureCode 'MISSING_TIMESTAMP' -Detail ('line={0};field={1}' -f $LineNumber, $FieldName)
    $textValue = ([string]$Value).Trim()
    Assert-ScoringCondition -Condition ($textValue -match '(Z|[+-]\d{2}:\d{2})$') -FailureCode 'TIMESTAMP_MISSING_EXPLICIT_OFFSET' -Detail ('line={0};field={1}' -f $LineNumber, $FieldName)
    try {
        return [System.DateTimeOffset]::Parse($textValue, $script:InvariantCulture, [System.Globalization.DateTimeStyles]::None).ToUniversalTime()
    }
    catch {
        throw ('INVALID_TIMESTAMP:line={0};field={1};value={2}' -f $LineNumber, $FieldName, $textValue)
    }
}

function ConvertTo-ScoringNullableUtcDate {
    param(
        [AllowNull()][object]$Value,
        [Parameter(Mandatory)][string]$FieldName,
        [Parameter(Mandatory)][int]$LineNumber
    )

    if (Test-ScoringBlank -Value $Value) { return $null }
    return ConvertTo-ScoringUtcDate -Value $Value -FieldName $FieldName -LineNumber $LineNumber
}

function ConvertTo-ScoringDecimal {
    param(
        [AllowNull()][object]$Value,
        [Parameter(Mandatory)][string]$FieldName,
        [Parameter(Mandatory)][int]$LineNumber
    )

    if (Test-ScoringBlank -Value $Value) { return $null }

    $textValue = ([string]$Value).Trim()
    $decimalValue = [decimal]0
    if ([decimal]::TryParse($textValue, [System.Globalization.NumberStyles]::Float, $script:InvariantCulture, [ref]$decimalValue)) {
        return $decimalValue
    }

    throw ('INVALID_RECONSTRUCTED_PRICE:line={0};field={1};value={2}' -f $LineNumber, $FieldName, $textValue)
}

function Format-ScoringUtc {
    param([Parameter(Mandatory)][System.DateTimeOffset]$Value)

    return $Value.ToUniversalTime().UtcDateTime.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ', $script:InvariantCulture)
}

function Format-ScoringNullableUtc {
    param([AllowNull()][System.Nullable[System.DateTimeOffset]]$Value)

    if ($null -eq $Value) { return $null }
    return Format-ScoringUtc -Value $Value
}

function ConvertTo-ScoringStableJson {
    param([Parameter(Mandatory)][object]$Value)

    $json = $Value | ConvertTo-Json -Depth 80
    return (($json -replace "`r`n", "`n") -replace "`r", "`n")
}

function ConvertTo-ScoringJsonLine {
    param([Parameter(Mandatory)][object]$Value)

    $json = $Value | ConvertTo-Json -Depth 80 -Compress
    return (($json -replace "`r`n", "`n") -replace "`r", "`n")
}

function ConvertTo-ScoringCsvCell {
    param([AllowNull()][object]$Value)

    $cellText = if ($null -eq $Value) { '' } else { [string]$Value }
    if ($cellText -match '[,"\r\n]') {
        return '"' + $cellText.Replace('"', '""') + '"'
    }
    return $cellText
}

function ConvertTo-ScoringCsv {
    param(
        [Parameter(Mandatory)][object[]]$Rows,
        [Parameter(Mandatory)][string[]]$Columns
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add([string]::Join(',', $Columns))
    foreach ($row in $Rows) {
        $cells = [System.Collections.Generic.List[string]]::new()
        foreach ($columnName in $Columns) {
            $cells.Add((ConvertTo-ScoringCsvCell -Value (Get-ScoringProperty -SourceObject $row -PropertyName $columnName)))
        }
        $lines.Add([string]::Join(',', $cells))
    }
    return ([string]::Join("`n", $lines) + "`n")
}

function Set-ScoringFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Content
    )

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Get-ScoringFileSha256Lower {
    param([Parameter(Mandatory)][string]$Path)

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-ScoringLineCount {
    param([Parameter(Mandatory)][string]$Path)

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $count = 0
    foreach ($byteValue in $bytes) {
        if ($byteValue -eq 10) { $count++ }
    }
    return $count
}

function Resolve-ScoringOutputDirectory {
    param(
        [Parameter(Mandatory)][string]$DirectoryPath,
        [Parameter(Mandatory)][bool]$AllowOverwrite
    )

    Assert-ScoringCondition -Condition (-not [string]::IsNullOrWhiteSpace($DirectoryPath)) -FailureCode 'INVALID_OUTPUT_DIRECTORY' -Detail 'empty'
    $resolvedPath = [System.IO.Path]::GetFullPath($DirectoryPath)
    $repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..')).TrimEnd('\')
    $operationsRoot = [System.IO.Path]::GetFullPath('C:\Users\JoanAB\Documents\BTC_15M_ARENA_OPERATIONS').TrimEnd('\')
    $trimmedOutput = $resolvedPath.TrimEnd('\')

    Assert-ScoringCondition -Condition ($trimmedOutput -cne $repositoryRoot) -FailureCode 'INVALID_OUTPUT_DIRECTORY' -Detail 'repository_root'
    Assert-ScoringCondition -Condition (-not ($trimmedOutput.StartsWith($operationsRoot + '\', [System.StringComparison]::OrdinalIgnoreCase) -or $trimmedOutput -ceq $operationsRoot)) -FailureCode 'INVALID_OUTPUT_DIRECTORY' -Detail 'operations_root'
    Assert-ScoringCondition -Condition (-not [System.IO.File]::Exists($resolvedPath)) -FailureCode 'INVALID_OUTPUT_DIRECTORY' -Detail 'path_is_file'

    if (-not [System.IO.Directory]::Exists($resolvedPath)) {
        New-Item -ItemType Directory -Path $resolvedPath | Out-Null
    }

    $children = @(Get-ChildItem -LiteralPath $resolvedPath -Force)
    if ($children.Count -gt 0) {
        if (-not $AllowOverwrite) {
            throw 'OUTPUT_DIRECTORY_NOT_EMPTY'
        }
        foreach ($child in $children) {
            Assert-ScoringCondition -Condition (-not $child.PSIsContainer) -FailureCode 'OUTPUT_DIRECTORY_CONTAINS_UNMANAGED_ENTRY' -Detail $child.Name
            Assert-ScoringCondition -Condition ($script:OutputFileNames -contains $child.Name) -FailureCode 'OUTPUT_DIRECTORY_CONTAINS_UNMANAGED_ENTRY' -Detail $child.Name
        }
    }

    return $resolvedPath
}

function Read-ScoringInputRecords {
    param([Parameter(Mandatory)][string]$Path)

    $resolvedInput = [System.IO.Path]::GetFullPath($Path)
    Assert-ScoringCondition -Condition ([System.IO.File]::Exists($resolvedInput)) -FailureCode 'INPUT_FILE_NOT_FOUND' -Detail $resolvedInput

    $records = [System.Collections.Generic.List[object]]::new()
    $lineNumber = 0
    foreach ($line in [System.IO.File]::ReadLines($resolvedInput)) {
        $lineNumber++
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $jsonDocument = $null
        try {
            $jsonDocument = [System.Text.Json.JsonDocument]::Parse($line)
            Assert-ScoringCondition -Condition ($jsonDocument.RootElement.ValueKind -eq [System.Text.Json.JsonValueKind]::Object) -FailureCode 'MALFORMED_JSON' -Detail ('line={0};root_not_object' -f $lineNumber)
            $orderedRecord = [ordered]@{}
            foreach ($propertyItem in $jsonDocument.RootElement.EnumerateObject()) {
                $propertyValue = switch ($propertyItem.Value.ValueKind) {
                    ([System.Text.Json.JsonValueKind]::String) { $propertyItem.Value.GetString(); break }
                    ([System.Text.Json.JsonValueKind]::Number) { $propertyItem.Value.GetRawText(); break }
                    ([System.Text.Json.JsonValueKind]::True) { $true; break }
                    ([System.Text.Json.JsonValueKind]::False) { $false; break }
                    ([System.Text.Json.JsonValueKind]::Null) { $null; break }
                    default { $propertyItem.Value.GetRawText(); break }
                }
                $orderedRecord[$propertyItem.Name] = $propertyValue
            }
            $record = [pscustomobject]$orderedRecord
        }
        catch {
            throw ('MALFORMED_JSON:line={0};message={1}' -f $lineNumber, $_.Exception.Message)
        }
        finally {
            if ($null -ne $jsonDocument) { $jsonDocument.Dispose() }
        }
        $records.Add([pscustomobject][ordered]@{
            line_number = $lineNumber
            record = $record
        })
    }
    return @($records)
}

function ConvertTo-ScoringValidatedRecord {
    param([Parameter(Mandatory)][object]$InputItem)

    $record = $InputItem.record
    $lineNumber = [int]$InputItem.line_number
    $requiredTextFields = @(
        'schema_version',
        'market_slug',
        'event_id',
        'market_id',
        'condition_id',
        'up_token_id',
        'down_token_id',
        'canonical_url'
    )

    $values = [ordered]@{}
    foreach ($fieldName in $requiredTextFields) {
        $fieldValue = Get-ScoringProperty -SourceObject $record -PropertyName $fieldName
        Assert-ScoringCondition -Condition (-not (Test-ScoringBlank -Value $fieldValue)) -FailureCode 'MISSING_IDENTITY_FIELD' -Detail ('line={0};field={1}' -f $lineNumber, $fieldName)
        $values[$fieldName] = ([string]$fieldValue).Trim()
    }

    Assert-ScoringCondition -Condition ($values['up_token_id'] -cne $values['down_token_id']) -FailureCode 'IDENTICAL_TOKEN_IDS' -Detail ('line={0}' -f $lineNumber)

    $windowStart = ConvertTo-ScoringUtcDate -Value (Get-ScoringProperty -SourceObject $record -PropertyName 'window_start_utc') -FieldName 'window_start_utc' -LineNumber $lineNumber
    $windowEnd = ConvertTo-ScoringUtcDate -Value (Get-ScoringProperty -SourceObject $record -PropertyName 'window_end_utc') -FieldName 'window_end_utc' -LineNumber $lineNumber
    Assert-ScoringCondition -Condition ($windowEnd -gt $windowStart) -FailureCode 'INVALID_WINDOW_ORDER' -Detail ('line={0}' -f $lineNumber)

    $prediction = [string](Get-ScoringProperty -SourceObject $record -PropertyName 'prediction')
    Assert-ScoringCondition -Condition (@('UP','DOWN','NO_TRADE') -ccontains $prediction) -FailureCode 'INVALID_PREDICTION' -Detail ('line={0};value={1}' -f $lineNumber, $prediction)

    $predictionTimestamp = ConvertTo-ScoringUtcDate -Value (Get-ScoringProperty -SourceObject $record -PropertyName 'prediction_timestamp_utc') -FieldName 'prediction_timestamp_utc' -LineNumber $lineNumber
    Assert-ScoringCondition -Condition ($predictionTimestamp -ge $windowStart) -FailureCode 'PREDICTION_BEFORE_WINDOW_START' -Detail ('line={0}' -f $lineNumber)

    $noTradeReason = Get-ScoringProperty -SourceObject $record -PropertyName 'primary_no_trade_reason'
    if ($prediction -ceq 'NO_TRADE') {
        Assert-ScoringCondition -Condition (-not (Test-ScoringBlank -Value $noTradeReason)) -FailureCode 'MISSING_NO_TRADE_REASON' -Detail ('line={0}' -f $lineNumber)
        $noTradeReason = ([string]$noTradeReason).Trim()
    }
    else {
        Assert-ScoringCondition -Condition (Test-ScoringBlank -Value $noTradeReason) -FailureCode 'UNEXPECTED_NO_TRADE_REASON' -Detail ('line={0}' -f $lineNumber)
        $noTradeReason = $null
    }

    $officialOutcome = [string](Get-ScoringProperty -SourceObject $record -PropertyName 'official_outcome')
    Assert-ScoringCondition -Condition (@('UP','DOWN','PENDING') -ccontains $officialOutcome) -FailureCode 'INVALID_OFFICIAL_OUTCOME' -Detail ('line={0};value={1}' -f $lineNumber, $officialOutcome)

    $officialOutcomeSource = Get-ScoringProperty -SourceObject $record -PropertyName 'official_outcome_source'
    if ($officialOutcome -in @('UP','DOWN')) {
        Assert-ScoringCondition -Condition (-not (Test-ScoringBlank -Value $officialOutcomeSource)) -FailureCode 'MISSING_OFFICIAL_OUTCOME_SOURCE' -Detail ('line={0}' -f $lineNumber)
        $officialOutcomeSource = ([string]$officialOutcomeSource).Trim()
        $resolutionTimestamp = ConvertTo-ScoringUtcDate -Value (Get-ScoringProperty -SourceObject $record -PropertyName 'official_resolution_timestamp_utc') -FieldName 'official_resolution_timestamp_utc' -LineNumber $lineNumber
        Assert-ScoringCondition -Condition ($resolutionTimestamp -ge $windowEnd) -FailureCode 'OFFICIAL_RESOLUTION_BEFORE_WINDOW_END' -Detail ('line={0}' -f $lineNumber)
    }
    else {
        $resolutionRaw = Get-ScoringProperty -SourceObject $record -PropertyName 'official_resolution_timestamp_utc'
        Assert-ScoringCondition -Condition (Test-ScoringBlank -Value $resolutionRaw) -FailureCode 'UNEXPECTED_PENDING_RESOLUTION_TIMESTAMP' -Detail ('line={0}' -f $lineNumber)
        $resolutionTimestamp = $null
        $officialOutcomeSource = if (Test-ScoringBlank -Value $officialOutcomeSource) { $null } else { ([string]$officialOutcomeSource).Trim() }
    }

    return [pscustomobject][ordered]@{
        line_number = $lineNumber
        schema_version = $values['schema_version']
        market_slug = $values['market_slug']
        event_id = $values['event_id']
        market_id = $values['market_id']
        condition_id = $values['condition_id']
        up_token_id = $values['up_token_id']
        down_token_id = $values['down_token_id']
        canonical_url = $values['canonical_url']
        window_start_utc = $windowStart
        window_end_utc = $windowEnd
        prediction = $prediction
        prediction_timestamp_utc = $predictionTimestamp
        primary_no_trade_reason = $noTradeReason
        official_outcome = $officialOutcome
        official_outcome_source = $officialOutcomeSource
        official_resolution_timestamp_utc = $resolutionTimestamp
        reconstructed_start_price = Get-ScoringProperty -SourceObject $record -PropertyName 'reconstructed_start_price'
        reconstructed_final_price = Get-ScoringProperty -SourceObject $record -PropertyName 'reconstructed_final_price'
        reconstructed_source = Get-ScoringProperty -SourceObject $record -PropertyName 'reconstructed_source'
        canonical_identity_key = (@($values['market_slug'], $values['event_id'], $values['market_id'], $values['condition_id']) -join '|')
    }
}

function ConvertTo-ScoringScoredRecord {
    param([Parameter(Mandatory)][object]$Record)

    $startDiagnostic = ConvertTo-ScoringDecimal -Value $Record.reconstructed_start_price -FieldName 'reconstructed_start_price' -LineNumber $Record.line_number
    $finalDiagnostic = ConvertTo-ScoringDecimal -Value $Record.reconstructed_final_price -FieldName 'reconstructed_final_price' -LineNumber $Record.line_number
    $hasStart = -not (Test-ScoringBlank -Value $Record.reconstructed_start_price)
    $hasFinal = -not (Test-ScoringBlank -Value $Record.reconstructed_final_price)
    $reconstructedOutcome = $null
    if ($null -ne $startDiagnostic -and $null -ne $finalDiagnostic) {
        $reconstructedOutcome = if ($finalDiagnostic -ge $startDiagnostic) { 'UP' } else { 'DOWN' }
    }

    if ($null -eq $reconstructedOutcome) {
        $reconstructionStatus = if ($hasStart -or $hasFinal) { 'NOT_COMPARABLE' } else { 'NOT_AVAILABLE' }
    }
    elseif ($Record.official_outcome -ceq 'PENDING') {
        $reconstructionStatus = 'NOT_COMPARABLE'
    }
    elseif ($reconstructedOutcome -ceq $Record.official_outcome) {
        $reconstructionStatus = 'MATCH'
    }
    else {
        $reconstructionStatus = 'MISMATCH'
    }

    $predictionStatus = $null
    $predictionCorrect = $null
    if ($Record.official_outcome -ceq 'PENDING') {
        $predictionStatus = 'PENDING_RESOLUTION'
    }
    elseif ($Record.prediction_timestamp_utc -gt $Record.window_end_utc) {
        $predictionStatus = 'LATE_INVALID'
    }
    elseif ($Record.prediction -ceq 'NO_TRADE') {
        $predictionStatus = 'ABSTAINED'
    }
    else {
        $predictionStatus = 'VALID'
        $predictionCorrect = ($Record.prediction -ceq $Record.official_outcome)
    }

    return [pscustomobject][ordered]@{
        schema_version = $Record.schema_version
        market_slug = $Record.market_slug
        event_id = $Record.event_id
        market_id = $Record.market_id
        condition_id = $Record.condition_id
        up_token_id = $Record.up_token_id
        down_token_id = $Record.down_token_id
        canonical_url = $Record.canonical_url
        window_start_utc = Format-ScoringUtc -Value $Record.window_start_utc
        window_end_utc = Format-ScoringUtc -Value $Record.window_end_utc
        prediction = $Record.prediction
        prediction_timestamp_utc = Format-ScoringUtc -Value $Record.prediction_timestamp_utc
        primary_no_trade_reason = $Record.primary_no_trade_reason
        official_outcome = $Record.official_outcome
        official_outcome_source = $Record.official_outcome_source
        official_resolution_timestamp_utc = if ($null -eq $Record.official_resolution_timestamp_utc) { $null } else { Format-ScoringUtc -Value $Record.official_resolution_timestamp_utc }
        official_outcome_authority = 'POLYMARKET_FINAL_RESOLVED_OUTCOME'
        tie_policy = 'UP'
        reconstructed_start_price = if ($null -eq $startDiagnostic) { $null } else { $startDiagnostic }
        reconstructed_final_price = if ($null -eq $finalDiagnostic) { $null } else { $finalDiagnostic }
        reconstructed_source = if (Test-ScoringBlank -Value $Record.reconstructed_source) { $null } else { ([string]$Record.reconstructed_source).Trim() }
        reconstructed_chainlink_outcome = $reconstructedOutcome
        reconstruction_status = $reconstructionStatus
        prediction_status = $predictionStatus
        prediction_correct = $predictionCorrect
    }
}

function ConvertTo-ScoringRatio {
    param(
        [Parameter(Mandatory)][int]$Numerator,
        [Parameter(Mandatory)][int]$Denominator
    )

    if ($Denominator -eq 0) { return $null }
    return [decimal]$Numerator / [decimal]$Denominator
}

function New-ScoringSummary {
    param(
        [Parameter(Mandatory)][object[]]$ScoredRecords,
        [Parameter(Mandatory)][int]$InputRecordCount
    )

    $eligibleResolved = @($ScoredRecords | Where-Object { $_.official_outcome -in @('UP','DOWN') })
    $pendingRecords = @($ScoredRecords | Where-Object { $_.official_outcome -ceq 'PENDING' })
    $validRecords = @($ScoredRecords | Where-Object { $_.prediction_status -ceq 'VALID' })
    $abstainedRecords = @($ScoredRecords | Where-Object { $_.prediction_status -ceq 'ABSTAINED' })
    $lateRecords = @($ScoredRecords | Where-Object { $_.prediction_status -ceq 'LATE_INVALID' })
    $correctRecords = @($validRecords | Where-Object { $_.prediction_correct -eq $true })
    $incorrectRecords = @($validRecords | Where-Object { $_.prediction_correct -eq $false })

    $actualUpPredictedUp = @($validRecords | Where-Object { $_.official_outcome -ceq 'UP' -and $_.prediction -ceq 'UP' }).Count
    $actualUpPredictedDown = @($validRecords | Where-Object { $_.official_outcome -ceq 'UP' -and $_.prediction -ceq 'DOWN' }).Count
    $actualDownPredictedUp = @($validRecords | Where-Object { $_.official_outcome -ceq 'DOWN' -and $_.prediction -ceq 'UP' }).Count
    $actualDownPredictedDown = @($validRecords | Where-Object { $_.official_outcome -ceq 'DOWN' -and $_.prediction -ceq 'DOWN' }).Count

    $upRecall = ConvertTo-ScoringRatio -Numerator $actualUpPredictedUp -Denominator ($actualUpPredictedUp + $actualUpPredictedDown)
    $downRecall = ConvertTo-ScoringRatio -Numerator $actualDownPredictedDown -Denominator ($actualDownPredictedDown + $actualDownPredictedUp)
    $balancedAccuracy = if ($null -eq $upRecall -or $null -eq $downRecall) { $null } else { ([decimal]$upRecall + [decimal]$downRecall) / [decimal]2 }

    return [pscustomobject][ordered]@{
        schema_version = 'BTC15M_OFFICIAL_OUTCOME_DIRECTIONAL_SCORING_SUMMARY_V1'
        input_record_count = $InputRecordCount
        eligible_resolved_market_count = $eligibleResolved.Count
        pending_resolution_count = $pendingRecords.Count
        valid_prediction_count = $validRecords.Count
        abstention_count = $abstainedRecords.Count
        late_invalid_count = $lateRecords.Count
        data_invalid_count = 0
        correct_prediction_count = $correctRecords.Count
        incorrect_prediction_count = $incorrectRecords.Count
        coverage = ConvertTo-ScoringRatio -Numerator $validRecords.Count -Denominator $eligibleResolved.Count
        coverage_status = if ($eligibleResolved.Count -eq 0) { 'ZERO_ELIGIBLE_RESOLVED_MARKETS' } else { 'AVAILABLE' }
        directional_accuracy = ConvertTo-ScoringRatio -Numerator $correctRecords.Count -Denominator $validRecords.Count
        directional_accuracy_status = if ($validRecords.Count -eq 0) { 'ZERO_VALID_PREDICTIONS' } else { 'AVAILABLE' }
        balanced_accuracy = $balancedAccuracy
        balanced_accuracy_status = if ($null -eq $balancedAccuracy) { 'ZERO_SUPPORT_FOR_AT_LEAST_ONE_ACTUAL_CLASS' } else { 'AVAILABLE' }
        UP_precision = ConvertTo-ScoringRatio -Numerator $actualUpPredictedUp -Denominator ($actualUpPredictedUp + $actualDownPredictedUp)
        UP_precision_status = if (($actualUpPredictedUp + $actualDownPredictedUp) -eq 0) { 'ZERO_PREDICTED_UP' } else { 'AVAILABLE' }
        UP_recall = $upRecall
        UP_recall_status = if (($actualUpPredictedUp + $actualUpPredictedDown) -eq 0) { 'ZERO_ACTUAL_UP_SUPPORT' } else { 'AVAILABLE' }
        DOWN_precision = ConvertTo-ScoringRatio -Numerator $actualDownPredictedDown -Denominator ($actualDownPredictedDown + $actualUpPredictedDown)
        DOWN_precision_status = if (($actualDownPredictedDown + $actualUpPredictedDown) -eq 0) { 'ZERO_PREDICTED_DOWN' } else { 'AVAILABLE' }
        DOWN_recall = $downRecall
        DOWN_recall_status = if (($actualDownPredictedDown + $actualDownPredictedUp) -eq 0) { 'ZERO_ACTUAL_DOWN_SUPPORT' } else { 'AVAILABLE' }
        actual_UP_predicted_UP = $actualUpPredictedUp
        actual_UP_predicted_DOWN = $actualUpPredictedDown
        actual_DOWN_predicted_UP = $actualDownPredictedUp
        actual_DOWN_predicted_DOWN = $actualDownPredictedDown
    }
}

function Invoke-OfficialOutcomeDirectionalScoring {
    param(
        [Parameter(Mandatory)][string]$InputPathValue,
        [Parameter(Mandatory)][string]$OutputDirectoryValue,
        [Parameter(Mandatory)][bool]$AllowOverwrite
    )

    $resolvedOutputDirectory = Resolve-ScoringOutputDirectory -DirectoryPath $OutputDirectoryValue -AllowOverwrite $AllowOverwrite
    $inputItems = Read-ScoringInputRecords -Path $InputPathValue
    $validatedRecords = [System.Collections.Generic.List[object]]::new()
    foreach ($inputItem in $inputItems) {
        $validatedRecords.Add((ConvertTo-ScoringValidatedRecord -InputItem $inputItem))
    }

    $seenIdentities = @{}
    foreach ($validatedRecord in @($validatedRecords | Sort-Object canonical_identity_key, line_number)) {
        if ($seenIdentities.ContainsKey($validatedRecord.canonical_identity_key)) {
            throw ('DUPLICATE_MARKET_IDENTITY:key={0};first_line={1};duplicate_line={2}' -f $validatedRecord.canonical_identity_key, $seenIdentities[$validatedRecord.canonical_identity_key], $validatedRecord.line_number)
        }
        $seenIdentities[$validatedRecord.canonical_identity_key] = $validatedRecord.line_number
    }

    $scoredRecords = @(
        $validatedRecords |
            Sort-Object @{ Expression = { Format-ScoringUtc -Value $_.window_start_utc } }, market_slug, event_id, market_id, condition_id |
            ForEach-Object { ConvertTo-ScoringScoredRecord -Record $_ }
    )
    $summary = New-ScoringSummary -ScoredRecords $scoredRecords -InputRecordCount $inputItems.Count

    $scoredContent = if ($scoredRecords.Count -eq 0) {
        ''
    }
    else {
        ((@($scoredRecords | ForEach-Object { ConvertTo-ScoringJsonLine -Value $_ }) -join "`n") + "`n")
    }
    $summaryContent = (ConvertTo-ScoringStableJson -Value $summary) + "`n"
    $confusionRows = @(
        [pscustomobject][ordered]@{ actual_outcome = 'UP'; predicted_UP = $summary.actual_UP_predicted_UP; predicted_DOWN = $summary.actual_UP_predicted_DOWN },
        [pscustomobject][ordered]@{ actual_outcome = 'DOWN'; predicted_UP = $summary.actual_DOWN_predicted_UP; predicted_DOWN = $summary.actual_DOWN_predicted_DOWN }
    )
    $confusionContent = ConvertTo-ScoringCsv -Rows $confusionRows -Columns @('actual_outcome','predicted_UP','predicted_DOWN')

    $scoredPath = Join-Path $resolvedOutputDirectory 'scored_markets.jsonl'
    $summaryPath = Join-Path $resolvedOutputDirectory 'directional_summary.json'
    $confusionPath = Join-Path $resolvedOutputDirectory 'confusion_matrix.csv'
    $manifestPath = Join-Path $resolvedOutputDirectory 'manifest.csv'

    Set-ScoringFile -Path $scoredPath -Content $scoredContent
    Set-ScoringFile -Path $summaryPath -Content $summaryContent
    Set-ScoringFile -Path $confusionPath -Content $confusionContent

    $manifestRows = foreach ($fileName in $script:ManifestMemberNames) {
        $filePath = Join-Path $resolvedOutputDirectory $fileName
        [pscustomobject][ordered]@{
            relative_path = $fileName
            bytes = ([System.IO.FileInfo]::new($filePath)).Length
            sha256 = Get-ScoringFileSha256Lower -Path $filePath
            line_count = Get-ScoringLineCount -Path $filePath
        }
    }
    $manifestContent = ConvertTo-ScoringCsv -Rows @($manifestRows) -Columns @('relative_path','bytes','sha256','line_count')
    Set-ScoringFile -Path $manifestPath -Content $manifestContent

    return [pscustomobject][ordered]@{
        result = 'PASS'
        input_record_count = $inputItems.Count
        output_directory = $resolvedOutputDirectory
        output_file_set = $script:OutputFileNames
    }
}

try {
    $resultObject = Invoke-OfficialOutcomeDirectionalScoring -InputPathValue $InputPath -OutputDirectoryValue $OutputDirectory -AllowOverwrite ([bool]$Overwrite)
    $resultObject | ConvertTo-Json -Depth 20
    exit 0
}
catch {
    $failureObject = [pscustomobject][ordered]@{
        result = 'NO_PASS'
        error = $_.Exception.Message
    }
    $failureObject | ConvertTo-Json -Depth 10
    exit 1
}
