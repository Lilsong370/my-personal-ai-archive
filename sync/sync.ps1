# 一键提交并推送本仓库的变更
# 用法：
#   .\sync.ps1                       # 默认提交信息
#   .\sync.ps1 -Message "补充:周报"  # 自定义提交信息
#   .\sync.ps1 -DryRun               # 只看会提交什么
param(
    [string]$Message = "",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

# 定时任务里没有交互窗口：凭据缺失时立刻失败，而不是弹窗卡住
$env:GIT_TERMINAL_PROMPT = "0"

# 定时继承的环境变量可能是旧的，兜底找一次 git.exe
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    foreach ($c in @(
        "C:\Program Files\Git\cmd\git.exe",
        "C:\Program Files (x86)\Git\cmd\git.exe",
        (Join-Path $env:LOCALAPPDATA "Programs\Git\cmd\git.exe")
    )) {
        if (Test-Path $c) {
            $env:PATH = (Split-Path $c) + ";" + $env:PATH
            break
        }
    }
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "找不到 git.exe，请先安装 Git for Windows"
}

$LogDir = Join-Path $env:LOCALAPPDATA "PersonalAIArchive"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }
$LogFile = Join-Path $LogDir "sync.log"

function Write-Log([string]$Level, [string]$Text) {
    $line = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Text
    Add-Content -Path $LogFile -Value $line -Encoding utf8
}

# git 往 stderr 写进度是常态，不能让 $ErrorActionPreference=Stop 把它当成异常
function Invoke-Git([string[]]$GitArgs) {
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $out = & git @GitArgs 2>&1 | Out-String
    $code = $LASTEXITCODE
    $ErrorActionPreference = $prev
    return [pscustomobject]@{ Code = $code; Output = $out.Trim() }
}

try {
    if (-not (Test-Path (Join-Path $RepoRoot ".git"))) {
        throw "当前位置不是 Git 仓库：$RepoRoot"
    }

    if (-not $Message) {
        $Message = "chore: sync " + (Get-Date -Format "yyyy-MM-dd HH:mm")
    }

    $r = Invoke-Git @("add", "-A")
    if ($r.Code -ne 0) { throw "git add 失败：$($r.Output)" }

    $r = Invoke-Git @("diff", "--cached", "--name-only")
    if ($r.Code -ne 0) { throw "git diff 失败：$($r.Output)" }

    $staged = @($r.Output -split "`r?`n" | Where-Object { $_.Trim() })
    if ($staged.Count -eq 0) {
        Write-Host "没有变更，跳过同步。" -ForegroundColor DarkGray
        Write-Log "INFO" "无变更"
        exit 0
    }

    Write-Host "将提交 $($staged.Count) 个文件：" -ForegroundColor Cyan
    $staged | ForEach-Object { Write-Host "  $_" }

    if ($DryRun) {
        Write-Host "DryRun：未提交。" -ForegroundColor Yellow
        exit 0
    }

    $r = Invoke-Git @("commit", "-m", $Message)
    if ($r.Code -ne 0) { throw "git commit 失败：$($r.Output)" }

    $pull = Invoke-Git @("pull", "--rebase", "--autostash")
    if ($pull.Code -ne 0) { Write-Log "WARN" "git pull 失败（继续尝试推送）：$($pull.Output)" }

    $push = Invoke-Git @("push")
    if ($push.Code -ne 0) {
        throw "git push 失败：$($push.Output)"
    }

    Write-Host "已同步：$Message" -ForegroundColor Green
    Write-Log "OK" "$Message（$($staged.Count) 个文件）"
}
catch {
    Write-Host "同步失败：$($_.Exception.Message)" -ForegroundColor Red
    Write-Log "ERROR" $_.Exception.Message
    exit 1
}
