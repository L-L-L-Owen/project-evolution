param(
  [Parameter(Mandatory=$true)][string]$ProjectPath,
  [Parameter(Mandatory=$true)][ValidatePattern('^[a-z][a-z0-9-]{2,63}$')][string]$ProjectId,
  [Parameter(Mandatory=$true)][string]$OutputDir
)

if (-not (Test-Path $ProjectPath -PathType Container)) { throw "Project path not found: $ProjectPath" }
New-Item -ItemType Directory -Force $OutputDir | Out-Null

function Write-AtomicText([string]$Path, [string]$Content) {
  $tmp = "$Path.tmp-$([guid]::NewGuid().ToString('N'))"
  try {
    [System.IO.File]::WriteAllText($tmp, $Content, (New-Object System.Text.UTF8Encoding($true)))
    if (Test-Path $Path) {
      $bak = "$Path.bak"
      Copy-Item $Path $bak -Force
      [System.IO.File]::Replace($tmp, $Path, $bak, $true)
    } else { Move-Item $tmp $Path -Force }
  } catch {
    if (Test-Path $tmp) { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
    throw "partial-write: $Path : $($_.Exception.Message)"
  }
}

$excluded = @('node_modules','vendor','.git','dist','build')
$files = Get-ChildItem $ProjectPath -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
  $path=$_.FullName
  foreach ($x in $excluded) { if ($path -match "\\$([regex]::Escape($x))(\\|$)") { return $false } }
  return $true
}
$relativeFiles = @($files | ForEach-Object { $_.FullName.Substring($ProjectPath.TrimEnd('\').Length).TrimStart('\') })
$names = @($files.Name)
function Has([string]$name) { return ($names -contains $name) }
$hasWebMarkers = @('index.html','src','app','pages','public','routes') | Where-Object { Test-Path (Join-Path $ProjectPath $_) }
$language = if (Has 'package.json') { 'javascript/typescript' } elseif (Has 'composer.json') { 'php' } elseif (Has 'requirements.txt') { 'python' } elseif (@($files | Where-Object Extension -eq '.csproj').Count) { 'csharp' } else { 'unknown' }
$framework = if (Has 'vite.config.js' -or Has 'vite.config.ts' -or Has 'vite.config.mjs') { 'vite' } elseif (Has 'next.config.js' -or Has 'next.config.mjs' -or Has 'next.config.ts') { 'next.js' } elseif (Has 'wp-config.php') { 'wordpress' } elseif (Has 'artisan') { 'laravel' } else { 'unknown' }
$type = if ($framework -ne 'unknown' -or @($hasWebMarkers).Count -gt 0) { 'web' } elseif (@($files | Where-Object Extension -eq '.csproj').Count) { 'desktop-or-dotnet' } else { 'unknown' }
$capabilities = [ordered]@{ login='unknown'; payment='unknown'; upload='unknown'; database='unknown'; server='unknown' }
if (Has 'prisma.schema' -or Has 'drizzle.config.ts' -or Has 'wp-config.php') { $capabilities.database='present' }
$now=(Get-Date).ToUniversalTime().ToString('o')
$profile = [ordered]@{ id="profile-$ProjectId"; schemaVersion=1; projectId=$ProjectId; projectType=$type; language=$language; framework=$framework; runtime='unknown'; deployment='unknown'; server='unknown'; database=$capabilities.database; capabilities=$capabilities; adapterStatus='partial'; createdAt=$now; updatedAt=$now }

$markers = [ordered]@{ frontend=@('src','app','pages','components','public','index.html'); backend=@('api','server','routes','controllers'); tests=@('tests','test','__tests__'); docs=@('docs','README.md') }
$features = @(); $evidenceId="evidence-static-scan-$ProjectId"
foreach ($pair in $markers.GetEnumerator()) {
  $hits=@(); foreach ($marker in $pair.Value) { if (Test-Path (Join-Path $ProjectPath $marker)) { $hits += $marker } }
  $exists = @($hits).Count -gt 0
  $gaps = @($(if ($exists) {'仅证明静态入口存在，尚未完成真实用户任务验收'} else {'未识别到明确目录或入口'}))
  $features += [ordered]@{ featureId="feature-$($pair.Key)"; name=$pair.Key; jobIds=@(); exists=$(if($exists){'yes'}else{'unknown'}); availability='not_verified'; usability='not_verified'; maturity='not_verified'; evidenceRefs=@($evidenceId); referenceRefs=@(); knownGaps=$gaps }
}
$featureMap = [ordered]@{ id="feature-map-$ProjectId"; schemaVersion=1; projectId=$ProjectId; features=$features; createdAt=$now; updatedAt=$now }
$manifest = [ordered]@{ scanId=$evidenceId; projectId=$ProjectId; scannedAt=$now; scannerVersion='static-adapter-1'; projectPath=$ProjectPath; includedFileCount=@($relativeFiles).Count; matchedFiles=$relativeFiles; excludedDirectories=$excluded; repeatable=$true; limitations=@('只读静态扫描','不启动项目','不执行用户任务','不验证线上行为') }
$evidence = [ordered]@{ id=$evidenceId; schemaVersion=1; projectId=$ProjectId; type='static_scan'; source='adapter'; capturedAt=$now; relatedJobIds=@(); relatedHypothesisIds=@(); evidenceLevel='L0'; artifactRefs=@('scan-manifest.json','project-profile.json','feature-map.json'); repeatability='repeatable'; participantType='none'; dataClass='internal'; confidence='medium'; status='valid'; createdAt=$now; updatedAt=$now }
$report = @"
# 项目进化初始报告

## 本轮结论
已完成只读静态扫描。适配器状态是 **partial（部分能力）**，不是“已具备真实验收能力”。

## 需要用户决定什么
请补充项目的真实设计目的、目标用户和最重要的一个任务。文件结构只能提供初步线索，不能替代你的确认。

## 已验证与未验证
- 已验证：扫描时间、扫描范围、排除目录、命中文件和常见技术标记已记录。
- 未验证：功能是否好用、目标用户体验、项目运行流程、线上行为和业务效果。

## 下一步动作
确认一个真实用户任务后，再生成可比较的改进假设、基线和研究目标。
"@

Write-AtomicText (Join-Path $OutputDir 'project-profile.json') ($profile | ConvertTo-Json -Depth 8)
Write-AtomicText (Join-Path $OutputDir 'feature-map.json') ($featureMap | ConvertTo-Json -Depth 12)
Write-AtomicText (Join-Path $OutputDir 'scan-manifest.json') ($manifest | ConvertTo-Json -Depth 12)
Write-AtomicText (Join-Path $OutputDir 'evidence-static-scan.json') ($evidence | ConvertTo-Json -Depth 8)
Write-AtomicText (Join-Path $OutputDir 'latest-report.md') $report
Write-Output "PASS static adapter output: $OutputDir (partial, read-only evidence recorded)"
