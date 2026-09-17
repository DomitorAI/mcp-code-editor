#Requires -Version 5.1
<#
SYNOPSIS: mcp-code-editor bootstrap — o linie de comanda, fara installer.
USAGE:
  irm https://raw.githubusercontent.com/DomitorAI/mcp-code-editor/main/scripts/bootstrap.ps1 | iex
  powershell -File scripts/bootstrap.ps1 [-Version 1.0.0] [-ExeUrl <zip>] [-CloudflaredUrl <url>]
#>
[CmdletBinding()]
param(
  [string]$Version = '1.0.0',
  [string]$ExeUrl = '',
  [string]$CloudflaredUrl = ''
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

if ($PSVersionTable.PSVersion.Major -lt 6) {
  [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
}

$repo     = 'DomitorAI/mcp-code-editor'
$appDir   = Join-Path $env:LOCALAPPDATA 'mcp-code-editor'
$exeName  = 'McpCodeEditor.Desktop.exe'
$exePath  = Join-Path $appDir $exeName
$cloudDir = Join-Path $env:LOCALAPPDATA 'cloudflared'
$cloudExe = Join-Path $cloudDir 'cloudflared.exe'
$lnkPath  = Join-Path ([Environment]::GetFolderPath('Desktop')) 'mcp-code-editor.lnk'

if ([string]::IsNullOrWhiteSpace($ExeUrl)) {
  $ExeUrl = "https://github.com/$repo/releases/download/v$Version/mcp-code-editor-win-x64.zip"
}
if ([string]::IsNullOrWhiteSpace($CloudflaredUrl)) {
  $CloudflaredUrl = 'https://github.com/cloudflare/cloudflared/releases/download/2026.9.1/cloudflared-windows-amd64.exe'
}

function Write-Step([string]$msg) {
  Write-Host "mcp-code-editor: $msg"
}

function Resolve-Source([string]$url) {
  if (Test-Path -LiteralPath $url) {
    return (Resolve-Path -LiteralPath $url).Path
  }
  return $url
}

function Save-File([string]$source, [string]$dest) {
  $source = Resolve-Source $source
  if ($source -notmatch '^https?://') {
    Copy-Item -LiteralPath $source -Destination $dest
    return
  }
  $wc = [System.Net.WebClient]::new()
  $wc.DownloadFile($source, $dest)
  $wc.Dispose()
}

if (-not (Test-Path -LiteralPath $appDir)) {
  New-Item -ItemType Directory -Path $appDir | Out-Null
  Write-Step "install dir: $appDir"
}

if (Test-Path -LiteralPath $exePath) {
  Write-Step "exe already present (skipping download): $exePath"
}
else {
  $zip = Join-Path $env:TEMP "mcp-code-editor-$Version.zip"
  Write-Step "downloading exe: $ExeUrl"
  Save-File $ExeUrl $zip
  $extract = Join-Path $env:TEMP "mcp-code-editor-$Version"
  if (Test-Path -LiteralPath $extract) {
    Remove-Item -LiteralPath $extract -Recurse -Force
  }
  Expand-Archive -Path $zip -DestinationPath $extract
  $found = Get-ChildItem -Path $extract -Filter $exeName -Recurse | Select-Object -First 1
  if (-not $found) {
    Remove-Item -LiteralPath $zip -Force
    throw "arhiva nu contine $exeName"
  }
  Copy-Item -Path (Join-Path $extract '*') -Destination $appDir -Recurse
  Remove-Item -LiteralPath $zip -Force
  Write-Step "exe installed: $exePath"
}

$cloudOnPath = Get-Command cloudflared -ErrorAction SilentlyContinue
if ($cloudOnPath -or (Test-Path -LiteralPath $cloudExe)) {
  Write-Step 'cloudflared already present (skipping download)'
}
else {
  if (-not (Test-Path -LiteralPath $cloudDir)) {
    New-Item -ItemType Directory -Path $cloudDir | Out-Null
  }
  Write-Step "downloading cloudflared: $CloudflaredUrl"
  Save-File $CloudflaredUrl $cloudExe
  Write-Step "cloudflared installed: $cloudExe"
}

$ws = New-Object -ComObject WScript.Shell
$sc = $ws.CreateShortcut($lnkPath)
$sc.TargetPath = $exePath
$sc.WorkingDirectory = $appDir
$sc.IconLocation = "$exePath,0"
$sc.Description = 'mcp-code-editor'
$sc.Save()
Write-Step "desktop shortcut: $lnkPath"

$CounterUrl = ''
if (-not [string]::IsNullOrWhiteSpace($CounterUrl)) {
  try { Invoke-WebRequest -Uri $CounterUrl -Method POST -UseBasicParsing -TimeoutSec 5 | Out-Null } catch { }
}

Write-Host ''
Write-Host 'Gata - icon-ul mcp-code-editor e pe Desktop. Dublu-click pentru pornire.' -ForegroundColor Green
