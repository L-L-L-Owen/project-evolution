$root = Split-Path -Parent $PSScriptRoot
$validator = Join-Path $PSScriptRoot 'validate_records.ps1'
$valid = Join-Path $root 'references\sample-evidence.valid.json'
$invalid = Join-Path $root 'references\sample-evidence.invalid.json'
$validPassed = $false
try { & $validator -RecordPath $valid -Type Evidence | Out-Null; $validPassed = $true } catch { }
if (-not $validPassed) { throw 'Valid sample was rejected.' }
$failed = $false
try { & $validator -RecordPath $invalid -Type Evidence | Out-Null } catch { $failed = $true }
if (-not $failed) { throw 'Invalid sample was accepted.' }
Write-Output 'PASS validator samples'
