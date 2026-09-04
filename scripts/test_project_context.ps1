$script=Join-Path $PSScriptRoot 'extract_project_context.ps1'
$tmp=Join-Path $env:TEMP ('project-evolution-context-' + [guid]::NewGuid().ToString('N'))
$project=Join-Path $tmp 'project'; $out=Join-Path $tmp 'out'
New-Item -ItemType Directory -Force (Join-Path $project 'public') | Out-Null
New-Item -ItemType Directory -Force (Join-Path $project 'data') | Out-Null
Set-Content (Join-Path $project 'public\index.html') '<label for="productKeyword">产品关键词</label><input id="productKeyword"><label for="quantity">开发数量</label><input id="quantity">' -Encoding UTF8
Set-Content (Join-Path $project 'data\jobs.json') '{"id":"job-demo-completed","status":"completed","updatedAt":"2026-09-03T00:00:00Z","request":{"productKeyword":"demo product","quantity":5}}' -Encoding UTF8
try {
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script -ProjectPath $project -ProjectId demo-project -OutputDir $out | Out-Null
  $ctx=Get-Content -Raw (Join-Path $out 'project-context.json') | ConvertFrom-Json
  if ($ctx.currentRequest -ne $null) { throw 'historical task was mislabeled as current request' }
  if ($ctx.currentRequestStatus -ne 'unknown') { throw 'unknown current request status was not preserved' }
  if ($ctx.currentRequestSource -ne 'none') { throw 'historical task was used as current request source' }
  if ($ctx.latestCompletedRequest.productKeyword -ne 'demo product') { throw 'latest completed request was not extracted' }
  if ([int]$ctx.latestCompletedRequest.quantity -ne 5) { throw 'latest completed request quantity was not extracted' }
  if (Test-Path (Join-Path $out 'current-request.json')) { throw 'stale current-request.json was not removed' }
  $plan=Get-Content -Raw (Join-Path $out 'research-plan.json') | ConvertFrom-Json
  if (@($plan.inputs | Where-Object {$_ -eq 'current-request.json'}).Count -gt 0) { throw 'research plan references current request without an active task' }
  if (@($plan.inputs | Where-Object {$_ -eq 'latest-completed-request.json'}).Count -ne 1) { throw 'research plan did not reference the historical baseline file' }
  if ($plan.status -ne 'blocked_no_current_task') { throw 'research plan did not record blocked no-current-task status' }
  if (Test-Path (Join-Path $out 'opportunity-draft.json')) { throw 'opportunity was generated without an active task' }
  if (Test-Path (Join-Path $out 'hypothesis-draft.json')) { throw 'hypothesis was generated without an active task' }
  if (@($ctx.detectedFormFields | Where-Object {$_.id -eq 'productKeyword'}).Count -lt 1) { throw 'form field was not extracted' }
  $v=Join-Path $PSScriptRoot 'validate_records.ps1'
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $v -RecordPath (Join-Path $out 'project-context.json') -Type ProjectContext | Out-Null
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $v -RecordPath (Join-Path $out 'feature-map.json') -Type FeatureMap | Out-Null
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $v -RecordPath (Join-Path $out 'evidence-context-scan.json') -Type Evidence | Out-Null
  Write-Output 'PASS project context extraction'
} finally {
  if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue }
}
