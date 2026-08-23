# MenuSlim installer - works for TRAE / Codex / Claude Code / Cursor / Windsurf
# Usage:
#   irm https://raw.githubusercontent.com/TJCSGAO/menuslim/main/install.ps1 | iex
#   (auto-installs into every detected tool's skill directory)
# Or target a specific tool:
#   ./install.ps1 -Target codex
param(
  [ValidateSet('trae','codex','claude','cursor','windsurf','all')]
  [string]$Target = 'all'
)
$ErrorActionPreference = 'Stop'

# tool -> candidate skill directories (first existing parent wins)
$map = [ordered]@{
  trae     = @("$env:USERPROFILE\.trae\skills\menuslim", "$env:USERPROFILE\.trae-cn\skills\menuslim")
  codex    = @("$env:USERPROFILE\.codex\skills\menuslim")
  claude   = @("$env:USERPROFILE\.claude\skills\menuslim")
  cursor   = @("$env:USERPROFILE\.cursor\skills\menuslim")
  windsurf = @("$env:USERPROFILE\.windsurf\skills\menuslim")
}

$files = @('SKILL.md', 'disable-context-menu.bat', 'restore-context-menu.bat')

Write-Host 'Downloading menuslim files ...'
$src = @()
$needZip = $false
foreach ($f in $files) {
  $dest = Join-Path $env:TEMP "menuslim-$f"
  try {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/TJCSGAO/menuslim/main/$f" -OutFile $dest -UseBasicParsing
  } catch {
    $needZip = $true
  }
  $src += $dest
}
if ($needZip) {
  Write-Host '  raw.githubusercontent.com unreachable, falling back to codeload archive ...'
  $zip = "$env:TEMP\menuslim.zip"
  Invoke-WebRequest -Uri 'https://codeload.github.com/TJCSGAO/menuslim/zip/refs/heads/main' -OutFile $zip -UseBasicParsing
  Expand-Archive -Path $zip -DestinationPath "$env:TEMP\menuslim-extract" -Force
  for ($i = 0; $i -lt $files.Count; $i++) {
    if (-not (Test-Path $src[$i]) -or (Get-Item $src[$i]).Length -eq 0) {
      Copy-Item "$env:TEMP\menuslim-extract\menuslim-main\$($files[$i])" $src[$i] -Force
    }
  }
}

$targets = if ($Target -eq 'all') { @($map.Keys) } else { @($Target) }
$installedCount = 0

foreach ($t in $targets) {
  foreach ($dir in $map[$t]) {
    # auto mode: only install when the tool's config dir exists; explicit mode: always
    $toolRoot = Split-Path (Split-Path $dir -Parent) -Parent
    if ($Target -ne 'all' -or (Test-Path $toolRoot)) {
      New-Item -ItemType Directory -Force $dir | Out-Null
      for ($i = 0; $i -lt $files.Count; $i++) {
        Copy-Item $src[$i] (Join-Path $dir $files[$i]) -Force
      }
      Write-Host "  [ok] $t -> $dir" -ForegroundColor Green
      $installedCount++
      break
    }
  }
}

if ($installedCount -eq 0) {
  Write-Warning 'No tool skill directory detected. Run with -Target <trae|codex|claude|cursor|windsurf> to specify one.'
} else {
  Write-Host ""
  Write-Host "Done! menuslim installed to $installedCount location(s)."
  Write-Host 'Trigger it by asking your agent: 清理右键菜单 / 恢复右键扩展'
}
