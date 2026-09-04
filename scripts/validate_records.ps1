param(
  [Parameter(Mandatory=$true)][string]$RecordPath,
  [Parameter(Mandatory=$true)][ValidateSet('ProjectContext','PurposeModel','ProjectProfile','FeatureMap','Feedback','Opportunity','Hypothesis','Evidence','Decision','ResearchSource','ResearchConclusion','RunResult')][string]$Type,
  [string]$Root
)

$schemaPath = Join-Path $PSScriptRoot '..\references\project-evolution.schema.json'
$schema = Get-Content -Raw $schemaPath | ConvertFrom-Json
$record = Get-Content -Raw $RecordPath | ConvertFrom-Json
if ($record -is [array]) { throw 'RecordPath must contain one JSON object, not an array.' }

function Get-ObjectProperty($obj, [string]$name) {
  if ($null -eq $obj) { return $null }
  $p = $obj.PSObject.Properties[$name]
  if ($null -eq $p) { return $null }
  Write-Output -NoEnumerate $p.Value
}
function Resolve-Ref($ref) {
  $name = ($ref -split '/')[-1]
  $defs = $schema.PSObject.Properties['$defs'].Value
  return $defs.PSObject.Properties[$name].Value
}
function Test-Value($value, $rule, [string]$path) {
  if ($null -eq $rule) { return $true }
  if ($rule.'$ref') { return Test-Value $value (Resolve-Ref $rule.'$ref') $path }
  if ($rule.oneOf) {
    foreach ($candidate in $rule.oneOf) { try { if (Test-Value $value $candidate $path) { return $true } } catch {} }
    throw "$path does not match any allowed schema."
  }
  if ($null -ne $rule.const -and $value -ne $rule.const) { throw "$path must equal $($rule.const)." }
  if ($rule.enum -and $value -notin @($rule.enum)) { throw "$path has invalid enum value: $value" }
  $types = if ($rule.PSObject.Properties['type']) { @($rule.type) } else { @() }
  if ($types.Count -gt 0) {
    $isNull = $null -eq $value; $isArray = $value -is [array]; $isObject = ($value -is [pscustomobject])
    $isInteger = ($value -is [int] -or $value -is [long]); $isNumber = ($value -is [int] -or $value -is [long] -or $value -is [double] -or $value -is [decimal])
    if ($rule.format -eq 'date-time' -and $value -is [datetime]) { $isString = $true } else { $isString = ($value -is [string]) }
    $ok = $false
    foreach ($t in $types) {
      if (($t -eq 'null' -and $isNull) -or ($t -eq 'array' -and $isArray) -or ($t -eq 'object' -and $isObject) -or ($t -eq 'integer' -and $isInteger) -or ($t -eq 'number' -and $isNumber) -or ($t -eq 'string' -and $isString) -or ($t -eq 'boolean' -and $value -is [bool])) { $ok=$true }
    }
    if (-not $ok) { throw "$path has wrong type." }
  }
  if ($null -eq $value -and $types -contains 'null') { return $true }
  if ($rule.type -eq 'object' -or $rule.properties -or $rule.required) {
    if (-not ($value -is [pscustomobject])) { throw "$path must be an object." }
    $valueProps=@($value.PSObject.Properties)
    if ($rule.PSObject.Properties['required'] -and $null -ne $rule.required) { foreach ($name in @($rule.required)) { if ($valueProps.Name -notcontains $name) { throw "$path missing required field: $name" } } }
    if ($rule.additionalProperties -eq $false) { foreach ($name in $valueProps.Name) { if ($null -eq $rule.properties.PSObject.Properties[$name]) { throw "$path has unknown field: $name" } } }
    foreach ($p in $valueProps) { $child = Get-ObjectProperty $rule.properties $p.Name; if ($child) { Test-Value $p.Value $child "$path.$($p.Name)" } }
  }
  if ($rule.type -eq 'array' -or $rule.items) { foreach ($item in @($value)) { Test-Value $item $rule.items "$path[]" } }
  if ($rule.minItems -and @($value).Count -lt $rule.minItems) { throw "$path has too few items." }
  if ($rule.minLength -and $value.Length -lt $rule.minLength) { throw "$path is too short." }
  if ($null -ne $rule.minimum -and $value -lt $rule.minimum) { throw "$path is below minimum." }
  if ($rule.pattern -and $value -notmatch $rule.pattern) { throw "$path has invalid format." }
  if ($rule.format -eq 'date-time' -and $null -ne $value -and $value -isnot [datetime] -and $value -notmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}') { throw "$path is not an ISO date-time." }
  if ($rule.format -eq 'uri' -and $null -ne $value -and $value -notmatch '^https?://') { throw "$path is not a stable HTTP URL." }
  return $true
}

$defs = $schema.PSObject.Properties['$defs'].Value
$def = $defs.PSObject.Properties[$Type].Value
if (-not $def) { throw "Schema definition not found: $Type" }
Test-Value $record $def $Type | Out-Null
if ($Type -eq 'Opportunity' -and $record.status -eq 'accepted' -and ($null -eq $record.valueAssessment -or $record.valueAssessment.result -ne 'pass')) { throw 'accepted Opportunity requires valueAssessment.result=pass.' }
if ($Type -eq 'Decision' -and $record.decision -eq 'defer' -and $null -eq $record.nextReviewAt) { throw 'defer requires nextReviewAt.' }

if ($Root -and $record.projectId) {
  $idsByProject = @{}
  Get-ChildItem $Root -Recurse -Filter *.jsonl -ErrorAction SilentlyContinue | ForEach-Object {
    Get-Content $_.FullName | Where-Object { $_.Trim() } | ForEach-Object {
      $r = $_.Trim() | ConvertFrom-Json; $rid = if ($r.id) { $r.id } else { $r.runId }
      if ($rid -and $r.projectId) { if (-not $idsByProject.ContainsKey($r.projectId)) { $idsByProject[$r.projectId]=@{} }; $idsByProject[$r.projectId][$rid]=$true }
    }
  }
  function Collect-Refs($node) {
    $out=@(); if ($null -eq $node) { return $out }
    if ($node -is [array]) { foreach ($item in $node) { $out += Collect-Refs $item }; return $out }
    if ($node -is [pscustomobject]) {
      foreach ($prop in $node.PSObject.Properties) {
        if ($prop.Name -in @('opportunityId','subjectId','evidenceRefs','sourceRefs','supportsOpportunityIds','supportsHypothesisIds','relatedJobIds','relatedHypothesisIds')) { $out += @($prop.Value) }
        $out += Collect-Refs $prop.Value
      }
    }
    return $out
  }
  $refs = @(Collect-Refs $record)
  foreach ($ref in $refs) { if ($ref -and (-not $idsByProject.ContainsKey($record.projectId) -or -not $idsByProject[$record.projectId].ContainsKey($ref))) { throw "unresolved same-project reference: $ref" } }
}
Write-Output "PASS $Type $RecordPath (schema-driven)"
