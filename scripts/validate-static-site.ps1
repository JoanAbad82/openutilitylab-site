[CmdletBinding()]
param()

Set-StrictMode -Version Latest

$script:Failures = New-Object System.Collections.Generic.List[string]

function Add-Failure {
    param(
        [Parameter(Mandatory = $true)][string]$Section,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $entry = "[$Section] $Message"
    $script:Failures.Add($entry)
    Write-Host "[FAIL] $entry"
}

function Require-File {
    param(
        [Parameter(Mandatory = $true)][string]$Section,
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$RepoRoot
    )

    $fullPath = Join-Path -Path $RepoRoot -ChildPath $RelativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        Add-Failure -Section $Section -Message "Missing required file: $RelativePath"
        return $false
    }

    return $true
}

function Require-Marker {
    param(
        [Parameter(Mandatory = $true)][string]$Section,
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$Marker
    )

    if (-not $Content.Contains($Marker)) {
        Add-Failure -Section $Section -Message "Missing marker '$Marker' in $RelativePath"
    }
}

function Reject-Marker {
    param(
        [Parameter(Mandatory = $true)][string]$Section,
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$Marker
    )

    if ($Content.IndexOf($Marker, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Add-Failure -Section $Section -Message "Rejected marker '$Marker' found in $RelativePath"
    }
}

function Get-FileContent {
    param(
        [Parameter(Mandatory = $true)][string]$Section,
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$RepoRoot
    )

    $fullPath = Join-Path -Path $RepoRoot -ChildPath $RelativePath
    try {
        return Get-Content -LiteralPath $fullPath -Raw -Encoding UTF8
    }
    catch {
        Add-Failure -Section $Section -Message "Unable to read ${RelativePath}: $($_.Exception.Message)"
        return $null
    }
}

function Complete-Section {
    param(
        [Parameter(Mandatory = $true)][string]$Section,
        [Parameter(Mandatory = $true)][int]$StartFailureCount
    )

    if ($script:Failures.Count -eq $StartFailureCount) {
        Write-Host "[PASS] $Section"
    }
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath "..")).Path
$requiredFiles = @(
    "index.html",
    "ai-assisted-work/index.html",
    "affiliate-friction-auditor/index.html",
    "affiliate-friction-auditor/affiliate-review-audit-example/index.html",
    "spectralcode/index.html",
    "styles.css",
    "robots.txt",
    "sitemap.xml"
)

$fileContent = @{}

$section = "Repository/root checks"
$sectionStart = $script:Failures.Count
foreach ($relativePath in $requiredFiles) {
    if (Require-File -Section $section -RelativePath $relativePath -RepoRoot $repoRoot) {
        $content = Get-FileContent -Section $section -RelativePath $relativePath -RepoRoot $repoRoot
        if ($null -ne $content) {
            $fileContent[$relativePath] = $content
        }
    }
}
Complete-Section -Section $section -StartFailureCount $sectionStart

$section = "robots.txt checks"
$sectionStart = $script:Failures.Count
if ($fileContent.ContainsKey("robots.txt")) {
    $robotsLines = @(Get-Content -LiteralPath (Join-Path $repoRoot "robots.txt") -Encoding UTF8)
    $expectedRobotsLines = @(
        "User-agent: *",
        "Allow: /",
        "Sitemap: https://openutilitylab.com/sitemap.xml"
    )

    if ($robotsLines.Count -ne $expectedRobotsLines.Count) {
        Add-Failure -Section $section -Message "robots.txt must contain exactly 3 lines"
    }
    else {
        for ($i = 0; $i -lt $expectedRobotsLines.Count; $i++) {
            if ($robotsLines[$i] -ne $expectedRobotsLines[$i]) {
                Add-Failure -Section $section -Message "robots.txt line $($i + 1) mismatch"
            }
        }
    }

    $sitemapLineCount = @($robotsLines | Where-Object { $_ -match '^Sitemap:\s*' }).Count
    if ($sitemapLineCount -ne 1) {
        Add-Failure -Section $section -Message "robots.txt must contain exactly one Sitemap line"
    }
}
else {
    Add-Failure -Section $section -Message "robots.txt not loaded"
}
Complete-Section -Section $section -StartFailureCount $sectionStart

$section = "sitemap.xml checks"
$sectionStart = $script:Failures.Count
if ($fileContent.ContainsKey("sitemap.xml")) {
    $sitemapRaw = $fileContent["sitemap.xml"]
    $sitemapXml = $null
    try {
        $sitemapXml = [xml]$sitemapRaw
    }
    catch {
        Add-Failure -Section $section -Message "sitemap.xml failed XML parsing: $($_.Exception.Message)"
    }

    if ($null -ne $sitemapXml) {
        $expectedNamespace = "http://www.sitemaps.org/schemas/sitemap/0.9"
        $actualNamespace = $sitemapXml.DocumentElement.NamespaceURI
        if ($actualNamespace -ne $expectedNamespace) {
            Add-Failure -Section $section -Message "Unexpected sitemap namespace: '$actualNamespace'"
        }

        $ns = New-Object System.Xml.XmlNamespaceManager($sitemapXml.NameTable)
        $ns.AddNamespace("sm", $expectedNamespace)

        $locNodes = $sitemapXml.SelectNodes('/sm:urlset/sm:url/sm:loc', $ns)
        $locs = @()
        foreach ($node in $locNodes) {
            $locs += $node.InnerText.Trim()
        }

        $expectedLocs = @(
            "https://openutilitylab.com/",
            "https://openutilitylab.com/ai-assisted-work/",
            "https://openutilitylab.com/affiliate-friction-auditor/",
            "https://openutilitylab.com/affiliate-friction-auditor/affiliate-review-audit-example/",
            "https://openutilitylab.com/spectralcode/"
        )

        if ($locs.Count -ne 6) {
            Add-Failure -Section $section -Message "Expected exactly 6 <loc> entries, found $($locs.Count)"
        }

        $uniqueLocCount = (@($locs | Sort-Object -Unique)).Count
        if ($uniqueLocCount -ne $locs.Count) {
            Add-Failure -Section $section -Message "Duplicate <loc> entries found in sitemap.xml"
        }

        foreach ($expectedLoc in $expectedLocs) {
            if (-not $locs.Contains($expectedLoc)) {
                Add-Failure -Section $section -Message "Missing expected <loc>: $expectedLoc"
            }
        }

        foreach ($loc in $locs) {
            if ($loc.Contains("?") -or $loc.Contains("#")) {
                Add-Failure -Section $section -Message "<loc> contains query/hash fragment: $loc"
            }
        }

        $bannedLocSnippets = @(
            "pages.dev",
            "localhost",
            "127.0.0.1",
            "github.com",
            "mtgsynergy.com",
            "spectral-code.org",
            "realitygap.openutilitylab.com"
        )

        foreach ($loc in $locs) {
            foreach ($snippet in $bannedLocSnippets) {
                if ($loc.IndexOf($snippet, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                    Add-Failure -Section $section -Message "Forbidden hostname/snippet '$snippet' in <loc>: $loc"
                }
            }
        }

        $lastmodNodes = $sitemapXml.SelectNodes('//sm:lastmod', $ns)
        if ($lastmodNodes.Count -ne 6) {
            Add-Failure -Section $section -Message "Expected exactly six <lastmod> entries, found $($lastmodNodes.Count)"
        }

        $allowedLastmodValues = @("2026-05-19", "2026-05-31")
        foreach ($node in $lastmodNodes) {
            $lastmodValue = $node.InnerText.Trim()
            if (-not $allowedLastmodValues.Contains($lastmodValue)) {
                Add-Failure -Section $section -Message "Unexpected <lastmod> value '$lastmodValue'"
            }
        }
    }
}
else {
    Add-Failure -Section $section -Message "sitemap.xml not loaded"
}
Complete-Section -Section $section -StartFailureCount $sectionStart

$section = "HTML route marker checks"
$sectionStart = $script:Failures.Count

$htmlMarkers = @{
    "index.html" = @(
        "Open Utility Lab",
        "AI-Assisted Product Builder",
        "View AI-assisted work profile",
        "Affiliate Friction Auditor",
        "RealityGap",
        "MTGSynergy",
        "SpectralCode"
    )
    "ai-assisted-work/index.html" = @(
        "AI-Assisted Product Builder",
        "AI Workflow Director",
        "recruiter-readable profile",
        "Target roles",
        "How I work with AI",
        "RealityGap",
        "MTGSynergy",
        "Affiliate Friction Auditor",
        "SpectralCode"
    )
    "affiliate-friction-auditor/index.html" = @(
        "Affiliate Friction Auditor",
        "Paste HTML",
        "Download"
    )
    "spectralcode/index.html" = @(
        "SpectralCode"
    )
}

foreach ($path in $htmlMarkers.Keys) {
    if ($fileContent.ContainsKey($path)) {
        foreach ($marker in $htmlMarkers[$path]) {
            Require-Marker -Section $section -RelativePath $path -Content $fileContent[$path] -Marker $marker
        }
    }
    else {
        Add-Failure -Section $section -Message "$path not loaded"
    }
}

$affiliatePath = "affiliate-friction-auditor/index.html"
$expectedAffiliateDescription = "Affiliate Friction Auditor is a private, browser-based tool for spotting affiliate links, commercial pressure, CTA patterns, and tracking signals in pasted HTML."
if ($fileContent.ContainsKey($affiliatePath)) {
    $affiliateHtml = $fileContent[$affiliatePath]
    $headMatch = [regex]::Match($affiliateHtml, '(?is)<head\b[^>]*>(.*?)</head>')
    if (-not $headMatch.Success) {
        Add-Failure -Section $section -Message "Could not locate real <head> in $affiliatePath"
    }
    else {
        $headContent = $headMatch.Groups[1].Value
        $descriptionMetaMatches = [regex]::Matches($headContent, '(?is)<meta\b[^>]*\bname\s*=\s*("description"|''description'')[^>]*>')

        if ($descriptionMetaMatches.Count -ne 1) {
            Add-Failure -Section $section -Message "Expected exactly one <meta name=\"description\"> in real <head>, found $($descriptionMetaMatches.Count)"
        }
        else {
            $metaTag = $descriptionMetaMatches[0].Value
            $contentMatch = [regex]::Match($metaTag, '(?is)\bcontent\s*=\s*("([^"]*)"|''([^'']*)'')')
            if (-not $contentMatch.Success) {
                Add-Failure -Section $section -Message "Description meta tag in real <head> is missing content attribute"
            }
            else {
                $contentValue = if ($contentMatch.Groups[2].Success) { $contentMatch.Groups[2].Value } else { $contentMatch.Groups[3].Value }
                if ($contentValue -ne $expectedAffiliateDescription) {
                    Add-Failure -Section $section -Message "affiliate-friction-auditor meta description mismatch"
                }
            }
        }
    }
}
Complete-Section -Section $section -StartFailureCount $sectionStart

$section = "Affiliate Friction Auditor trust checks"
$sectionStart = $script:Failures.Count
$affiliatePath = "affiliate-friction-auditor/index.html"
$affiliateExamplePath = "affiliate-friction-auditor/affiliate-review-audit-example/index.html"
if ($fileContent.ContainsKey($affiliatePath)) {
    $affiliateHtml = $fileContent[$affiliatePath]
    $affiliateMarkers = @(
        '<link rel="canonical" href="https://openutilitylab.com/affiliate-friction-auditor/">',
        "No data leaves your browser",
        "No backend",
        "See the affiliate review audit example",
        "Fastest first run:",
        "First-Pass Local HTML Report",
        "Manual Review Backlog",
        "Use this to understand which observable HTML signal groups influenced the indicative score."
    )

    foreach ($marker in $affiliateMarkers) {
        Require-Marker -Section $section -RelativePath $affiliatePath -Content $affiliateHtml -Marker $marker
    }
}
else {
    Add-Failure -Section $section -Message "$affiliatePath not loaded"
}

if ($fileContent.ContainsKey($affiliateExamplePath)) {
    $affiliateExampleHtml = $fileContent[$affiliateExamplePath]
    $affiliateExampleMarkers = @(
        '<link rel="canonical" href="https://openutilitylab.com/affiliate-friction-auditor/affiliate-review-audit-example/">',
        "How to read this sample:",
        "guided reading order",
        "load the demo HTML, analyze locally, inspect the top priorities"
    )

    foreach ($marker in $affiliateExampleMarkers) {
        Require-Marker -Section $section -RelativePath $affiliateExamplePath -Content $affiliateExampleHtml -Marker $marker
    }
}
else {
    Add-Failure -Section $section -Message "$affiliateExamplePath not loaded"
}
Complete-Section -Section $section -StartFailureCount $sectionStart

$section = "CSS marker checks"
$sectionStart = $script:Failures.Count
if ($fileContent.ContainsKey("styles.css")) {
    $cssMarkers = @(
        "OPENUTILITYLAB_MOBILE_PORTFOLIO_HERO_OVERFLOW_REPAIR_V1",
        "mobile-root-horizontal-panning-lock",
        "box-sizing: border-box;",
        "wide-professional-layout",
        "portfolio-wide-shell",
        "canonical-portfolio-layout",
        "portfolio-hero",
        "profile-snapshot"
    )

    foreach ($marker in $cssMarkers) {
        Require-Marker -Section $section -RelativePath "styles.css" -Content $fileContent["styles.css"] -Marker $marker
    }
}
else {
    Add-Failure -Section $section -Message "styles.css not loaded"
}
Complete-Section -Section $section -StartFailureCount $sectionStart

$section = "Broken-output / corruption guardrails"
$sectionStart = $script:Failures.Count
$guardrailFiles = @(
    "index.html",
    "ai-assisted-work/index.html",
    "affiliate-friction-auditor/index.html",
    "affiliate-friction-auditor/affiliate-review-audit-example/index.html",
    "spectralcode/index.html",
    "styles.css",
    "robots.txt",
    "sitemap.xml"
)

$brokenMarkers = @(
    "404 Not Found",
    "Page not found",
    "Application error",
    "Internal Server Error",
    "Cannot GET",
    "This site can’t be reached",
    "C:\\Users\\JoanAB"
)

foreach ($path in $guardrailFiles) {
    if (-not $fileContent.ContainsKey($path)) {
        Add-Failure -Section $section -Message "$path not loaded"
        continue
    }

    $content = $fileContent[$path]
    foreach ($marker in $brokenMarkers) {
        Reject-Marker -Section $section -RelativePath $path -Content $content -Marker $marker
    }
}
Complete-Section -Section $section -StartFailureCount $sectionStart

$section = "Overclaim guardrails"
$sectionStart = $script:Failures.Count
$overclaimMarkers = @(
    "senior software engineer",
    "Senior Software Engineer",
    "staff engineer",
    "Staff Engineer",
    "lead engineer",
    "Lead Engineer",
    "10 years",
    "decade of professional software engineering",
    "generated revenue",
    "venture-backed",
    "managed a team",
    "enterprise clients"
)

foreach ($path in $guardrailFiles) {
    if (-not $fileContent.ContainsKey($path)) {
        Add-Failure -Section $section -Message "$path not loaded"
        continue
    }

    $content = $fileContent[$path]
    foreach ($marker in $overclaimMarkers) {
        Reject-Marker -Section $section -RelativePath $path -Content $content -Marker $marker
    }
}
Complete-Section -Section $section -StartFailureCount $sectionStart

$section = "Git safety checks"
$sectionStart = $script:Failures.Count
try {
    $statusLines = @(git status --porcelain 2>$null)
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[WARN] Unable to read git status (non-fatal)."
    }
    else {
        if ($statusLines.Count -gt 0) {
            $nonScriptChanges = @($statusLines | Where-Object { $_ -notmatch 'scripts[\\/]validate-static-site\.ps1$' })
            if ($nonScriptChanges.Count -gt 0) {
                Write-Host "[WARN] Working tree is dirty ($($statusLines.Count) change(s))."
            }
            else {
                Write-Host "[WARN] Working tree has only scripts/validate-static-site.ps1 changes during harness development."
            }
        }
    }
}
catch {
    Write-Host "[WARN] Git status unavailable: $($_.Exception.Message)"
}
Complete-Section -Section $section -StartFailureCount $sectionStart

Write-Host ""
Write-Host "Validation summary: $($script:Failures.Count) failure(s)."

if ($script:Failures.Count -gt 0) {
    Write-Host "OPENUTILITYLAB_STATIC_SITE_VALIDATION_HARNESS_V1_FAIL"
    exit 1
}

Write-Host "OPENUTILITYLAB_STATIC_SITE_VALIDATION_HARNESS_V1_PASS"
exit 0

