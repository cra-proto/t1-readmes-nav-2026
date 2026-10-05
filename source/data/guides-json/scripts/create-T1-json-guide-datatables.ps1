<#
create-T1-json-guide-datatables.ps1

Generate guide JSON table data from:
1) the guide template JSON
2) a guide-to-province metadata file

The script does not self-seed from table-data.
It validates bilingual link pairs after generation.
#>

[CmdletBinding()]
param(
  [string]$PubsListPath = ".\recent-T1-pubs-9yrs.txt",
  [string]$TemplatePath = ".\t1-guide-template-table-data.json",
  [string]$GuideMetadataPath = ".\guide-province-map.json",
  [string]$OutputDir,
  [int]$TimeoutSec = 12,
  [int]$RequestDelayMs = 0,
  [int]$RetryCount = 2,
  [int]$RetryDelayMs = 500,
  [int]$MaxRedirects = 8,
  [switch]$GenerateOnly,
  [switch]$PauseBeforeLinkCheck,
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$defaultGuideOutputDir = 'C:\my-working-files\GitHub\t1-readmes-nav-2026\source\data\guides-json\table-data'
$defaultOutputEncoding = [System.Text.UTF8Encoding]::new($false)
$EN_NA = @('Not available')
$FR_NA = @('Sans objet')

function Assert-NoMojibakeText {
  param(
    [Parameter(Mandatory)] [string]$Text,
    [Parameter(Mandatory)] [string]$Context
  )

  $containsReplacementChar = $Text.IndexOf([string][char]0xFFFD, [System.StringComparison]::Ordinal) -ge 0
  $containsUtf8MojibakeLead = ($Text.IndexOf([char]0x00C3) -ge 0) -or ($Text.IndexOf([char]0x00C2) -ge 0)

  if ($containsReplacementChar -or $containsUtf8MojibakeLead) {
    throw "Detected mojibake in $Context. Save the source JSON/script files as UTF-8 before generating outputs."
  }
}

function Resolve-ExistingPath {
  param(
    [Parameter(Mandatory)] [string]$PathValue,
    [Parameter(Mandatory)] [string]$BaseDir
  )

  if ([System.IO.Path]::IsPathRooted($PathValue)) {
    if (-not (Test-Path -LiteralPath $PathValue)) {
      throw "Required file not found: $PathValue"
    }
    return (Resolve-Path -LiteralPath $PathValue).Path
  }

  $scriptRelative = Join-Path $BaseDir $PathValue
  if (Test-Path -LiteralPath $scriptRelative) {
    return (Resolve-Path -LiteralPath $scriptRelative).Path
  }

  if (Test-Path -LiteralPath $PathValue) {
    return (Resolve-Path -LiteralPath $PathValue).Path
  }

  throw "Required file not found: $PathValue"
}

function Resolve-DirectoryPath {
  param(
    [Parameter(Mandatory)] [string]$PathValue,
    [Parameter(Mandatory)] [string]$BaseDir
  )

  if ([System.IO.Path]::IsPathRooted($PathValue)) {
    return $PathValue
  }

  return (Join-Path $BaseDir $PathValue)
}

function Get-PubsList {
  param(
    [Parameter(Mandatory)] [string]$Path,
    [switch]$SkipComments
  )

  $pubs = Get-Content -LiteralPath $Path |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -and $_ -ne '' }

  if ($SkipComments) {
    $pubs = $pubs | Where-Object { -not $_.StartsWith('#') }
  }

  return $pubs
}

function Read-TextFilePreserveEncoding {
  param([Parameter(Mandatory)] [string]$Path)

  function Get-TrailingNewlines([string]$s) {
    $m = [regex]::Match($s, '((?:\r\n|\n|\r)+)$')
    if ($m.Success) { return $m.Groups[1].Value }
    return ''
  }

  $bytes = [System.IO.File]::ReadAllBytes($Path)
  if ($bytes.Length -eq 0) {
    return [pscustomobject]@{
      Text             = ''
      Encoding         = [System.Text.UTF8Encoding]::new($false)
      TrailingNewlines = ''
    }
  }

  if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    $text = [System.Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3)
    return [pscustomobject]@{
      Text             = $text
      Encoding         = [System.Text.UTF8Encoding]::new($true)
      TrailingNewlines = Get-TrailingNewlines $text
    }
  }
  if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
    $text = [System.Text.Encoding]::Unicode.GetString($bytes, 2, $bytes.Length - 2)
    return [pscustomobject]@{
      Text             = $text
      Encoding         = [System.Text.Encoding]::Unicode
      TrailingNewlines = Get-TrailingNewlines $text
    }
  }
  if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
    $text = [System.Text.Encoding]::BigEndianUnicode.GetString($bytes, 2, $bytes.Length - 2)
    return [pscustomobject]@{
      Text             = $text
      Encoding         = [System.Text.Encoding]::BigEndianUnicode
      TrailingNewlines = Get-TrailingNewlines $text
    }
  }

  $utf8Strict = [System.Text.UTF8Encoding]::new($false, $true)
  try {
    $text = $utf8Strict.GetString($bytes)
    return [pscustomobject]@{
      Text             = $text
      Encoding         = [System.Text.UTF8Encoding]::new($false)
      TrailingNewlines = Get-TrailingNewlines $text
    }
  } catch {
    $text = [System.Text.Encoding]::Default.GetString($bytes)
    return [pscustomobject]@{
      Text             = $text
      Encoding         = [System.Text.Encoding]::Default
      TrailingNewlines = Get-TrailingNewlines $text
    }
  }
}

function Write-TextFileWithEncoding {
  param(
    [Parameter(Mandatory)] [string]$Path,
    [Parameter(Mandatory)] [string]$Text,
    [Parameter(Mandatory)] [System.Text.Encoding]$Encoding,
    [string]$TrailingNewlines = ''
  )

  $normalized = [regex]::Replace($Text, '(?:\r\n|\n|\r)+$', '')
  $toWrite = $normalized + $TrailingNewlines
  [System.IO.File]::WriteAllText($Path, $toWrite, $Encoding)
}

function Get-GuideMetadataMap {
  param([Parameter(Mandatory)] [string]$Path)

  $metadataFile = Read-TextFilePreserveEncoding -Path $Path
  Assert-NoMojibakeText -Text $metadataFile.Text -Context 'guide metadata JSON'
  $json = $metadataFile.Text | ConvertFrom-Json
  return ConvertTo-HashtableRecursive -InputObject $json
}

function ConvertTo-HashtableRecursive {
  param([Parameter(Mandatory)] $InputObject)

  if ($null -eq $InputObject) {
    return $null
  }

  if ($InputObject -is [System.Collections.IDictionary]) {
    $result = @{}
    foreach ($key in $InputObject.Keys) {
      $result[$key] = ConvertTo-HashtableRecursive -InputObject $InputObject[$key]
    }
    return $result
  }

  if ($InputObject -is [System.Collections.IEnumerable] -and -not ($InputObject -is [string])) {
    $items = New-Object System.Collections.Generic.List[object]
    foreach ($item in $InputObject) {
      $items.Add((ConvertTo-HashtableRecursive -InputObject $item))
    }
    return $items.ToArray()
  }

  if ($InputObject -is [pscustomobject]) {
    $result = @{}
    foreach ($property in $InputObject.PSObject.Properties) {
      $result[$property.Name] = ConvertTo-HashtableRecursive -InputObject $property.Value
    }
    return $result
  }

  return $InputObject
}

function Get-TwoDigitYear {
  param([Parameter(Mandatory)] [string]$Year)
  return $Year.Substring(2)
}

function Get-FrenchLegacyCode {
  param([Parameter(Mandatory)] [string]$GuideCode)
  $first4 = [int]$GuideCode.Substring(0, 4)
  $suffix = $GuideCode.Substring(4)
  return ($first4 + 100).ToString() + $suffix
}

function ConvertTo-JsonStringLiteral {
  param([AllowNull()][string]$Value)

  if ($null -eq $Value) { return 'null' }

  $builder = New-Object System.Text.StringBuilder
  [void]$builder.Append('"')
  foreach ($char in $Value.ToCharArray()) {
    switch ([int][char]$char) {
      8 { [void]$builder.Append('\b'); continue }
      9 { [void]$builder.Append('\t'); continue }
      10 { [void]$builder.Append('\n'); continue }
      12 { [void]$builder.Append('\f'); continue }
      13 { [void]$builder.Append('\r'); continue }
      34 { [void]$builder.Append('\"'); continue }
      92 { [void]$builder.Append('\\'); continue }
    }

    if ([int][char]$char -lt 32) {
      [void]$builder.AppendFormat('\u{0:x4}', [int][char]$char)
      continue
    }

    [void]$builder.Append($char)
  }

  [void]$builder.Append('"')
  return $builder.ToString()
}

function ConvertTo-TemplateJson {
  param([Parameter(Mandatory)] [hashtable]$Document)

  $fieldOrder = @(
    'year',
    'html_acc_en',
    'html_acc_fr',
    'stnd_pdf_en',
    'stnd_pdf_fr',
    'lrge_pdf_en',
    'lrge_pdf_fr',
    'dwld_etx_en',
    'dwld_etx_fr'
  )

  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add('{')
  $lines.Add('  "data": [')

  for ($rowIndex = 0; $rowIndex -lt $Document.data.Count; $rowIndex++) {
    $row = $Document.data[$rowIndex]
    $rowKeys = $fieldOrder | Where-Object { $row.Contains($_) }

    $lines.Add('    {')
    for ($keyIndex = 0; $keyIndex -lt $rowKeys.Count; $keyIndex++) {
      $key = $rowKeys[$keyIndex]
      $value = $row[$key]

      if ($value -is [System.Array]) {
        $items = foreach ($item in $value) { ConvertTo-JsonStringLiteral -Value ([string]$item) }
        $valueJson = "[{0}]" -f ($items -join ', ')
      } else {
        $valueJson = ConvertTo-JsonStringLiteral -Value ([string]$value)
      }

      $suffix = if ($keyIndex -lt ($rowKeys.Count - 1)) { ',' } else { '' }
      $lines.Add(("      ""{0}"": {1}{2}" -f $key, $valueJson, $suffix))
    }

    $rowSuffix = if ($rowIndex -lt ($Document.data.Count - 1)) { ',' } else { '' }
    $lines.Add("    }$rowSuffix")
  }

  $lines.Add('  ]')
  $lines.Add('}')
  return [string]::Join("`r`n", $lines)
}

function New-LinkArray {
  param(
    [Parameter(Mandatory)] [string]$Label,
    [string]$Url
  )

  if ([string]::IsNullOrWhiteSpace($Url)) {
    return @($Label)
  }

  return @($Label, $Url)
}

function Join-FrenchPrepositionAndName {
  param(
    [Parameter(Mandatory)] [string]$Preposition,
    [Parameter(Mandatory)] [string]$Name
  )

  $trimmedPreposition = $Preposition.TrimEnd()
  $trimmedName = $Name.TrimStart()

  if ($trimmedPreposition.EndsWith("'")) {
    return "$trimmedPreposition$trimmedName"
  }

  return "$trimmedPreposition $trimmedName"
}

function Get-ProvinceLabelFrPrefix {
  param([Parameter(Mandatory)] [hashtable]$Meta)

  if (-not $Meta.ContainsKey('name_fr')) {
    throw "Guide metadata missing name_fr."
  }
  if (-not $Meta.ContainsKey('fr_preposition')) {
    throw "Guide metadata missing fr_preposition."
  }

  $provinceName = Join-FrenchPrepositionAndName -Preposition ([string]$Meta.fr_preposition) -Name ([string]$Meta.name_fr)
  return "Renseignements sur l'imp$([char]0x00F4)t $provinceName"
}

function Get-ProvinceHtmlUrls {
  param(
    [Parameter(Mandatory)] [string]$GuideCode,
    [Parameter(Mandatory)] [string]$Year,
    [Parameter(Mandatory)] [hashtable]$Meta
  )

  $enBase = "https://www.canada.ca/en/revenue-agency/services/forms-publications/tax-packages-years/archived-general-income-tax-benefit-package-$Year/$($Meta.slug_en)"
  $frBase = "https://www.canada.ca/fr/agence-revenu/services/formulaires-publications/trousses-impot-toutes-annees-imposition/archivee-trousse-generale-impot-prestations-$Year/$($Meta.slug_fr)"

  if ([int]$Year -ge 2023) {
    return [pscustomobject]@{
      En = "$enBase/$GuideCode.html"
      Fr = "$frBase/$GuideCode.html"
    }
  }

  switch ($Meta.html_profile) {
    'direct' {
      return [pscustomobject]@{
        En = "$enBase/$GuideCode.html"
        Fr = "$frBase/$GuideCode.html"
      }
    }
    'ontario' {
      return [pscustomobject]@{
        En = "$enBase/$GuideCode/information-residents-$($Meta.slug_en).html"
        Fr = "$frBase/$GuideCode.html"
      }
    }
    'nova_scotia' {
      if ($Year -eq '2022') {
        return [pscustomobject]@{
          En = "$enBase/$GuideCode/information-residents-$($Meta.slug_en).html"
          Fr = "$frBase/$GuideCode/renseignements-residents-$($Meta.slug_fr).html"
        }
      }

      if ([int]$Year -le 2021) {
        return [pscustomobject]@{
          En = "$enBase/$GuideCode/information-residents-$($Meta.slug_en).html"
          Fr = $null
        }
      }
    }
    'nunavut' {
      $enUrl = "$enBase/$GuideCode/information-residents-$($Meta.slug_en).html"
      return [pscustomobject]@{
        En = $enUrl
        Fr = $enUrl
      }
    }
  }

  return [pscustomobject]@{
    En = "$enBase/$GuideCode/information-residents-$($Meta.slug_en).html"
    Fr = "$frBase/$GuideCode/renseignements-residents-$($Meta.slug_fr).html"
  }
}

function Get-GuideHtmlArrays {
  param(
    [Parameter(Mandatory)] [string]$GuideCode,
    [Parameter(Mandatory)] [string]$Year,
    [Parameter(Mandatory)] [hashtable]$Meta,
    [Parameter(Mandatory)] [psobject]$TemplateRow
  )

  if ($Year -eq '2025') {
    return [pscustomobject]@{
      En = @($TemplateRow.html_acc_en)
      Fr = @($TemplateRow.html_acc_fr)
    }
  }

  if ($Meta.kind -eq 'non_resident') {
    $labelEn = "$($Meta.label_en_prefix) for $Year"
    $labelFr = "$($Meta.label_fr_prefix) pour $Year"
    $enBase = "https://www.canada.ca/en/revenue-agency/services/forms-publications/tax-packages-years/archived-general-income-tax-benefit-package-$Year/non-residents/$GuideCode"
    $frBase = "https://www.canada.ca/fr/agence-revenu/services/formulaires-publications/trousses-impot-toutes-annees-imposition/archivee-trousse-generale-impot-prestations-$Year/non-residents/$GuideCode"

    switch ($Year) {
      '2024' { $enUrl = "$enBase/income-tax-benefit-guide-non-residents-deemed-residents-canada.html"; $frUrl = "$frBase/guide-impot-prestations-non-residents-residents-reputes-canada.html" }
      '2023' { $enUrl = "$enBase/income-tax-benefit-guide-non-residents-deemed-residents-canada.html"; $frUrl = "$frBase/guide-impot-prestations-non-residents-residents-reputes-canada.html" }
      '2022' { $enUrl = "$enBase/income-tax-benefit-guide-non-residents-deemed-residents-canada.html"; $frUrl = "$frBase/guide-impot-prestations-non-residents-residents-reputes-canada.html" }
      '2021' { $enUrl = "$enBase/income-tax-benefit-guide-non-residents-deemed-residents-canada.html"; $frUrl = "$frBase/guide-impot-prestations-non-residents-residents-reputes-canada.html" }
      '2020' { $enUrl = "$enBase/income-tax-benefit-guide-non-residents-deemed-residents-canada.html"; $frUrl = "$frBase/guide-impot-prestations-non-residents-residents-reputes-canada.html" }
      '2019' { $enUrl = "$enBase/income-tax-benefit-guide-non-residents-deemed-residents-canada.html"; $frUrl = "$frBase/guide-impot-prestations-non-residents-residents-reputes-canada.html" }
      '2018' { $enUrl = "$enBase/general-income-tax-benefit-guide-non-residents-deemed-residents-canada.html"; $frUrl = "$frBase/guide-general-impot-prestations-non-residents-residents-reputes-canada.html" }
      '2017' { $enUrl = "$enBase/general-income-tax-benefit-guide-non-residents-deemed-residents-canada.html"; $frUrl = "$frBase/guide-general-impot-prestations-non-residents-residents-reputes-canada.html" }
      '2016' { $enUrl = "$enBase/general-guide-non-residents-general-information.html"; $frUrl = "$frBase/guide-general-impot-prestations-non-residents-residents-reputes-canada-remplir-votre-declaration.html" }
      default { throw "Unhandled non-resident year: $Year" }
    }

    return [pscustomobject]@{
      En = @($labelEn, $enUrl)
      Fr = @($labelFr, $frUrl)
    }
  }

  $urls = Get-ProvinceHtmlUrls -GuideCode $GuideCode -Year $Year -Meta $Meta
  $labelEn = "$($Meta.name_en) tax information for $Year"
  $labelFr = "$(Get-ProvinceLabelFrPrefix -Meta $Meta) pour $Year"

  return [pscustomobject]@{
    En = New-LinkArray -Label $labelEn -Url $urls.En
    Fr = New-LinkArray -Label $labelFr -Url $urls.Fr
  }
}

function Get-GuideFileFamily {
  param(
    [Parameter(Mandatory)] [string]$GuideCode,
    [Parameter(Mandatory)] [string]$Year,
    [Parameter(Mandatory)] [ValidateSet('en', 'fr')] [string]$Lang,
    [Parameter(Mandatory)] [ValidateSet('stnd_pdf', 'lrge_pdf', 'dwld_etx')] [string]$Field
  )

  if ($GuideCode -ne '5013-g') {
    if ($Lang -eq 'fr' -and [int]$Year -le 2019) {
      return Get-FrenchLegacyCode -GuideCode $GuideCode
    }
    return $GuideCode
  }

  switch ($Year) {
    '2025' { return '5013-g' }
    '2024' { return '5013-g' }
    '2023' { return '5013-g' }
    '2022' {
      if ($Field -eq 'dwld_etx') { return '5013g' }
      return '5013-g'
    }
    '2021' {
      if ($Field -eq 'lrge_pdf') { return '5013-g' }
      return '5013g'
    }
    '2020' {
      return '5013g'
    }
    default {
      if ($Field -eq 'lrge_pdf') {
        if ($Lang -eq 'fr') { return '5113-g' }
        return '5013-g'
      }
      if ($Lang -eq 'fr') { return '5113g' }
      return '5013g'
    }
  }
}

function Get-GuideFileArray {
  param(
    [Parameter(Mandatory)] [string]$GuideCode,
    [Parameter(Mandatory)] [string]$Year,
    [Parameter(Mandatory)] [ValidateSet('stnd_pdf', 'lrge_pdf', 'dwld_etx')] [string]$Field,
    [Parameter(Mandatory)] [ValidateSet('en', 'fr')] [string]$Lang,
    [Parameter(Mandatory)] [object[]]$TemplateValue
  )

  if ($TemplateValue.Count -eq 1) {
    return @($TemplateValue)
  }

  $family = Get-GuideFileFamily -GuideCode $GuideCode -Year $Year -Lang $Lang -Field $Field
  $yy = Get-TwoDigitYear -Year $Year
  $folder = "https://www.canada.ca/content/dam/cra-arc/formspubs/pub/$GuideCode"
  $label = [string]$TemplateValue[0]

  switch ($Field) {
    'stnd_pdf' {
      $url = "$folder/$family-$yy$($Lang.Substring(0,1)).pdf"
      return @($label, $url)
    }
    'lrge_pdf' {
      $url = "$folder/$family-lp-$yy$($Lang.Substring(0,1)).pdf"
      return @($label, $url)
    }
    'dwld_etx' {
      $url = "$folder/$family-$yy$($Lang.Substring(0,1)).txt"
      return @($label, $url)
    }
  }
}

function Build-GuideDocumentFromTemplate {
  param(
    [Parameter(Mandatory)] [psobject]$TemplateDocument,
    [Parameter(Mandatory)] [string]$GuideCode,
    [Parameter(Mandatory)] [hashtable]$MetadataMap
  )

  if (-not $MetadataMap.ContainsKey($GuideCode)) {
    throw "Guide metadata missing for $GuideCode"
  }

  $meta = $MetadataMap[$GuideCode]
  $rows = New-Object System.Collections.Generic.List[hashtable]

  foreach ($templateRow in $TemplateDocument.data) {
    $year = [string]$templateRow.year
    $html = Get-GuideHtmlArrays -GuideCode $GuideCode -Year $year -Meta $meta -TemplateRow $templateRow

    $rows.Add([ordered]@{
      year = $year
      html_acc_en = @($html.En)
      html_acc_fr = @($html.Fr)
      stnd_pdf_en = @(Get-GuideFileArray -GuideCode $GuideCode -Year $year -Field 'stnd_pdf' -Lang 'en' -TemplateValue @($templateRow.stnd_pdf_en))
      stnd_pdf_fr = @(Get-GuideFileArray -GuideCode $GuideCode -Year $year -Field 'stnd_pdf' -Lang 'fr' -TemplateValue @($templateRow.stnd_pdf_fr))
      lrge_pdf_en = @(Get-GuideFileArray -GuideCode $GuideCode -Year $year -Field 'lrge_pdf' -Lang 'en' -TemplateValue @($templateRow.lrge_pdf_en))
      lrge_pdf_fr = @(Get-GuideFileArray -GuideCode $GuideCode -Year $year -Field 'lrge_pdf' -Lang 'fr' -TemplateValue @($templateRow.lrge_pdf_fr))
      dwld_etx_en = @(Get-GuideFileArray -GuideCode $GuideCode -Year $year -Field 'dwld_etx' -Lang 'en' -TemplateValue @($templateRow.dwld_etx_en))
      dwld_etx_fr = @(Get-GuideFileArray -GuideCode $GuideCode -Year $year -Field 'dwld_etx' -Lang 'fr' -TemplateValue @($templateRow.dwld_etx_fr))
    })
  }

  return [ordered]@{ data = $rows }
}

function Test-Url200 {
  param(
    [Parameter(Mandatory)] [string]$Url,
    [int]$TimeoutSec = 10,
    [int]$RequestDelayMs = 0,
    [int]$RetryCount = 2,
    [int]$RetryDelayMs = 500,
    [int]$MaxRedirects = 8
  )

  function Get-HttpStatusFromError {
    param([Parameter(Mandatory)] $ErrorRecord)
    try {
      $resp = $ErrorRecord.Exception.Response
      if ($null -eq $resp) { return $null }
      if ($resp -is [System.Net.HttpWebResponse]) { return [int]$resp.StatusCode }
      if ($resp.PSObject.Properties.Name -contains 'StatusCode') { return [int]$resp.StatusCode }
    } catch {
      return $null
    }
    return $null
  }

  function Get-FinalResponseUri {
    param($Response)
    try {
      if ($null -ne $Response.BaseResponse.ResponseUri) {
        return [string]$Response.BaseResponse.ResponseUri.AbsoluteUri
      }
    } catch {
      return $null
    }
    return $null
  }

  function Is-Canada404LandingUrl {
    param([AllowNull()][string]$FinalUrl)
    if ([string]::IsNullOrWhiteSpace($FinalUrl)) { return $false }
    return $FinalUrl -match '^https://www\.canada\.ca/errors/404\.html(?:[?#].*)?$'
  }

  function Is-TransientHttpStatus {
    param([Nullable[int]]$StatusCode)
    if ($null -eq $StatusCode) { return $true }
    return $StatusCode -in @(408, 429, 500, 502, 503, 504)
  }

  function Invoke-UrlAttempt {
    param(
      [Parameter(Mandatory)] [string]$AttemptUrl,
      [Parameter(Mandatory)] [string]$Method,
      [int]$AttemptTimeoutSec,
      [int]$AttemptRequestDelayMs,
      [int]$AttemptRetryCount,
      [int]$AttemptRetryDelayMs,
      [int]$AttemptMaxRedirects
    )

    for ($attempt = 0; $attempt -le $AttemptRetryCount; $attempt++) {
      if ($AttemptRequestDelayMs -gt 0) {
        Start-Sleep -Milliseconds $AttemptRequestDelayMs
      }

      try {
        $response = Invoke-WebRequest -Uri $AttemptUrl -Method $Method -TimeoutSec $AttemptTimeoutSec -MaximumRedirection $AttemptMaxRedirects -ErrorAction Stop
        $statusCode = [int]$response.StatusCode
        $finalUrl = Get-FinalResponseUri -Response $response
        $isCanada404Landing = Is-Canada404LandingUrl -FinalUrl $finalUrl
        return [pscustomobject]@{
          Success    = ($statusCode -ge 200 -and $statusCode -le 299 -and -not $isCanada404Landing)
          StatusCode = $statusCode
          FinalUrl   = $finalUrl
          Redirected = ($null -ne $finalUrl -and $finalUrl -ne $AttemptUrl)
        }
      } catch {
        $statusCode = Get-HttpStatusFromError -ErrorRecord $_
        $retryable = Is-TransientHttpStatus -StatusCode $statusCode
        if ($retryable -and $attempt -lt $AttemptRetryCount) {
          $sleepMs = $AttemptRetryDelayMs * [math]::Pow(2, $attempt)
          if ($sleepMs -gt 0) {
            Start-Sleep -Milliseconds ([int][math]::Round($sleepMs))
          }
          continue
        }

        return [pscustomobject]@{
          Success    = $false
          StatusCode = $statusCode
          FinalUrl   = $null
          Redirected = $false
        }
      }
    }

    return [pscustomobject]@{
      Success    = $false
      StatusCode = $null
      FinalUrl   = $null
      Redirected = $false
    }
  }

  $headResult = Invoke-UrlAttempt -AttemptUrl $Url -Method Head -AttemptTimeoutSec $TimeoutSec -AttemptRequestDelayMs $RequestDelayMs -AttemptRetryCount $RetryCount -AttemptRetryDelayMs $RetryDelayMs -AttemptMaxRedirects $MaxRedirects
  if ($headResult.Success -and -not $headResult.Redirected) { return $true }

  $getResult = Invoke-UrlAttempt -AttemptUrl $Url -Method Get -AttemptTimeoutSec $TimeoutSec -AttemptRequestDelayMs $RequestDelayMs -AttemptRetryCount $RetryCount -AttemptRetryDelayMs $RetryDelayMs -AttemptMaxRedirects $MaxRedirects
  if ($getResult.Success) { return $true }

  return $false
}

function Get-RegexEscaped {
  param([Parameter(Mandatory)] [string]$Value)
  return [regex]::Escape($Value)
}

function Replace-ArrayInYearObject {
  param(
    [Parameter(Mandatory)] [string]$JsonText,
    [Parameter(Mandatory)] [string]$Year,
    [Parameter(Mandatory)] [string]$KeyName,
    [Parameter(Mandatory)] [string]$NewArrayJson
  )

  $yearPattern = '"year"\s*:\s*"' + (Get-RegexEscaped $Year) + '"'
  $objPattern = '\{(?<obj>[^{}]*' + $yearPattern + '.*?)[\r\n ]*\}'
  $objMatch = [regex]::Match($JsonText, $objPattern, 'Singleline')
  if (-not $objMatch.Success) { return $JsonText }

  $objText = $objMatch.Value
  $keyPattern = '"' + (Get-RegexEscaped $KeyName) + '"\s*:\s*(\[[^\]]*\]|"[^"]*")'
  $newObjText = [regex]::Replace($objText, $keyPattern, '"' + $KeyName + '": ' + $NewArrayJson, 1)
  if ($newObjText -eq $objText) { return $JsonText }

  return $JsonText.Substring(0, $objMatch.Index) + $newObjText + $JsonText.Substring($objMatch.Index + $objMatch.Length)
}

function Get-LinkUrl {
  param([object]$Value)
  if ($null -eq $Value) { return $null }
  if ($Value -is [string]) { return $null }
  if ($Value -is [object[]] -and $Value.Count -ge 2) { return [string]$Value[1] }
  return $null
}

function Is-NotAvailablePair {
  param([object]$Value, [string]$Lang)
  if ($null -eq $Value) { return $false }
  if ($Value -is [object[]] -and $Value.Count -eq 1) {
    if ($Lang -eq 'en') { return ($Value[0] -eq 'Not available') }
    if ($Lang -eq 'fr') { return ($Value[0] -eq 'Sans objet') }
  }
  return $false
}

function Convert-ArrayToInlineJson {
  param([Parameter(Mandatory)] [object[]]$Value)
  return ($Value | ConvertTo-Json -Compress)
}

function Get-RowPairBases {
  param([Parameter(Mandatory)] [psobject]$Row)
  return @($Row.PSObject.Properties | ForEach-Object { $_.Name }) |
    Where-Object { $_ -match '_(en|fr)$' } |
    ForEach-Object { $_ -replace '_(en|fr)$', '' } |
    Sort-Object -Unique
}

function Set-PairInRowAndJson {
  param(
    [Parameter(Mandatory)] [psobject]$Row,
    [Parameter(Mandatory)] [string]$YearValue,
    [Parameter(Mandatory)] [string]$EnKey,
    [Parameter(Mandatory)] [object[]]$EnValue,
    [Parameter(Mandatory)] [string]$FrKey,
    [Parameter(Mandatory)] [object[]]$FrValue,
    [Parameter(Mandatory)] [ref]$JsonTextRef
  )

  $Row.$EnKey = $EnValue
  $Row.$FrKey = $FrValue
  $jsonText = [string]$JsonTextRef.Value
  $jsonText = Replace-ArrayInYearObject -JsonText $jsonText -Year $YearValue -KeyName $EnKey -NewArrayJson (Convert-ArrayToInlineJson -Value $EnValue)
  $jsonText = Replace-ArrayInYearObject -JsonText $jsonText -Year $YearValue -KeyName $FrKey -NewArrayJson (Convert-ArrayToInlineJson -Value $FrValue)
  $JsonTextRef.Value = $jsonText
}

function Set-PairToNotAvailable {
  param(
    [Parameter(Mandatory)] [psobject]$Row,
    [Parameter(Mandatory)] [string]$YearValue,
    [Parameter(Mandatory)] [string]$EnKey,
    [Parameter(Mandatory)] [string]$FrKey,
    [Parameter(Mandatory)] [ref]$JsonTextRef
  )

  Set-PairInRowAndJson -Row $Row -YearValue $YearValue -EnKey $EnKey -EnValue $EN_NA -FrKey $FrKey -FrValue $FR_NA -JsonTextRef $JsonTextRef
}

function Normalize-NaArrayLiterals {
  param([Parameter(Mandatory)] [string]$JsonText)
  $out = $JsonText
  $out = [regex]::Replace($out, '("(?<k>[^"]+_en)"\s*:\s*)"Not available"', '$1["Not available"]')
  $out = [regex]::Replace($out, '("(?<k>[^"]+_fr)"\s*:\s*)"Sans objet"', '$1["Sans objet"]')
  return $out
}

$PubsListPath = Resolve-ExistingPath -PathValue $PubsListPath -BaseDir $scriptRoot
$TemplatePath = Resolve-ExistingPath -PathValue $TemplatePath -BaseDir $scriptRoot
$GuideMetadataPath = Resolve-ExistingPath -PathValue $GuideMetadataPath -BaseDir $scriptRoot

if (-not $PSBoundParameters.ContainsKey('OutputDir') -or [string]::IsNullOrWhiteSpace($OutputDir)) {
  $OutputDir = $defaultGuideOutputDir
} else {
  $OutputDir = Resolve-DirectoryPath -PathValue $OutputDir -BaseDir $scriptRoot
}
[System.IO.Directory]::CreateDirectory($OutputDir) | Out-Null

$templateFile = Read-TextFilePreserveEncoding -Path $TemplatePath
$templateDocument = $templateFile.Text | ConvertFrom-Json
$guideMetadataMap = Get-GuideMetadataMap -Path $GuideMetadataPath
$pubsForGeneration = Get-PubsList -Path $PubsListPath -SkipComments
if (-not $pubsForGeneration) {
  throw "No guide codes found in $PubsListPath"
}

$generatedSources = @{}
$generatedTotal = 0

Write-Host "Step 1/2: Generating guide JSON from template..." -ForegroundColor Cyan

foreach ($pub in $pubsForGeneration) {
  if ($pub -notmatch '^\d{4}-.+$') {
    Write-Warning "Skipping invalid guide code: '$pub'"
    continue
  }

  $document = Build-GuideDocumentFromTemplate -TemplateDocument $templateDocument -GuideCode $pub -MetadataMap $guideMetadataMap
  $outJson = (ConvertTo-TemplateJson -Document $document) + "`r`n"
  Assert-NoMojibakeText -Text $outJson -Context "$pub generated JSON"
  $outPath = Join-Path $OutputDir "$pub-table-data.json"

  $generatedSources[$pub] = [pscustomobject]@{
    JsonText         = $outJson
    Encoding         = $templateFile.Encoding
    TrailingNewlines = $templateFile.TrailingNewlines
  }

  if ($DryRun) {
    Write-Host "[DRY RUN] $pub => would write $outPath"
  } else {
    Write-TextFileWithEncoding -Path $outPath -Text $outJson -Encoding $defaultOutputEncoding -TrailingNewlines $templateFile.TrailingNewlines
  }
  $generatedTotal++
}

Write-Host "Done. Generated $generatedTotal JSON file(s) in '$OutputDir'." -ForegroundColor Cyan

if ($GenerateOnly) {
  Write-Host "Generate-only mode enabled. Skipping link validation." -ForegroundColor Yellow
  return
}

if ($PauseBeforeLinkCheck -and -not $DryRun) {
  $answer = (Read-Host "Files generated. Validate links now? [Y/N]").Trim().ToLowerInvariant()
  if ($answer -notin @('y', 'yes')) {
    Write-Host "Skipped link validation by user choice." -ForegroundColor Yellow
    return
  }
}

$validatedTotal = 0
Write-Host "Step 2/2: Validating bilingual guide links..." -ForegroundColor Cyan

foreach ($pub in $pubsForGeneration) {
  if ($pub -notmatch '^\d{4}-.+$') {
    continue
  }

  $outPath = Join-Path $OutputDir "$pub-table-data.json"

  if ($DryRun) {
    $generatedSource = $generatedSources[$pub]
    if ($null -eq $generatedSource) {
      Write-Warning "No generated JSON found for $pub in dry-run mode. Skipping validation."
      continue
    }
    $jsonSourceText = $generatedSource.JsonText
    $sourceEncoding = $generatedSource.Encoding
    $sourceTrailingNewlines = $generatedSource.TrailingNewlines
  } else {
    if (-not (Test-Path -LiteralPath $outPath)) {
      Write-Warning "Generated file missing for $pub ($outPath). Skipping validation."
      continue
    }
    $generatedFile = Read-TextFilePreserveEncoding -Path $outPath
    $jsonSourceText = $generatedFile.Text
    $sourceEncoding = $generatedFile.Encoding
    $sourceTrailingNewlines = $generatedFile.TrailingNewlines
  }

  $jsonObj = $jsonSourceText | ConvertFrom-Json
  $outJsonFinal = $jsonSourceText
  $changedPairs = 0

  foreach ($row in $jsonObj.data) {
    $yearValue = [string]$row.year
    $bases = Get-RowPairBases -Row $row

    foreach ($base in $bases) {
      $enKey = "${base}_en"
      $frKey = "${base}_fr"
      if (-not ($row.PSObject.Properties.Name -contains $enKey)) { continue }
      if (-not ($row.PSObject.Properties.Name -contains $frKey)) { continue }

      $enVal = $row.$enKey
      $frVal = $row.$frKey

      $enIsNA = Is-NotAvailablePair -Value $enVal -Lang 'en'
      $frIsNA = Is-NotAvailablePair -Value $frVal -Lang 'fr'
      if ($enIsNA -or $frIsNA) {
        Set-PairToNotAvailable -Row $row -YearValue $yearValue -EnKey $enKey -FrKey $frKey -JsonTextRef ([ref]$outJsonFinal)
        $changedPairs++
        continue
      }

      $enUrl = Get-LinkUrl -Value $enVal
      $frUrl = Get-LinkUrl -Value $frVal
      if (-not $enUrl -and -not $frUrl) { continue }
      if (-not $enUrl -or -not $frUrl) { continue }

      $enValid = Test-Url200 -Url $enUrl -TimeoutSec $TimeoutSec -RequestDelayMs $RequestDelayMs -RetryCount $RetryCount -RetryDelayMs $RetryDelayMs -MaxRedirects $MaxRedirects
      $frValid = Test-Url200 -Url $frUrl -TimeoutSec $TimeoutSec -RequestDelayMs $RequestDelayMs -RetryCount $RetryCount -RetryDelayMs $RetryDelayMs -MaxRedirects $MaxRedirects

      if ($enValid -and $frValid) { continue }

      Set-PairToNotAvailable -Row $row -YearValue $yearValue -EnKey $enKey -FrKey $frKey -JsonTextRef ([ref]$outJsonFinal)
      $changedPairs++
    }
  }

  if ($DryRun) {
    Write-Host "[DRY RUN] $pub => would modify $changedPairs pair(s) in $outPath"
  } else {
    $outJsonFinal = Normalize-NaArrayLiterals -JsonText $outJsonFinal
    Assert-NoMojibakeText -Text $outJsonFinal -Context "$pub validated JSON"
    Write-TextFileWithEncoding -Path $outPath -Text $outJsonFinal -Encoding $defaultOutputEncoding -TrailingNewlines $sourceTrailingNewlines
    Write-Host "$pub => modified $changedPairs pair(s)."
  }
  $validatedTotal++
}

Write-Host "Done. Validated $validatedTotal JSON file(s)." -ForegroundColor Green
