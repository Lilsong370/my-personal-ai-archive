# 把一段 AI 输出快速沉淀到今天的收件箱，并同步到 GitHub
# 用法：
#   .\capture.ps1 -Text "内容"                     # 直接写内容
#   .\capture.ps1 -Text "内容" -Tag claude          # 打标签
#   Get-Clipboard | .\capture.ps1 -Tag chatgpt      # 直接读剪贴板
#   .\capture.ps1 -Text "内容" -NoSync              # 只写文件，不推送
param(
    [Parameter(ValueFromPipeline = $true)]
    [string]$Text,

    [string]$Tag = "ai",

    [switch]$NoSync
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$InboxDir = Join-Path $RepoRoot "sync\inbox"

if (-not (Test-Path $InboxDir)) {
    New-Item -ItemType Directory -Path $InboxDir -Force | Out-Null
}

if (-not $Text) {
    $Text = Get-Clipboard -Raw
}
if (-not $Text -or $Text.Trim().Length -eq 0) {
    throw "没有内容可写入（-Text 为空，且剪贴板也是空的）"
}

$date = Get-Date -Format "yyyy-MM-dd"
$time = Get-Date -Format "HH:mm"
$file = Join-Path $InboxDir "$date.md"

if (-not (Test-Path $file)) {
    Set-Content -Path $file -Value "# $date · 收件箱`n" -Encoding utf8
}

$block = @"

## $time [$Tag]

$($Text.Trim())

"@

Add-Content -Path $file -Value $block -Encoding utf8
Write-Host "已写入：sync\inbox\$date.md" -ForegroundColor Cyan

if (-not $NoSync) {
    & (Join-Path $PSScriptRoot "sync.ps1") -Message "capture($Tag): $date $time"
}
