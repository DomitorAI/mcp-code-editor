#Requires -Version 5.1
<#
SYNOPSIS: mcp-code-editor uninstall - removes the app, the config, the shortcut and the temp files.
USAGE:
  irm https://raw.githubusercontent.com/DomitorAI/mcp-code-editor/main/scripts/uninstall.ps1 | iex
  powershell -File scripts/uninstall.ps1
#>
$ErrorActionPreference = 'Stop'

$appDir  = Join-Path $env:LOCALAPPDATA 'mcp-code-editor'
$lnkPath = Join-Path ([Environment]::GetFolderPath('Desktop')) 'mcp-code-editor.lnk'

function Write-Step([string]$msg) {
  Write-Host "mcp-code-editor: $msg"
}

$failed = $false

if (Test-Path -LiteralPath $appDir) {
  try {
    Remove-Item -LiteralPath $appDir -Recurse -Force
    Write-Step "removed: $appDir"
  }
  catch {
    Write-Host "mcp-code-editor: could not remove $appDir (locked file?). Close the app and rerun the script." -ForegroundColor Red
    $failed = $true
  }
}
else {
  Write-Step "app dir not found (skipping): $appDir"
}

if (Test-Path -LiteralPath $lnkPath) {
  Remove-Item -LiteralPath $lnkPath -Force
  Write-Step "removed: $lnkPath"
}
else {
  Write-Step "shortcut not found (skipping): $lnkPath"
}

$temps = Get-ChildItem -Path $env:TEMP -Filter 'mcp-code-editor-*' -Force -ErrorAction SilentlyContinue
if ($temps) {
  foreach ($t in $temps) {
    Remove-Item -LiteralPath $t.FullName -Recurse -Force
    Write-Step "removed: $($t.FullName)"
  }
}
else {
  Write-Step 'temp files not found (skipping)'
}

if ($failed) {
  exit 1
}

Write-Host ''
Write-Host 'Done - the app, the config and the shortcut have been removed. cloudflared was kept.' -ForegroundColor Green
