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
    exit 0
}

Write-Host "将提交以下文件：" -ForegroundColor Cyan
$staged | ForEach-Object { Write-Host "  $_" }

if ($DryRun) {
    Write-Host "DryRun：未提交。" -ForegroundColor Yellow
    exit 0
}

git commit -m $Message | Out-Null
git pull --rebase --autostash
git push
Write-Host "已同步：$Message" -ForegroundColor Green
