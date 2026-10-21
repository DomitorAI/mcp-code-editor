#Requires -Version 5.1
<#
SYNOPSIS: mcp-code-editor bootstrap - one command line, no installer.
USAGE:
  irm https://raw.githubusercontent.com/DomitorAI/mcp-code-editor/main/scripts/bootstrap.ps1 | iex
  powershell -File scripts/bootstrap.ps1 [-ExeUrl <zip>] [-CloudflaredUrl <url>]
#>
[CmdletBinding()]
param(
  [string]$ExeUrl = '',
  [string]$CloudflaredUrl = ''
)

$ErrorActionPreference = 'Stop'

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
  $ExeUrl = "https://github.com/$repo/releases/latest/download/mcp-code-editor-win-x64.zip"
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

function Save-File([string]$source, [string]$dest, [string]$label) {
  $source = Resolve-Source $source
  if ($source -notmatch '^https?://') {
    Write-Step "$label - copying $source"
    Copy-Item -LiteralPath $source -Destination $dest -Force
    return
  }
  Write-Step "$label - downloading $source"
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  $total = [long]0
  $read = [long]0
  $resp = $null
  $in = $null
  $out = $null
  try {
    $req = [System.Net.HttpWebRequest]::Create($source)
    $req.Timeout = 1800000
    $resp = $req.GetResponse()
    $total = [long]$resp.ContentLength
    $in = $resp.GetResponseStream()
    $out = [IO.File]::Create($dest)
    $buf = New-Object byte[] 65536
    while (($n = $in.Read($buf, 0, $buf.Length)) -gt 0) {
      $out.Write($buf, 0, $n)
      $read += $n
      if ($total -gt 0) {
        Write-Progress -Activity $label -Status ('{0:N1} / {1:N1} MB' -f ($read / 1MB), ($total / 1MB)) -PercentComplete (($read / $total) * 100)
      }
      else {
        Write-Progress -Activity $label -Status ('{0:N1} MB' -f ($read / 1MB))
      }
    }
  }
  catch {
    Remove-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue
    Write-Host 'mcp-code-editor: download failed - check the internet connection and rerun the command.' -ForegroundColor Red
    throw
  }
  finally {
    if ($null -ne $out) { $out.Dispose() }
    if ($null -ne $in) { $in.Dispose() }
    if ($null -ne $resp) { $resp.Close() }
    Write-Progress -Activity $label -Completed
  }
  $sw.Stop()
  Write-Step ('{0} - downloaded {1:N1} MB in {2} s' -f $label, ($read / 1MB), [int]$sw.Elapsed.TotalSeconds)
}

if (-not (Test-Path -LiteralPath $appDir)) {
  New-Item -ItemType Directory -Path $appDir | Out-Null
  Write-Step "install dir: $appDir"
}

if (Test-Path -LiteralPath $exePath) {
  Write-Step "exe already present (skipping download): $exePath"
}
else {
  $zip = Join-Path $env:TEMP 'mcp-code-editor-latest.zip'
  Save-File $ExeUrl $zip 'mcp-code-editor zip'
  $extract = Join-Path $env:TEMP 'mcp-code-editor-latest'
  if (Test-Path -LiteralPath $extract) {
    Remove-Item -LiteralPath $extract -Recurse -Force
  }
  Write-Step 'extracting archive'
  Expand-Archive -Path $zip -DestinationPath $extract
  $found = Get-ChildItem -Path $extract -Filter $exeName -Recurse | Select-Object -First 1
  if (-not $found) {
    Remove-Item -LiteralPath $zip -Force
    throw "archive does not contain $exeName"
  }
  Write-Step "installing to $appDir"
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
  Save-File $CloudflaredUrl $cloudExe 'cloudflared'
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
Write-Host 'Done - the mcp-code-editor icon is on the Desktop. Double-click to start.' -ForegroundColor Green
