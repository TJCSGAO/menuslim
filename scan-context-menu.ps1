# MenuSlim-Plus - full context menu scan
$ErrorActionPreference = 'SilentlyContinue'
$outDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Get-Default($path) {
    $i = Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
    if ($i) { return $i.GetValue('') }
    return $null
}

function Resolve-CLSID($guid) {
    $res = [ordered]@{ CLSID = $guid; Name = ''; Dll = ''; Bitness = ''; Company = ''; Description = '' }
    if ($guid -notmatch '^\{[0-9a-fA-F\-]+\}$') { return $res }
    $p64 = "Registry::HKEY_CLASSES_ROOT\CLSID\$guid"
    $p32 = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Classes\CLSID\$guid"
    $base = $null
    if (Test-Path -LiteralPath $p64) { $base = $p64; $res.Bitness = '64/any' }
    elseif (Test-Path -LiteralPath $p32) { $base = $p32; $res.Bitness = '32' }
    if ($base) {
        $res.Name = Get-Default $base
        $dll = Get-Default "$base\InprocServer32"
        if (-not $dll) { $dll = Get-Default "$base\LocalServer32" }
        if ($dll) {
            $dll = [Environment]::ExpandEnvironmentVariables($dll)
            $res.Dll = $dll
            if (Test-Path -LiteralPath $dll) {
                $vi = (Get-Item -LiteralPath $dll).VersionInfo
                $res.Company = $vi.CompanyName
                $res.Description = $vi.FileDescription
            }
        }
    }
    return [pscustomobject]$res
}

$comRecords = @()
$staticRecords = @()

# ---- COM ContextMenuHandlers locations ----
$comLocs = @(
    @{ Scope = "AllFiles(*)";            Path = 'Registry::HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers' },
    @{ Scope = 'Directory';              Path = 'Registry::HKEY_CLASSES_ROOT\Directory\shellex\ContextMenuHandlers' },
    @{ Scope = 'DirectoryBackground';    Path = 'Registry::HKEY_CLASSES_ROOT\Directory\Background\shellex\ContextMenuHandlers' },
    @{ Scope = 'Folder';                 Path = 'Registry::HKEY_CLASSES_ROOT\Folder\shellex\ContextMenuHandlers' },
    @{ Scope = 'AllFilesystemObjects';   Path = 'Registry::HKEY_CLASSES_ROOT\AllFilesystemObjects\shellex\ContextMenuHandlers' },
    @{ Scope = 'Drive';                  Path = 'Registry::HKEY_CLASSES_ROOT\Drive\shellex\ContextMenuHandlers' },
    @{ Scope = 'LibraryFolder';          Path = 'Registry::HKEY_CLASSES_ROOT\LibraryFolder\shellex\ContextMenuHandlers' }
)

# SystemFileAssociations (perceived types + extensions)
Get-ChildItem 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations' -ErrorAction SilentlyContinue | ForEach-Object {
    $comLocs += @{ Scope = "SFA\$($_.PSChildName)"; Path = "$($_.PSPath)\shellex\ContextMenuHandlers" }
}

# ProgID level (every HKCR child that registers handlers)
Get-ChildItem 'Registry::HKEY_CLASSES_ROOT' -ErrorAction SilentlyContinue | ForEach-Object {
    $cn = $_.PSChildName
    if ($cn -like '*.OpenWith*' -or $cn -like 'SystemFileAssociations*' -or $cn -eq '*' -or $cn -in @('Directory','Folder','AllFilesystemObjects','Drive','LibraryFolder','CLSID')) { return }
    $comLocs += @{ Scope = "ProgID\$cn"; Path = "$($_.PSPath)\shellex\ContextMenuHandlers" }
}

$seenCom = @{}
foreach ($loc in $comLocs) {
    if (-not (Test-Path -LiteralPath $loc.Path)) { continue }
    Get-ChildItem -LiteralPath $loc.Path -ErrorAction SilentlyContinue | ForEach-Object {
        $sub = $_
        $clsid = $sub.GetValue('')
        $handlerName = $sub.PSChildName
        if (-not $clsid -and $handlerName -match '^\{[0-9a-fA-F\-]+\}$') { $clsid = $handlerName }
        if (-not $clsid) { return }
        $clsid = $clsid.Trim()
        $key = "$($loc.Scope)|$clsid"
        if ($seenCom[$key]) { return }
        $seenCom[$key] = $true
        $info = Resolve-CLSID $clsid
        $comRecords += [pscustomobject]@{
            Scope = $loc.Scope
            HandlerKey = $handlerName
            CLSID = $clsid
            ExtensionName = $info.Name
            Dll = $info.Dll
            Bitness = $info.Bitness
            Company = $info.Company
            FileDescription = $info.Description
        }
    }
}

# ---- Static verb menu items (shell, not shellex) ----
$staticLocs = @(
    @{ Scope = "AllFiles(*)";          Path = 'Registry::HKEY_CLASSES_ROOT\*\shell' },
    @{ Scope = 'Directory';            Path = 'Registry::HKEY_CLASSES_ROOT\Directory\shell' },
    @{ Scope = 'DirectoryBackground';  Path = 'Registry::HKEY_CLASSES_ROOT\Directory\Background\shell' },
    @{ Scope = 'Folder';               Path = 'Registry::HKEY_CLASSES_ROOT\Folder\shell' },
    @{ Scope = 'AllFilesystemObjects'; Path = 'Registry::HKEY_CLASSES_ROOT\AllFilesystemObjects\shell' },
    @{ Scope = 'Drive';                Path = 'Registry::HKEY_CLASSES_ROOT\Drive\shell' },
    @{ Scope = 'LibraryFolder';        Path = 'Registry::HKEY_CLASSES_ROOT\LibraryFolder\shell' }
)
Get-ChildItem 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations' -ErrorAction SilentlyContinue | ForEach-Object {
    $staticLocs += @{ Scope = "SFA\$($_.PSChildName)"; Path = "$($_.PSPath)\shell" }
}
Get-ChildItem 'Registry::HKEY_CLASSES_ROOT' -ErrorAction SilentlyContinue | ForEach-Object {
    $cn = $_.PSChildName
    if ($cn -like '*.OpenWith*' -or $cn -like 'SystemFileAssociations*' -or $cn -eq '*' -or $cn -in @('Directory','Folder','AllFilesystemObjects','Drive','LibraryFolder','CLSID')) { return }
    $staticLocs += @{ Scope = "ProgID\$cn"; Path = "$($_.PSPath)\shell" }
}

$seenStatic = @{}
foreach ($loc in $staticLocs) {
    if (-not (Test-Path -LiteralPath $loc.Path)) { continue }
    Get-ChildItem -LiteralPath $loc.Path -ErrorAction SilentlyContinue | ForEach-Object {
        $verb = $_.PSChildName
        if ($verb -like 'Extended*') { return }
        $key = "$($loc.Scope)|$verb"
        if ($seenStatic[$key]) { return }
        $seenStatic[$key] = $true
        $mui = $_.GetValue('MUIVerb')
        $cmd = Get-Default "$($_.PSPath)\command"
        $programmatic = $null -ne (Get-Item -LiteralPath $_.PSPath).GetValue('ProgrammaticAccessOnly')
        $legacy = $null -ne (Get-Item -LiteralPath $_.PSPath).GetValue('LegacyDisable')
        if ($cmd) { $cmd = [Environment]::ExpandEnvironmentVariables($cmd) }
        $staticRecords += [pscustomobject]@{
            Scope = $loc.Scope
            Verb = $verb
            MUIVerb = $mui
            Command = $cmd
            AlreadyHidden = ($programmatic -or $legacy)
        }
    }
}

# ---- Win11 new menu state ----
$classicKey = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
$classicEnabled = $false
if (Test-Path $classicKey) {
    $v = (Get-Item $classicKey).GetValue('')
    if ($null -ne $v -and $v -eq '') { $classicEnabled = $true }
}

# ---- Existing Blocked lists ----
$blocked = @()
foreach ($root in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked',
                    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked')) {
    if (Test-Path $root) {
        $item = Get-Item $root
        foreach ($n in $item.GetValueNames()) {
            if ($n -like '{*}') { $blocked += [pscustomobject]@{ Root = $root; CLSID = $n } }
        }
    }
}

$result = [ordered]@{
    ScanTime = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    ClassicMenuEnabled = $classicEnabled
    BlockedNow = $blocked
    ComHandlers = $comRecords
    StaticVerbs = $staticRecords
}
$result | ConvertTo-Json -Depth 6 | Out-File -FilePath (Join-Path $outDir 'scan-result.json') -Encoding utf8

Write-Output "COM handlers: $($comRecords.Count)"
Write-Output "Static verbs : $($staticRecords.Count)"
Write-Output "Classic menu already enabled: $classicEnabled"
Write-Output "Blocked now  : $($blocked.Count)"
