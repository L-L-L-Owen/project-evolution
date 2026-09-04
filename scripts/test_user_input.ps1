$parser=Join-Path $PSScriptRoot 'parse_user_input.ps1'
function Parse([string]$text,[string]$state='awaiting-user-decision',[string]$scope=$null,[string]$review=$null) {
  $args=@('-NoProfile','-ExecutionPolicy','Bypass','-File',$parser,'-Text',$text,'-CurrentState',$state)
  if ($scope) {$args += @('-ExecutedScope',$scope)}; if ($review) {$args += @('-NextReviewAt',$review)}
  return (& powershell.exe @args | ConvertFrom-Json)
}
$a=Parse '我看到了'; if ($a.event -ne 'report_seen' -or -not $a.transitionAllowed) { throw 'report_seen parse failed' }
$b=Parse '我只改了一部分'; if (-not $b.needsScopeConfirmation -or $b.transitionAllowed -or $b.event -ne 'claim_partial_execution') { throw 'partial scope guard failed' }
$c=Parse '先不做'; if (-not $c.needsReviewDate -or $c.transitionAllowed -or $c.nextState -ne 'awaiting-user-decision') { throw 'defer review-date guard failed' }
$c2=Parse '先不做' 'awaiting-user-decision' $null '2026-09-10T00:00:00Z'; if (-not $c2.transitionAllowed -or $c2.nextState -ne 'deferred') { throw 'defer with review date failed' }
$d=Parse '改后确实有效' 'awaiting-user-decision'; if ($d.nextState -ne 'awaiting-user-decision' -or -not $d.requiresEvidence) { throw 'change-effective guard failed' }
$e=Parse '以后都作为通用规则' 'awaiting-user-decision'; if ($e.nextState -ne 'awaiting-user-decision' -or -not $e.requiresEvidence) { throw 'promotion guard failed' }
$f=Parse '同意执行'; if ($f.event -ne 'accept_for_execution' -or $f.nextState -ne 'approved-awaiting-execution') { throw 'accept parse failed' }
Write-Output 'PASS user input parser and transition guards'
