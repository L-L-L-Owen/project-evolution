param(
  [Parameter(Mandatory=$true)][string]$ProjectPath,
  [Parameter(Mandatory=$true)][ValidatePattern('^[a-z][a-z0-9-]{2,63}$')][string]$ProjectId,
  [Parameter(Mandatory=$true)][string]$OutputDir,
  [string]$BrowserSnapshotPath
)

if (-not (Test-Path $ProjectPath -PathType Container)) { throw "Project path not found: $ProjectPath" }
New-Item -ItemType Directory -Force $OutputDir | Out-Null
function Write-Atomic([string]$Path,[string]$Text){
  $tmp="$Path.tmp-$([guid]::NewGuid().ToString('N'))"
  try { [IO.File]::WriteAllText($tmp,$Text,(New-Object Text.UTF8Encoding($true))); if(Test-Path $Path){$bak="$Path.bak"; Copy-Item $Path $bak -Force; [IO.File]::Replace($tmp,$Path,$bak,$true)} else {Move-Item $tmp $Path -Force} }
  catch { if(Test-Path $tmp){Remove-Item $tmp -Force -ErrorAction SilentlyContinue}; throw "partial-write: $Path : $($_.Exception.Message)" }
}
function Read-Json([string]$Path){ if([string]::IsNullOrWhiteSpace($Path) -or -not(Test-Path $Path)){return $null}; try{return (Get-Content -Raw $Path | ConvertFrom-Json)}catch{return $null} }
$now=(Get-Date).ToUniversalTime().ToString('o')
$files=@(Get-ChildItem $ProjectPath -Recurse -File -ErrorAction SilentlyContinue | Where-Object {$_.FullName -notmatch '\\(node_modules|vendor|\.git|dist|build)\\'})
$relative=@($files | ForEach-Object {$_.FullName.Substring($ProjectPath.TrimEnd('\').Length).TrimStart('\')})
$htmlFiles=@($files | Where-Object {$_.Extension -eq '.html' -and $_.FullName -match '\\public\\' -and $_.Name -in @('index.html','index-layout-test.html')})
$fields=@(); $sensitiveFieldSeen=$false
foreach($f in $htmlFiles){
  $html=[IO.File]::ReadAllText($f.FullName)
  foreach($m in [regex]::Matches($html,'<label[^>]*for=["'']([^"'']+)["''][^>]*>(.*?)</label>',[Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [Text.RegularExpressions.RegexOptions]::Singleline)){
    $id=$m.Groups[1].Value; $label=([regex]::Replace($m.Groups[2].Value,'<[^>]+>','')).Trim()
    $sensitive=($id -match '(?i)password|pass|token|cookie|secret|api.?key' -or $label -match '密码|口令|令牌|密钥|cookie|token|secret')
    if($sensitive){$sensitiveFieldSeen=$true; continue}
    if($label){$fields += [pscustomobject]@{id=$id;label=$label;source=$f.FullName.Substring($ProjectPath.TrimEnd('\').Length).TrimStart('\');sensitive=$false}}
  }
}
$fields=@($fields | Group-Object id | ForEach-Object {$_.Group[0]})
if($sensitiveFieldSeen){$fields += [pscustomobject]@{id='sensitive-field';label='敏感输入';source='redacted';sensitive=$true}}

$jobs=@(); $jobPaths=@((Join-Path $ProjectPath 'data\jobs.json')) + @(Get-ChildItem (Join-Path $ProjectPath 'data\users') -Recurse -Filter jobs.json -ErrorAction SilentlyContinue | ForEach-Object FullName)
foreach($jp in $jobPaths){$data=Read-Json $jp; if($data){$jobs+=@($data)}}
function Latest($items){if(@($items).Count -eq 0){return $null}; return @($items | Sort-Object @{Expression={try{[datetime]$_.updatedAt}catch{[datetime]::MinValue}}} -Descending)[0]}
$active=Latest @($jobs | Where-Object {$_.status -in @('running','processing','in_progress','started')})
$pending=Latest @($jobs | Where-Object {$_.status -in @('queued','pending','waiting')})
$completed=Latest @($jobs | Where-Object {$_.status -in @('done','completed','success')})
$browser=Read-Json $BrowserSnapshotPath
$current=$null; $currentStatus='unknown'; $currentSource='none'; $currentId=$null
if($browser -and $browser.request){$current=$browser.request; $currentStatus=if($browser.status -in @('active','running')){'active'}else{'pending'}; $currentSource='browser_snapshot'; $currentId=$browser.jobId}
elseif($active){$current=$active.request; $currentStatus='active'; $currentSource='persisted_active_job'; $currentId=$active.id}
elseif($pending){$current=$pending.request; $currentStatus='pending'; $currentSource='persisted_pending_job'; $currentId=$pending.id}
elseif($completed){$current=$null; $currentStatus='unknown'; $currentSource='none'; $currentId=$null}

$leadSignals=(@($fields | Where-Object {$_.label -match '开发客户|产品关键词|目标人群|开发数量'}).Count -gt 0 -or @($relative | Where-Object {$_ -match 'website-page-parser|mail-center|storage\.js'}).Count -gt 0)
$purpose=@($(if($leadSignals){'根据用户需求开发 B2B 客户线索，兼顾数量、匹配度和可联系性'}))
$steps=@($(if($leadSignals){'填写开发需求','选择范围与来源','设置数量和质量条件','启动任务','查看筛选结果','验证联系方式并跟进'}))
$context=[ordered]@{
  projectId=$ProjectId; capturedAt=$now; purposeCandidates=$purpose; purposeStatus=$(if($leadSignals){'inferred_pending_user_decision'}else{'unknown'}); detectedFormFields=$fields; workflowSteps=$steps;
  latestCompletedJobId=$(if($completed){$completed.id}else{$null}); activeJobId=$(if($active){$active.id}else{$null}); pendingJobId=$(if($pending){$pending.id}else{$null});
  currentRequestStatus=$currentStatus; currentRequestSource=$currentSource; currentRequest=$current; latestCompletedRequest=$(if($completed){$completed.request}else{$null}); limits=@('只读取已落盘文件、静态页面和显式浏览器快照','敏感字段只记录存在，不保存名称和值','不读取密钥或 Cookie','不启动任务','未落盘的浏览器输入标记为 unknown')
}
$featureDefs=if($leadSignals){[ordered]@{requirement_input=@('productKeyword','websiteUrl','supportingFile','countriesMulti','peopleMulti','rolesMulti','quantity');quality_gates=@('minIntent','requiredContacts');source_selection=@('channels','socials');search_jobs=@('jobs.json','server.js','search');lead_results=@('leads.json','lead-card');contact_verification=@('contact-mining','email','phone');follow_up=@('followUps','customerStatus','mail-center')}}else{[ordered]@{frontend=@('src','app','pages','public');backend=@('api','server','routes');tests=@('tests','test','__tests__');docs=@('docs','README.md')}}
$evidenceId="evidence-context-scan-$ProjectId"; $features=@()
foreach($pair in $featureDefs.GetEnumerator()){
  $hits=@(); foreach($marker in $pair.Value){if((Test-Path (Join-Path $ProjectPath $marker)) -or @($relative | Where-Object {$_ -match [regex]::Escape($marker)}).Count -gt 0 -or @($fields | Where-Object {$_.id -eq $marker}).Count -gt 0){$hits+=$marker}}
  $exists=(@($hits).Count -gt 0); $jobIds=@(); if($pair.Key -eq 'search_jobs' -and $currentId){$jobIds=@($currentId)}
  $features += [ordered]@{featureId="feature-$($pair.Key)";name=$pair.Key;jobIds=$jobIds;exists=$(if($exists){'yes'}else{'unknown'});availability='not_verified';usability='not_verified';maturity='not_verified';evidenceRefs=@($evidenceId);referenceRefs=@();knownGaps=@($(if($exists){'静态或记录线索存在，仍需按真实任务验收'}else{'未识别到明确线索'}))}
}
$featureMap=[ordered]@{id="feature-map-$ProjectId";schemaVersion=1;projectId=$ProjectId;features=$features;createdAt=$now;updatedAt=$now}
$evidence=[ordered]@{id=$evidenceId;schemaVersion=1;projectId=$ProjectId;type='static_scan';source='adapter';capturedAt=$now;relatedJobIds=@($(if($currentId){$currentId}));relatedHypothesisIds=@();evidenceLevel='L0';artifactRefs=@('project-context.json','feature-map.json');repeatability='repeatable';participantType='none';dataClass='internal';confidence='medium';status='valid';createdAt=$now;updatedAt=$now}
$reviewRequest=if($current){$current}else{$null}
$reviewSource=if($current){$currentSource}elseif($completed){'latest_completed_job_baseline'}else{'none'}
$requestText=if($current){"已自动读取当前任务：状态=$currentStatus，来源=$currentSource，产品=$($current.productKeyword)，数量=$($current.quantity)。"}elseif($completed){"当前没有活动或待执行任务；已读取最近完成任务作为基线，来源=$reviewSource，产品=$($completed.request.productKeyword)，数量=$($completed.request.quantity)。它不会被标记为当前任务。"}else{'当前没有可确认的活动、待执行或已完成任务，任务状态记为 unknown。'}
$requestInput=if($current){'current-request.json'}elseif($completed){'latest-completed-request.json'}else{$null}
$researchInputs=@('project-context.json','feature-map.json')
if($requestInput){$researchInputs += $requestInput}
$report=@"
# 项目进化自动首轮报告

## 本轮结论
已自动读取项目上下文、页面表单、业务功能线索和任务记录。适配器状态为 **partial**，不代表真实用户验收通过。

## 当前任务
$requestText

## 自动识别的固定流程
$(($steps -join ' → '))

## 本轮主焦点
用户需求 → 线索匹配 → 质量验证 → 优先跟进，重点检查数量增长时质量是否同步保持。

## 已验证与未验证
- 已验证：上下文来源、任务状态、表单字段、业务功能候选和 L0 Evidence 已落盘。
- 未验证：真实用户体验、联系方式真实可达率、需求匹配率、重复率和最终跟进转化。

## 研究与改进边界
$(if($current){'本轮有明确当前任务：可以围绕该任务建立研究计划、机会和假设草稿；这些仍需用户决定后才能执行。'}elseif($completed){'本轮没有当前任务：最近完成任务只作为历史基线，不能当作当前需求结论；本轮不生成当前改进假设。'}else{'本轮没有任何任务：只完成项目上下文和功能线索整理，不生成任务型改进假设。'})

## 下一步用户只需决定
$(if($current){'是否接受本轮主焦点进入下一步研究或执行准备。'}else{'如需形成针对具体需求的改进建议，请先在项目中提交或保留一个活动/待执行任务；否则本轮仅作为初始化记录。'})
"@
$researchPlan=[ordered]@{projectId=$ProjectId;createdAt=$now;focus='提高符合需求且可联系的 B2B 客户线索比例';inputs=$researchInputs;sourceTracks=@('B2B lead qualification','data verification and deduplication','target-user workflow and usability');status=$(if($current){'ready_for_runtime_research'}else{'blocked_no_current_task'});baselineSource=$(if($current){$currentSource}elseif($completed){'latest_completed_job_baseline'}else{'none'})}
$opportunity=$null; $hypothesis=$null
if($reviewRequest -and $leadSignals){
  $oppId="opportunity-context-$ProjectId"; $hypId="hypothesis-context-$ProjectId"
  $opportunity=[ordered]@{id=$oppId;schemaVersion=1;projectId=$ProjectId;userProblem='结果数量达到目标时，真正符合本次需求且具备可联系信息的客户比例是否足够';unmetNeed='用户需要在较少人工筛选下优先看到可联系、匹配度高的客户';affectedJobs=@('job-develop-qualified-leads');purposeLink="purpose-$ProjectId";evidenceRefs=@($evidenceId);referenceRefs=@();expectedValue='high';costBand='unknown';complexityRisk='unknown';valueAssessment=$null;status='candidate';createdAt=$now;updatedAt=$now}
  $hypothesis=[ordered]@{id=$hypId;schemaVersion=1;projectId=$ProjectId;opportunityId=$oppId;statement='如果系统同时按需求匹配、联系方式完整性和来源可验证性排序，用户将更快选出值得跟进的客户';changeProposal='先建立当前任务的数量、匹配率、联系方式完整率、可验证率和选出可跟进客户耗时基线，再比较排序或筛选改进';affectedJobs=@('job-develop-qualified-leads');participantType='unknown';baseline=@{metrics=@(@{indicatorId='lead-fit-rate';value='unknown';unit='rate';collectionMethod='manual review';sampleDescription='当前任务结果';sampleSize=0;collectedAt=$now},@{indicatorId='lead-verifiability';value='unknown';unit='rate';collectionMethod='manual review';sampleDescription='当前任务结果';sampleSize=0;collectedAt=$now},@{indicatorId='lead-followup-selection-time';value='unknown';unit='minutes';collectionMethod='task observation';sampleDescription='一次真实用户任务';sampleSize=0;collectedAt=$now})};target=@{expectedChange='提高可联系且符合需求的结果比例，减少人工筛选时间';passCondition='同一任务下核心指标达到预先设定目标且无关键副作用';failCondition='匹配率或可验证率下降，或用户筛选时间明显增加'};observationWindow='下一次真实任务及改后复核';sideEffectsToCheck=@('结果数量不足','重复客户增加','联系方式误报');rollbackPlan='保留原排序和筛选口径，撤回未验证的改动';status='proposed';createdAt=$now;updatedAt=$now}
}
Write-Atomic (Join-Path $OutputDir 'project-context.json') ($context|ConvertTo-Json -Depth 14)
Write-Atomic (Join-Path $OutputDir 'feature-map.json') ($featureMap|ConvertTo-Json -Depth 14)
Write-Atomic (Join-Path $OutputDir 'evidence-context-scan.json') ($evidence|ConvertTo-Json -Depth 10)
Write-Atomic (Join-Path $OutputDir 'latest-report.md') $report
Write-Atomic (Join-Path $OutputDir 'research-plan.json') ($researchPlan|ConvertTo-Json -Depth 10)
if($current){Write-Atomic (Join-Path $OutputDir 'current-request.json') ($current|ConvertTo-Json -Depth 12)} else { if(Test-Path (Join-Path $OutputDir 'current-request.json')){Remove-Item (Join-Path $OutputDir 'current-request.json') -Force -ErrorAction SilentlyContinue} }
if($completed){Write-Atomic (Join-Path $OutputDir 'latest-completed-request.json') ($completed.request|ConvertTo-Json -Depth 12)} else { if(Test-Path (Join-Path $OutputDir 'latest-completed-request.json')){Remove-Item (Join-Path $OutputDir 'latest-completed-request.json') -Force -ErrorAction SilentlyContinue} }
if($opportunity){Write-Atomic (Join-Path $OutputDir 'opportunity-draft.json') ($opportunity|ConvertTo-Json -Depth 12)} elseif(Test-Path (Join-Path $OutputDir 'opportunity-draft.json')){Remove-Item (Join-Path $OutputDir 'opportunity-draft.json') -Force -ErrorAction SilentlyContinue}
if($hypothesis){Write-Atomic (Join-Path $OutputDir 'hypothesis-draft.json') ($hypothesis|ConvertTo-Json -Depth 16)} elseif(Test-Path (Join-Path $OutputDir 'hypothesis-draft.json')){Remove-Item (Join-Path $OutputDir 'hypothesis-draft.json') -Force -ErrorAction SilentlyContinue}
Write-Output "PASS project context and first review scaffold extracted: $OutputDir"
