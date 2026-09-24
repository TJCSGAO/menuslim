<#
  MenuSlim-Plus - block context menu handlers at USER level (no admin needed)

  Example:
    .\block-handlers.ps1 -ClassicMenu -RestartExplorer
    .\block-handlers.ps1 -Clsids @('{12345678-....}') `
        -HideStaticVerbs @('Software\Classes\Directory\shell\ExampleVerb') `
        -RestartExplorer
#>
param(
    [string[]]$Clsids = @(),
    [string[]]$HideStaticVerbs = @(),
    [switch]$ClassicMenu,
    [switch]$RestartExplorer
)
$ErrorActionPreference = 'Stop'
$cu = [Microsoft.Win32.Registry]::CurrentUser

# 1. Restore the Windows 10-style full (classic) context menu on Win11.
# MUST use reg.exe with /ve: .NET SetValue('','') does NOT persist an empty default.
if ($ClassicMenu) {
    & reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve | Out-Null
    Write-Output '[OK] classic full context menu enabled'
}

# 2. Block COM shell extension handlers via the official user blocklist.
if ($Clsids.Count -gt 0) {
    $blk = $cu.CreateSubKey('Software\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked')
    $added = 0
    foreach ($c in $Clsids) {
        $c = $c.Trim()
        if ($c -match '^\{[0-9a-fA-F\-]+\}$') {
            $blk.SetValue($c, '', [Microsoft.Win32.RegistryValueKind]::String)
            $added++
        } else {
            Write-Warning "Skipped (not a CLSID): $c"
        }
    }
    $blk.Close()
    Write-Output "[OK] $added handler CLSID(s) blocked (user level)"
}

# 3. Hide static (non-COM) verb entries via ProgrammaticAccessOnly.
# Pass full HKCU-relative paths, e.g. 'Software\Classes\Directory\shell\SomeVerb'.
if ($HideStaticVerbs.Count -gt 0) {
    foreach ($rp in $HideStaticVerbs) {
        $rp = $rp.Trim().TrimStart('\')
        $sk = $cu.CreateSubKey($rp)
        $sk.SetValue('ProgrammaticAccessOnly', '', [Microsoft.Win32.RegistryValueKind]::String)
        $sk.Close()
        Write-Output "[OK] static verb hidden: $rp"
    }
}

# 4. Restart Explorer so everything takes effect.
if ($RestartExplorer) {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
    Write-Output '[OK] Explorer restarted'
}
