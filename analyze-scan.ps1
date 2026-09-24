# Analyze scan results: classify system vs third-party
$ErrorActionPreference = 'SilentlyContinue'
$outDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$data = Get-Content (Join-Path $outDir 'scan-result.json') -Raw -Encoding utf8 | ConvertFrom-Json

function Test-SystemPath($p) {
    if (-not $p) { return $false }
    $t = $p.ToLower()
    $sysPrefixes = @(
        "$env:SystemRoot\".ToLower(),
        'c:\windows\',
        'c:\program files\microsoft',
        'c:\program files (x86)\microsoft',
        'c:\program files\common files\microsoft shared',
        'c:\program files (x86)\common files\microsoft shared',
        'c:\program files\windowsapps\microsoft',
        'c:\windows.old\'
    )
    foreach ($s in $sysPrefixes) { if ($t.StartsWith($s)) { return $true } }
    # rundll32/regsvr32 with only system dlls
    return $false
}

# ---- COM: dedupe by CLSID, merge scopes ----
$comByClsid = @{}
foreach ($r in $data.ComHandlers) {
    if (-not $comByClsid[$r.CLSID]) {
        $comByClsid[$r.CLSID] = [pscustomobject]@{
            CLSID = $r.CLSID; Name = $r.ExtensionName; Dll = $r.Dll; Bitness = $r.Bitness
            Company = $r.Company; Desc = $r.FileDescription; Scopes = (New-Object System.Collections.Generic.List[string])
        }
    }
    if ($r.Scope -notin $comByClsid[$r.CLSID].Scopes) { [void]$comByClsid[$r.CLSID].Scopes.Add($r.Scope) }
}

$comThird = @(); $comSys = @(); $comUnknown = @()
foreach ($c in $comByClsid.Values) {
    if ($c.Dll) {
        if (Test-SystemPath $c.Dll) { $comSys += $c } else { $comThird += $c }
    } else { $comUnknown += $c }
}

# ---- Static verbs: dedupe by verb+command, classify by command exe path ----
$stByKey = @{}
foreach ($r in $data.StaticVerbs) {
    if ($r.AlreadyHidden) { continue }
    $k = "$($r.Verb)||$($r.Command)"
    if (-not $stByKey[$k]) {
        $stByKey[$k] = [pscustomobject]@{
            Verb = $r.Verb; MUIVerb = $r.MUIVerb; Command = $r.Command
            Scopes = (New-Object System.Collections.Generic.List[string])
        }
    }
    if ($r.Scope -notin $stByKey[$k].Scopes) { [void]$stByKey[$k].Scopes.Add($r.Scope) }
}

$stThird = @(); $stSys = @()
foreach ($s in $stByKey.Values) {
    $cmd = $s.Command
    $isThird = $false
    if ($cmd) {
        # extract first quoted/existing exe path
        $exe = $null
        if ($cmd -match '^"([^"]+\.exe)"') { $exe = $matches[1] }
        elseif ($cmd -match '^([A-Za-z]:\\[^"]+?\.exe)') { $exe = $matches[1] }
        elseif ($cmd -match '([A-Za-z]:\\[^"]+?\.exe)') { $exe = $matches[1] }
        if ($exe) {
            $exe = [Environment]::ExpandEnvironmentVariables($exe)
            if (-not (Test-SystemPath $exe)) {
                if ($exe -match '^[A-Za-z]:\\(Program Files|Program Files \(x86\)|Users|ProgramData|Tools|Apps)') { $isThird = $true }
                elseif ($exe -match '^[D-Z]:\\') { $isThird = $true }
            }
        }
    }
    if ($isThird) { $stThird += $s } else { $stSys += $s }
}

$report = [ordered]@{
    ComThirdParty = $comThird
    ComUnknown = $comUnknown
    StaticThirdParty = $stThird
}
$report | ConvertTo-Json -Depth 6 | Out-File (Join-Path $outDir 'thirdparty-list.json') -Encoding utf8

Write-Output "===== THIRD-PARTY COM HANDLERS: $($comThird.Count) ====="
$comThird | Sort-Object Company, Name | ForEach-Object {
    Write-Output ("[{0}] {1} | {2} | {3}" -f $_.Company, $_.Name, (Split-Path $_.Dll -Leaf), ($_.Scopes -join ';'))
}
Write-Output ""
Write-Output "===== UNRESOLVED COM (packaged/modern, no DLL): $($comUnknown.Count) ====="
$comUnknown | ForEach-Object {
    Write-Output ("{0} | {1} | scopes: {2}" -f $_.Name, $_.CLSID, ($_.Scopes -join ';'))
}
Write-Output ""
Write-Output "===== THIRD-PARTY STATIC VERBS: $($stThird.Count) ====="
$stThird | Sort-Object Command | ForEach-Object {
    $label = if ($_.MUIVerb) { $_.MUIVerb } else { $_.Verb }
    Write-Output ("{0} | {1} | scopes: {2}" -f $label, $_.Command, ($_.Scopes -join ';'))
}
Write-Output ""
Write-Output "System COM kept: $($comSys.Count); System/static kept: $($stSys.Count)"
