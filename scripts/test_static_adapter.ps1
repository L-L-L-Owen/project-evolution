$adapter=Join-Path $PSScriptRoot 'static-project-adapter.ps1'
$tmp=Join-Path $env:TEMP ('project-evolution-adapter-' + [guid]::NewGuid().ToString('N'))
$project=Join-Path $tmp 'project'; $out=Join-Path $tmp 'out'
New-Item -ItemType Directory -Force (Join-Path $project 'src') | Out-Null
Set-Content (Join-Path $project 'package.json') '{"name":"demo"}' -Encoding UTF8
Set-Content (Join-Path $project 'src\index.js') 'console.log(1)' -Encoding UTF8
try {
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $adapter -ProjectPath $project -ProjectId demo-project -OutputDir $out | Out-Null
  $profile=Get-Content -Raw (Join-Path $out 'project-profile.json') | ConvertFrom-Json
  if ($profile.adapterStatus -ne 'partial') { throw 'adapterStatus must be partial' }
  if (-not (Test-Path (Join-Path $out 'evidence-static-scan.json'))) { throw 'scan Evidence missing' }
  $manifest=Get-Content -Raw (Join-Path $out 'scan-manifest.json') | ConvertFrom-Json
  if ($manifest.includedFileCount -lt 2 -or -not $manifest.repeatable) { throw 'scan manifest incomplete' }
  $report=Get-Content -Raw (Join-Path $out 'latest-report.md')
  if ($report -notmatch 'partial') { throw 'report status missing' }
  Write-Output 'PASS static adapter evidence and partial status'
} finally {
  if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
}
