<#
  考研冲刺看板 · kaoyan/tools/dashboard.ps1

  作用：算倒计时 / 连续达标天数 / 近 N 日各科时长 / 欠账日 / 下一个里程碑。
  用法：
    pwsh -File kaoyan/tools/dashboard.ps1
    pwsh -File kaoyan/tools/dashboard.ps1 -RecentDays 14
    pwsh -File kaoyan/tools/dashboard.ps1 -Root D:\deepseek_dsh -ExamDate 2026-12-19

  依赖：kaoyan/logs/<YYYY-MM-DD>.md 中的 [机器可读] 块（key=value 行）。
  数据缺失不会报错，只会显示 0 / 缺。
#>
[CmdletBinding()]
param(
  [string]$ExamDate = '2026-12-19',
  [int]$RecentDays = 7,
  [double]$MinHoursForStreak = 6,
  [string]$Root
)

$ErrorActionPreference = 'Continue'
$inv = [System.Globalization.CultureInfo]::InvariantCulture
$style = [System.Globalization.DateTimeStyles]::None

if (-not $Root) {
  $here = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
  $Root = Split-Path -Parent (Split-Path -Parent $here)
}
$LogsDir = Join-Path $Root 'kaoyan\logs'
$StateFile = Join-Path $Root 'kaoyan\state\state.yaml'

function Parse-Date([string]$s) {
  $d = [datetime]::MinValue
  if ([datetime]::TryParseExact($s, 'yyyy-MM-dd', $inv, $style, [ref]$d)) { return $d.Date }
  return $null
}

# ---------- 读取日志 ----------
$logs = @()
if (Test-Path -LiteralPath $LogsDir) {
  Get-ChildItem -LiteralPath $LogsDir -Filter '20*.md' -File -ErrorAction SilentlyContinue | ForEach-Object {
    $text = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
    if (-not $text) { return }
    $map = @{}
    foreach ($m in [regex]::Matches($text, '(?m)^([a-z0-9_]+)=(.+)$')) {
      $map[$m.Groups[1].Value] = $m.Groups[2].Value.Trim()
    }
    if (-not $map.ContainsKey('date')) { return }
    $d = Parse-Date $map['date']
    if (-not $d) { return }
    $num = { param($k) $v = 0.0; if ($map.ContainsKey($k)) { [void][double]::TryParse($map[$k], [ref]$v) }; return $v }
    $logs += [pscustomobject]@{
      Date        = $d
      Hours       = & $num 'hours'
      Math        = [int](& $num 'math_min')
      Cs408       = [int](& $num 'cs408_min')
      English     = [int](& $num 'english_min')
      Politics    = [int](& $num 'politics_min')
      Mood        = [int](& $num 'mood')
      SleepHours  = & $num 'sleep_hours'
      SleepAt     = if ($map.ContainsKey('sleep_at')) { $map['sleep_at'] } else { '' }
      Checkin     = if ($map.ContainsKey('checkin')) { $map['checkin'] } else { '?' }
      MathDeliver = if ($map.ContainsKey('math_deliver')) { $map['math_deliver'] } else { '' }
      CsDeliver   = if ($map.ContainsKey('cs408_deliver')) { $map['cs408_deliver'] } else { '' }
    }
  }
}

$today = (Get-Date).Date
$exam = Parse-Date $ExamDate
if (-not $exam) { Write-Output "[错误] 无法解析考试日期：$ExamDate"; exit 1 }
$daysLeft = ($exam - $today).Days
$studyDaysLeft = ($exam.AddDays(-1) - $today).Days

# ---------- 里程碑 ----------
$nextMilestone = '（未找到）'
if (Test-Path -LiteralPath $StateFile) {
  $stateText = Get-Content -LiteralPath $StateFile -Raw -Encoding UTF8
  $cands = @()
  # 新格式：   M4 2026-10-28: 说明
  foreach ($m in [regex]::Matches($stateText, '(?m)^\s*(M\d+)\s+(\d{4}-\d{2}-\d{2})')) {
    $dd = Parse-Date $m.Groups[2].Value
    if ($dd) { $cands += [pscustomobject]@{ Id = $m.Groups[1].Value; Due = $dd } }
  }
  # 旧格式兼容：  M4: { due: 2026-10-28, status: pending }
  foreach ($m in [regex]::Matches($stateText, '(?m)^\s*(M\d+):\s*\{\s*due:\s*(\d{4}-\d{2}-\d{2}),\s*status:\s*pending')) {
    $dd = Parse-Date $m.Groups[2].Value
    if ($dd) { $cands += [pscustomobject]@{ Id = $m.Groups[1].Value; Due = $dd } }
  }
  if ($cands.Count -gt 0) {
    $pick = $cands | Sort-Object Due | Select-Object -First 1
    $nextMilestone = "$($pick.Id) @ $($pick.Due.ToString('yyyy-MM-dd'))（还剩 $(($pick.Due - $today).Days) 天）"
  }
}

# ---------- 硬截止（报名/确认，逾期不补办） ----------
$nextDeadline = '（未找到）'
if ($stateText) {
  $dl = @()
  foreach ($m in [regex]::Matches($stateText, '(?m)^\s{2}(pre_register|register):\s*\{\s*start:\s*(\d{4}-\d{2}-\d{2})')) {
    $dd = Parse-Date $m.Groups[2].Value
    if ($dd) {
      $nm = if ($m.Groups[1].Value -eq 'pre_register') { '预报名开始' } else { '正式报名开始' }
      $dl += [pscustomobject]@{ Name = $nm; Date = $dd }
    }
  }
  # 新格式：  meta 下的 ticket: 2026-12-09
  foreach ($m in [regex]::Matches($stateText, '(?m)^\s*ticket:\s*(\d{4}-\d{2}-\d{2})')) {
    $dd = Parse-Date $m.Groups[1].Value
    if ($dd) { $dl += [pscustomobject]@{ Name = '准考证下载（约）'; Date = $dd } }
  }
  $future = @($dl | Where-Object { $_.Date -ge $today } | Sort-Object Date)
  if ($future.Count -gt 0) {
    $pk = $future[0]
    $nextDeadline = "$($pk.Name) @ $($pk.Date.ToString('yyyy-MM-dd'))（还剩 $(($pk.Date - $today).Days) 天，逾期不补办）"
  } elseif ($dl.Count -gt 0) {
    $nextDeadline = '报名节点已全部过去'
  }
}

# ---------- 统计 ----------
$windowStart = $today.AddDays(-1 * ($RecentDays - 1))
$recent = @($logs | Where-Object { $_.Date -ge $windowStart -and $_.Date -le $today } | Sort-Object Date)
$sumHours = ($recent | Measure-Object -Property Hours -Sum).Sum
if (-not $sumHours) { $sumHours = 0 }
$avgHours = if ($recent.Count -gt 0) { [math]::Round($sumHours / $RecentDays, 1) } else { 0 }
$sumMath = [int](($recent | Measure-Object -Property Math -Sum).Sum)
$sumCs = [int](($recent | Measure-Object -Property Cs408 -Sum).Sum)
$sumEn = [int](($recent | Measure-Object -Property English -Sum).Sum)
$sumPo = [int](($recent | Measure-Object -Property Politics -Sum).Sum)

# 连续达标天数
$streak = 0
$cursor = $today
if (-not ($logs | Where-Object { $_.Date -eq $today })) { $cursor = $today.AddDays(-1) }
while ($true) {
  $entry = $logs | Where-Object { $_.Date -eq $cursor } | Select-Object -First 1
  if ($entry -and $entry.Hours -ge $MinHoursForStreak) { $streak++; $cursor = $cursor.AddDays(-1) } else { break }
}

# 近 14 日缺勤
$gaps = @()
for ($i = 0; $i -lt 14; $i++) {
  $dd = $today.AddDays(-1 * $i)
  if (-not ($logs | Where-Object { $_.Date -eq $dd })) { $gaps += $dd.ToString('MM-dd') }
}

# ---------- 输出 ----------
$line = '=' * 62
Write-Output $line
Write-Output '  408 百日冲刺看板'
Write-Output $line
Write-Output ("今天        {0} {1}" -f $today.ToString('yyyy-MM-dd'), $today.ToString('dddd'))
Write-Output ("考试        {0}（12/19 政治+英语 · 12/20 数学+408）" -f $exam.ToString('yyyy-MM-dd'))
Write-Output ("倒计时      D-{0}   有效学习日 {1} 天" -f $daysLeft, $studyDaysLeft)
Write-Output ("下一里程碑  {0}" -f $nextMilestone)
Write-Output ("下一硬截止  {0}" -f $nextDeadline)
Write-Output ("日志总数    {0} 篇   最近 {1} 日平均 {2} h/天" -f $logs.Count, $RecentDays, $avgHours)

Write-Output ''
Write-Output ("-- 最近 {0} 日各科累计（分钟）--" -f $RecentDays)
Write-Output ("数学 {0,5}  (目标 {1})   408 {2,5}  (目标 {3})" -f $sumMath, ($RecentDays * 180), $sumCs, ($RecentDays * 180))
Write-Output ("英语 {0,5}  (目标 {1})   政治 {2,5}  (目标 {3})" -f $sumEn, ($RecentDays * 45), $sumPo, ($RecentDays * 30))

Write-Output ''
Write-Output ("-- 今日（{0}）--" -f $today.ToString('yyyy-MM-dd'))
$t = $logs | Where-Object { $_.Date -eq $today } | Select-Object -First 1
if ($t) {
  $mk = if ($t.Math -ge 180) { 'OK ' } else { 'NG ' }
  $ck = if ($t.Cs408 -ge 180) { 'OK ' } else { 'NG ' }
  $ek = if ($t.English -ge 45) { 'OK ' } else { 'NG ' }
  $pk = if ($t.Politics -ge 30) { 'OK ' } else { 'NG ' }
  Write-Output ("  {0}数学 {1,4} min   数学目标 180" -f $mk, $t.Math)
  Write-Output ("  {0}408  {1,4} min   408 目标 180" -f $ck, $t.Cs408)
  Write-Output ("  {0}英语 {1,4} min   英语目标 45" -f $ek, $t.English)
  Write-Output ("  {0}政治 {1,4} min   政治目标 30" -f $pk, $t.Politics)
  Write-Output ("  总时长 {0} h   心情 {1}/10   checkin={2}" -f $t.Hours, $t.Mood, $t.Checkin)
  $sk = if ($t.SleepHours -ge 7) { 'OK ' } else { 'NG ' }
  Write-Output ("  {0}昨夜睡眠 {1} h（入睡 {2}）  目标 ≥7 h / 22:30 上床" -f $sk, $t.SleepHours, $t.SleepAt)
  Write-Output ("  数学交付：{0}" -f $t.MathDeliver)
  Write-Output ("  408 交付：{0}" -f $t.CsDeliver)
} else {
  Write-Output '  今天还没有日志 —— 21:30 记得落盘。'
}

Write-Output ''
$recentSleep = @($recent | Where-Object { $_.SleepHours -gt 0 })
if ($recentSleep.Count -gt 0) {
  $avgSleep = [math]::Round((($recentSleep | Measure-Object -Property SleepHours -Average).Average), 1)
  $lateNights = 0
  foreach ($s in $recentSleep) {
    if ($s.SleepAt -ne '') {
      $p = $s.SleepAt.Split(':')
      $t = [int]$p[0] * 60 + [int]$p[1]
      if ($t -lt 1320) { $t += 1440 }   # 22:00 之前入睡 → 归到次日
      if ($t -gt 1470) { $lateNights++ }  # 晚于 00:30
    }
  }
  Write-Output ("-- 近 {0} 日平均睡眠 {1} h；入睡晚于 00:30 的天数：{2} --" -f $RecentDays, $avgSleep, $lateNights)
}
Write-Output ("-- 连续达标 {0} 天（阈值 {1} h）--" -f $streak, $MinHoursForStreak)
if ($gaps.Count -gt 0) {
  Write-Output ("-- 近 14 日缺勤 {0} 天：{1}" -f $gaps.Count, ($gaps -join ', '))
} else {
  Write-Output '-- 近 14 日无缺勤，保持。'
}
Write-Output $line
