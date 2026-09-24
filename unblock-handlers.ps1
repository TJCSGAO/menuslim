<#
  MenuSlim-Plus - undo changes made by block-handlers.ps1 (user level)

  Pass the SAME arguments you used to block, plus the undo switches.
  Example:
    .\unblock-handlers.ps1 -RemoveClassicMenu -Clsids @('{12345678-....}') `
        -HideStaticVerbs @('Software\Classes\Directory\shell\ExampleVerb') `
        -RestartExplorer
#>
param(
    [string[]]$Clsids = @(),
    [string[]]$HideStaticVerbs = @(),
    [switch]$RemoveClassicMenu,
    [switch]$RestartExplorer
)
$ErrorActionPreference = 'Continue'
$cu = [Microsoft.Win32.Registry]::CurrentUser

# 1. Remove CLSID values from the user blocklist.
if ($Clsids.Count -gt 0) {
    $blk = $cu.OpenSubKey('Software\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked', $true)
    if ($blk) {
        foreach ($c in $Clsids) {
            $c = $c.Trim()
            if ($blk.GetValueNames() -contains $c) { $blk.DeleteValue($c, $false); Write-Output "[OK] unblocked: $c" }
        }
        $blk.Close()
    }
}

# 2. Remove only the ProgrammaticAccessOnly value (leaves the key intact -> zero risk).
if ($HideStaticVerbs.Count -gt 0) {
    foreach ($rp in $HideStaticVerbs) {
        $rp = $rp.Trim().TrimStart('\')
        $sk = $cu.OpenSubKey($rp, $true)
        if ($sk -and ($sk.GetValueNames() -contains 'ProgrammaticAccessOnly')) {
            $sk.DeleteValue('ProgrammaticAccessOnly', $false)
            Write-Output "[OK] un-hid static verb: $rp"
        }
        if ($sk) { $sk.Close() }
    }
}

# 3. Remove classic menu override -> restores the Windows 11 new-style menu.
if ($RemoveClassicMenu) {
    try {
        $cu.DeleteSubKeyTree('Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}', $false)
        Write-Output '[OK] classic menu override removed (new-style menu restored)'
    } catch { Write-Output '[..] classic override not present' }
}

# 4. Restart Explorer.
if ($RestartExplorer) {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
    Write-Output '[OK] Explorer restarted'
}
Write-Output 'UNBLOCK DONE'
