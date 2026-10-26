# 一键提交并推送本仓库的变更
# 用法：
#   .\sync.ps1                      # 用默认提交信息
#   .\sync.ps1 -Message "补充:周报" # 自定义提交信息
#   .\sync.ps1 -DryRun              # 只看会提交什么，不实际提交
param(
    [string]$Message = "",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

# 定时任务里没有交互窗口：凭据缺失时立刻失败，而不是弹窗卡死
$env:GIT_TERMINAL_PROMPT = "0"

$LogDir = Join-Path $env:LOCALAPPDATA "PersonalAIArchive"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }
$LogFile = Join-Path $LogDir "sync.log"

function Write-Log([string]$Level, [string]$Text) {
    $line = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Text
    Add-Content -Path $LogFile -Value $line -Encoding utf8
}

try {
    if (-not (Test-Path (Join-Path $RepoRoot ".git"))) {
        throw "当前位置不是 Git 仓库：$RepoRoot（先确认已 git clone 并 cd 进仓库）"
    }

    if (-not $Message) {
        $Message = "chore: sync " + (Get-Date -Format "yyyy-MM-dd HH:mm")
    }

    git add -A

    $staged = git diff --cached --name-only
    if (-not $staged) {
        Write-Host "没有变更，跳过同步。" -ForegroundColor DarkGray
        Write-Log "INFO" "无变更"
        exit 0
    }

    $count = ($staged | Measure-Object).Count
    Write-Host "将提交 $count 个文件：" -ForegroundColor Cyan
    $staged | ForEach-Object { Write-Host "  $_" }

    if ($DryRun) {
        Write-Host "DryRun：未提交。" -ForegroundColor Yellow
        exit 0
    }

    git commit -m $Message | Out-Null
    git pull --rebase --autostash 2>&1 | Out-Null

    $pushOut = git push 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "git push 失败：$pushOut"
    }

    Write-Host "已同步：$Message" -ForegroundColor Green
    Write-Log "OK" "$Message（$count 个文件）"
}
catch {
    Write-Host "同步失败：$($_.Exception.Message)" -ForegroundColor Red
    Write-Log "ERROR" $_.Exception.Message
    exit 1
}
