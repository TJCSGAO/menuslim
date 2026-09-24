---
name: "menuslim"
description: "Slim down and repair the Windows right-click context menu. It can (1) restore the one-step Windows 10-style full menu on Windows 11 so users no longer click 'Show more options'; (2) fully scan ALL context-menu entries - COM ContextMenuHandlers (64/32-bit, per-extension, per-ProgID) and static shell verbs; (3) label third-party vendors, back up the registry, and let the user selectively block/restore entries at the user level without uninstalling anything. Invoke when a user complains about the Win11 'Show more options' extra click, a long/slow/bloated right-click menu, wants to clean up 右键菜单/右键扩展, or wants to restore previously hidden entries."
---

# MenuSlim (右键瘦身)

Manage the Windows Explorer right-click menu end to end: fix the Windows 11 two-level menu, scan every entry (COM handlers **and** static verbs), classify vendors, back up, then let the user choose what to hide. Everything is reversible; no software is uninstalled and no source file is touched.

## Workflow

### Step 0 - Identify the OS and your privileges

```powershell
Get-CimInstance Win32_OperatingSystem | Select-Object Caption, BuildNumber
# Admin? (most actions in this skill run at HKCU and do NOT need it)
([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
```

The classic-menu override and the user blocklist both live under **HKCU**, so the whole job normally needs no elevation. Only an optional machine-wide fallback uses HKLM (see Step 6).

### Step 1 - Remove the Windows 11 "Show more options" extra click

On Windows 11 the default menu is truncated and the full menu requires a second click. Restore the one-step full menu by creating an **empty-data default value** here (the CLSID is a fixed Windows identifier, not user data):

```
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve
```

Verify the value truly exists - this is the part that silently fails if done wrong:

```
reg query "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /s
REM correct output contains a line:   (Default)    REG_SZ
```

A ready-to-run equivalent is `enable-classic-menu.bat`. Undo with `restore-new-menu.bat` (deletes the override key, restoring the Windows 11 menu).

### Step 2 - Full scan (COM handlers + static verbs)

Run `scan-context-menu.ps1`. It writes `scan-result.json` next to itself and prints counts. It enumerates:

- COM `ContextMenuHandlers` under every relevant location (see Reference A), including a full sweep of every `HKEY_CLASSES_ROOT` child (ProgID level) and `SystemFileAssociations`.
- Each CLSID is resolved to its owning DLL, checking both the 64-bit class view and the **32-bit** `WOW6432Node\Classes\CLSID` view, plus the DLL's company name / file description.
- Static (non-COM) verbs under each `shell` key, with their command line and whether they are already hidden.
- The current classic-menu state and the existing HKLM/HKCU blocklists.

Then run `analyze-scan.ps1` to separate third-party entries from system entries (writes `thirdparty-list.json`).

### Step 3 - Classify and label vendors

Resolve each COM handler's CLSID to its DLL and label the vendor. Map common DLL file names to friendly names (Reference B). For static verbs, classify by the executable path in the verb's `command` value.

Important scoping distinction:
- Entries registered at the **top-level** scopes (`*`, `Directory`, `Directory\Background`, `Folder`, `Drive`, `AllFilesystemObjects`, `LibraryFolder`) appear on the menus the user actually opens - these are the bloat sources.
- A ProgID's own `open` / `print` / `edit` verbs are the normal file-association behavior (double-click actions). They are not bloat and should normally be left alone.

### Step 4 - Let the user confirm

Present a vendor-labeled table (name, CLSID / verb, DLL or command, scope, recommendation) and let the user multi-select. Never hide system entries. If the user defers selection, a reasonable default is to hide clearly third-party top-level entries (cloud drives, input-method helpers, chat apps, "open in editor" verbs) while **keeping** compression menus (7-Zip / WinRAR) since those are commonly used daily; state the default clearly and make it reversible.

### Step 5 - Back up before changing anything

Export every key you will touch (read access is enough), e.g.:

```
reg export "HKCR\CLSID\{...}"            backup\clsid-{...}.reg /y
reg export "HKCR\Directory\shell\Verb"   backup\static-n.reg  /y
reg export "HKLM\...\Shell Extensions\Blocked" backup\blocked-hklm.reg /y
reg export "HKCU\Software\Classes\CLSID" backup\hkcu-classes-clsid.reg /y
```

Missing keys produce an ERROR line; that is expected, not a failure.

### Step 6 - Apply (user level, no admin)

Use `block-handlers.ps1`, which wraps the reliable mechanisms:

```powershell
.\block-handlers.ps1 -ClassicMenu `
    -Clsids @('{chosen-clsid-1}','{chosen-clsid-2}') `
    -HideStaticVerbs @('Software\Classes\Directory\shell\SomeVerb') `
    -RestartExplorer
```

Mechanisms used:

- **COM handler**: the CLSID is added as an empty-string value under
  `HKCU\Software\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked`.
  Explorer then refuses to load the handler; the software itself is untouched.
- **Static verb**: create the matching key under `HKCU\Software\Classes\...` and add an empty `ProgrammaticAccessOnly` value. Because HKCU and HKLM class keys merge, the verb disappears from the normal right-click menu (it remains reachable via the extended keyboard menu). Static verbs do NOT respond to the COM blocklist.
- **Classic menu**: the `reg add ... /ve` from Step 1.

Optional machine-wide fallback (needs elevation): add the same CLSIDs under
`HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked`.
If you cannot trigger an elevated process, generate a **pure-English .bat** and have the user run it via right-click -> "Run as administrator" rather than fighting inline elevation.

### Step 7 - Restart Explorer and verify

Restart Explorer (`Stop-Process -Name explorer -Force; Start-Process explorer.exe`) and verify by reading the registry back - do not trust exit codes:

- `reg query` for the classic override shows `(Default) REG_SZ`.
- The blocklist key lists exactly the chosen CLSIDs.
- Each hidden static verb key contains `ProgrammaticAccessOnly`.
- Explorer is running; then ask the user to actually right-click a file, a folder, and the desktop background. If a cached entry persists, sign out/in once.

Restore everything with `unblock-handlers.ps1` using the same arguments (plus `-RemoveClassicMenu`); it removes only the values it created and restarts Explorer.

## Reference A - registry locations

COM context-menu handlers (use the `Registry::HKEY_CLASSES_ROOT` provider path; there is no default `HKCR:` drive):

```
HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers
HKEY_CLASSES_ROOT\Directory\shellex\ContextMenuHandlers
HKEY_CLASSES_ROOT\Directory\Background\shellex\ContextMenuHandlers
HKEY_CLASSES_ROOT\Folder\shellex\ContextMenuHandlers
HKEY_CLASSES_ROOT\AllFilesystemObjects\shellex\ContextMenuHandlers
HKEY_CLASSES_ROOT\Drive\shellex\ContextMenuHandlers
HKEY_CLASSES_ROOT\LibraryFolder\shellex\ContextMenuHandlers
HKEY_CLASSES_ROOT\SystemFileAssociations\<.ext or perceived type>\shellex\ContextMenuHandlers
HKEY_CLASSES_ROOT\<ProgID>\shellex\ContextMenuHandlers      (sweep every child)
```

CLSID resolution:
```
HKEY_CLASSES_ROOT\CLSID\<clsid>\InprocServer32            (64-bit / neutral)
HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Classes\CLSID\<clsid>\InprocServer32   (32-bit)
```

Static verbs live under the same scopes with `shell` instead of `shellex\ContextMenuHandlers`.

For a handler subkey, read its default value for the CLSID; if empty and the subkey name itself is a GUID, the subkey name is the CLSID.

## Reference B - vendor mapping (generic examples)

These are common, illustrative mappings (functional knowledge, not user data):

- `kwpsshellext64.dll`, `qingshellext64.dll`, `qingnse64.dll`, `kdesktopshellext64.dll` -> WPS Office / Kingsoft
- `YunShellExt*.dll` -> Baidu Netdisk
- `QQShellExt*.dll` -> QQ / TIM
- `biz_shellext*.dll` -> Sogou Input Method
- `FileSyncShell*.dll` -> OneDrive
- `7-zip.dll` -> 7-Zip; `rarext.dll` / `rarext32.dll` -> WinRAR
- `ConvertToPDFShellExtension*.dll` -> Foxit PDF; `AcShellExtension.dll` -> Autodesk AutoCAD

System entries to keep by default include anything under `C:\Windows\` or the Microsoft program folders, and handlers such as SendTo, Sharing / ModernSharing, CopyAsPathMenu, New, WorkFolders, EncryptionMenu / CryptoMenu, EPP (Defender), PintoStartScreen / Taskband Pin, Compressed Folder menus, Compatibility, Windows Photo Viewer, and contact (.contact/.group) handlers.

## Critical pitfalls (learned the hard way)

1. **Empty default value for the classic menu**: you MUST use `reg add "...\InprocServer32" /f /ve`. PowerShell/.NET `(Get-Item $k).SetValue('','')` reports success but does NOT persist the value, so the menu stays truncated. Confirm with `reg query /s` - you must see a `(Default) REG_SZ` line.
2. **Registry provider is not a file system**: `New-Item -Force` does not create multiple missing parent levels for registry keys; create parents step by step or use `[Microsoft.Win32.Registry]::CurrentUser.CreateSubKey(...)`.
3. **Wildcards in paths**: a path containing `*` (e.g. `Classes\*\shell`) is interpreted by `-Path`. Use `-LiteralPath` for cmdlets or the .NET registry API.
4. **HKCR provider**: use `Registry::HKEY_CLASSES_ROOT\...`; a plain `HKCR:` drive does not exist by default.
5. **32-bit handlers**: resolve CLSIDs in both the HKCR view and `WOW6432Node\Classes\CLSID`, or you miss 32-bit extensions.
6. **Static vs COM**: the blocklist only affects COM handlers. Hide static verbs with `ProgrammaticAccessOnly` (or `LegacyDisable`).
7. **UAC / elevation**: writing HKLM needs elevation. If an elevated launch returns a negative exit code (UAC prompt missed/cancelled on a separate desktop), stop retrying after two attempts and ship a pure-English admin .bat.
8. **.bat encoding**: cmd mojibakes UTF-8-with-BOM files containing non-ASCII text. Keep .bat files pure ASCII/English; do not rely on `chcp 65001` to embed Chinese.
9. **Quoting**: avoid complex inline `-ArgumentList` quoting when elevating; write logic to a .ps1/.bat file and elevate the file.
10. **Verification**: after writes, read back the actual values/properties; exit codes alone are not sufficient.

## Privacy rules (when sharing or publishing this skill)

Open-source the workflow and the generic scripts only. Before publishing, make sure NO artifact contains:

- the user name / home path (e.g. `C:\Users\<name>`), real names, or machine names;
- absolute paths from the user's machine (personal folders, custom install drives, project paths);
- the user's scan results (`scan-result.json`, `thirdparty-list.json`) or the list of CLSIDs/software actually selected on their machine (that reveals which apps they installed);
- tokens, credentials, or any personal identifiers.

Use environment variables (`$env:USERPROFILE`, `$env:SystemRoot`), parameters, and clearly-marked placeholder GUIDs. Generic vendor examples in Reference B are fine because they describe common software in general, not the user's machine.

## Deliverables

- Generic scripts: `scan-context-menu.ps1`, `analyze-scan.ps1`, `block-handlers.ps1`, `unblock-handlers.ps1`.
- Generic double-click helpers: `enable-classic-menu.bat`, `restore-new-menu.bat`.
- A vendor-labeled scan table for the user (kept private), a registry backup folder, and clear run/restore instructions.
