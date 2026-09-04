param(
  [Parameter(Mandatory=$true)][string]$Text,
  [ValidateSet('reported','awaiting-user-decision','approved-awaiting-execution','deferred','rejected','awaiting-more-evidence','change-candidate-detected','verifying','supported','failed','inconclusive','reopened')][string]$CurrentState='awaiting-user-decision',
  [string]$ExecutedScope,
  [string]$NextReviewAt
)

# 这里只做“事件识别”，不把一句自然语言当成已完成的事实。
$event='ambiguous_user_input'; $proposedNext=$CurrentState; $needsScope=$false; $needsReviewDate=$false; $requiresEvidence=$false; $confidence='low'; $rule='none'
$trimmed=$Text.Trim()
if ($trimmed -match '看到了|看过了|已阅') { $event='report_seen'; $confidence='high'; $rule='report_seen' }
elseif ($trimmed -match '先不做|以后再说|暂缓') { $event='defer'; $proposedNext='deferred'; $needsReviewDate=$true; $confidence='high'; $rule='defer' }
elseif ($trimmed -match '不适合|不要这个|拒绝') { $event='reject'; $proposedNext='rejected'; $confidence='high'; $rule='reject' }
elseif ($trimmed -match '改了一部分|处理了一部分|只改了') { $event='claim_partial_execution'; $needsScope=$true; $proposedNext='change-candidate-detected'; $requiresEvidence=$true; $confidence='high'; $rule='partial_execution' }
elseif ($trimmed -match '改好了|已经处理|完成修改') { $event='claim_executed'; $proposedNext='change-candidate-detected'; $requiresEvidence=$true; $confidence='high'; $rule='executed' }
elseif ($trimmed -match '更多依据|更多证据|再查一下') { $event='request_more_evidence'; $proposedNext='awaiting-more-evidence'; $confidence='high'; $rule='more_evidence' }
elseif ($trimmed -match '同意执行|接受执行|可以做|按这个做') { $event='accept_for_execution'; $proposedNext='approved-awaiting-execution'; $confidence='high'; $rule='accept_for_execution' }
elseif ($trimmed -match '确认问题存在') { $event='confirm_problem_exists'; $confidence='high'; $rule='problem_exists' }
elseif ($trimmed -match '值得试试|值得尝试') { $event='confirm_trial_worthwhile'; $confidence='high'; $rule='trial_worthwhile' }
elseif ($trimmed -match '改后.*有效|确实有效') { $event='confirm_change_effective'; $proposedNext='verifying'; $requiresEvidence=$true; $confidence='medium'; $rule='change_effective_claim' }
elseif ($trimmed -match '通用规则|以后都这样') { $event='approve_rule_promotion'; $requiresEvidence=$true; $confidence='medium'; $rule='rule_promotion_claim' }

$allowed = @{
  'report_seen'=@('awaiting-user-decision');
  'defer'=@('awaiting-user-decision','awaiting-more-evidence');
  'reject'=@('awaiting-user-decision','awaiting-more-evidence');
  'claim_partial_execution'=@('approved-awaiting-execution','awaiting-user-decision','deferred','reopened');
  'claim_executed'=@('approved-awaiting-execution','awaiting-user-decision','reopened');
  'request_more_evidence'=@('awaiting-user-decision','reported','reopened');
  'accept_for_execution'=@('awaiting-user-decision');
  'confirm_problem_exists'=@('awaiting-user-decision','reported');
  'confirm_trial_worthwhile'=@('awaiting-user-decision');
  'confirm_change_effective'=@('verifying','supported','inconclusive');
  'approve_rule_promotion'=@('supported')
}
$transitionAllowed = ($allowed.ContainsKey($event) -and $allowed[$event] -contains $CurrentState)
$reviewDateValid=$true
if ($event -eq 'defer') {
  if ([string]::IsNullOrWhiteSpace($NextReviewAt)) { $needsReviewDate=$true; $reviewDateValid=$false }
  else { try { [datetime]::Parse($NextReviewAt) | Out-Null } catch { $needsReviewDate=$true; $reviewDateValid=$false } }
}
if ($event -eq 'claim_partial_execution' -and [string]::IsNullOrWhiteSpace($ExecutedScope)) { $needsScope=$true }
if ($needsScope -or -not $reviewDateValid) { $transitionAllowed=$false }
if (-not $transitionAllowed) { $proposedNext=$CurrentState }
if ($event -eq 'approve_rule_promotion') { $proposedNext=$CurrentState; $requiresEvidence=$true }

[ordered]@{
  event=$event; originalText=$Text; parsedAt=(Get-Date).ToUniversalTime().ToString('o');
  currentState=$CurrentState; proposedNextState=$proposedNext; nextState=$proposedNext; transitionAllowed=$transitionAllowed;
  executedScope=if ([string]::IsNullOrWhiteSpace($ExecutedScope)) {$null} else {$ExecutedScope};
  nextReviewAt=if ([string]::IsNullOrWhiteSpace($NextReviewAt)) {$null} else {$NextReviewAt};
  needsScopeConfirmation=$needsScope; needsReviewDate=$needsReviewDate; reviewDateValid=$reviewDateValid; requiresEvidence=$requiresEvidence;
  confidence=$confidence; matchedRule=$rule; notes=if ($event -eq 'approve_rule_promotion') {'仅记录为待审核请求，不自动升级通用规则。'} else {$null}
} | ConvertTo-Json -Compress
