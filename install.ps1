# MenuSlim one-line installer
# Installs the menuslim skill into the user's TRAE skill directory.
$ErrorActionPreference = 'Stop'

$skillDirs = @(
  "$env:USERPROFILE\.trae\skills\menuslim",
  "$env:USERPROFILE\.trae-cn\skills\menuslim"
)

$repo = 'https://raw.githubusercontent.com/TJCSGAO/menuslim/main/'
$files = @('SKILL.md', 'disable-context-menu.bat', 'restore-context-menu.bat')

$installed = $null
foreach ($dir in $skillDirs) {
  $parent = Split-Path $dir -Parent
  if (Test-Path $parent) { $installed = $dir; break }
}
if (-not $installed) { $installed = $skillDirs[0] }

New-Item -ItemType Directory -Force $installed | Out-Null
Write-Host "Installing menuslim to: $installed"

foreach ($f in $files) {
  $url = $repo + $f
  $dest = Join-Path $installed $f
  Write-Host "  Downloading $f ..."
  try {
    Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
  } catch {
    # Fallback to codeload zip in case raw is blocked
    Write-Warning "Direct download failed, falling back to GitHub codeload archive ..."
    $zip = "$env:TEMP\menuslim.zip"
    Invoke-WebRequest -Uri 'https://codeload.github.com/TJCSGAO/menuslim/zip/refs/heads/main' -OutFile $zip -UseBasicParsing
    Expand-Archive -Path $zip -DestinationPath "$env:TEMP\menuslim-extract" -Force
    Copy-Item "$env:TEMP\menuslim-extract\menuslim-main\$f" $dest -Force
    break
  }
}

Write-Host ''
Write-Host 'Done! menuslim installed.' -ForegroundColor Green
Write-Host "Next: open TRAE and say \"\u5e2e\u6211\u6e05\u7406\u53f3\u952e\u83dc\u5355\" to trigger the skill."
