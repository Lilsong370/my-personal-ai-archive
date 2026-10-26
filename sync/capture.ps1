# 把一段 AI 输出归档到 journal/，并同步到 GitHub
# 用法：
#   .\capture.ps1 -Text "内容"                       # 直接写内容
#   .\capture.ps1 -Text "内容" -Tag claude -Title "周报模板"
#   Get-Clipboard | .\capture.ps1 -Tag chatgpt       # 读剪贴板
#   .\capture.ps1 -Text "内容" -NoSync               # 只写文件，不推送
param(
    [Parameter(ValueFromPipeline = $true)]
    [string]$Text,

    [string]$Tag = "ai",

    [string]$Title = "",

    [switch]$NoSync
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$now = Get-Date

$dir = Join-Path $RepoRoot ("journal\" + $now.ToString("yyyy-MM"))
if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

if (-not $Text) {
    $Text = Get-Clipboard -Raw
}
if (-not $Text -or $Text.Trim().Length -eq 0) {
    throw "没有内容可写入（-Text 为空，且剪贴板也是空的）"
}

$file = Join-Path $dir ($now.ToString("yyyy-MM-dd") + ".md")
if (-not (Test-Path $file)) {
    Set-Content -Path $file -Value ("# " + $now.ToString("yyyy-MM-dd") + " · 对话记录`n") -Encoding utf8
}

$head = "## " + $now.ToString("HH:mm") + " · " + $Tag
if ($Title) { $head = $head + " · " + $Title }

$block = "`n" + $head + "`n`n" + $Text.Trim() + "`n"
Add-Content -Path $file -Value $block -Encoding utf8

Write-Host ("已写入 journal\" + $now.ToString("yyyy-MM") + "\" + $now.ToString("yyyy-MM-dd") + ".md") -ForegroundColor Cyan

if (-not $NoSync) {
    & (Join-Path $PSScriptRoot "sync.ps1") -Message ("archive(" + $Tag + "): " + $now.ToString("yyyy-MM-dd HH:mm"))
}
