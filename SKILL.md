---
name: "menuslim"
description: "Scans, lists, and lets the user selectively disable/restore third-party Windows right-click context menu shell extensions (WPS, BaiduNetdisk, Sogou, QQ/TIM, cloud drives, etc.) via the registry Blocked list. Invoke when the user complains about a long or slow right-click menu, wants to clean up 右键菜单/右键扩展, or wants to restore previously blocked entries."
---

# MenuSlim (右键瘦身)

Slim down bloated Windows right-click menus. Manage third-party Explorer context-menu shell extensions: scan them, present a vendor-labeled list, let the user choose, then disable or restore via the registry shell-extension blocklist. The method is fully reversible and does not modify or uninstall any software.

## Workflow

### Step 1 — Scan registry handler locations

Third-party context menu handlers live under these keys (use the `Registry::HKEY_CLASSES_ROOT` provider path — plain `HKCR:` does **not** exist in PowerShell by default):

```
Registry::HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers
Registry::HKEY_CLASSES_ROOT\Directory\shellex\ContextMenuHandlers
Registry::HKEY_CLASSES_ROOT\Directory\Background\shellex\ContextMenuHandlers
Registry::HKEY_CLASSES_ROOT\Folder\shellex\ContextMenuHandlers
Registry::HKEY_CLASSES_ROOT\AllFilesystemObjects\shellex\ContextMenuHandlers
```

For each subkey, read the default value (the CLSID, e.g. `{85212cfd-...}`). Note: the subkey *name* may be empty or localized — the CLSID in the default value is the reliable identifier.

### Step 2 — Resolve each CLSID to its owning DLL

```
Registry::HKEY_CLASSES_ROOT\CLSID\<clsid>\InprocServer32  -> default value = DLL path
```

Classify by DLL path:

- **System / keep by default**: paths under `C:\Windows\`, `C:\Program Files\Microsoft`, or handlers named `SendTo`, `Sharing`, `ModernSharing`, `CopyAsPathMenu`, `New`, `WorkFolders`, `EncryptionMenu`, `EPP`, `CryptoMenu`, `PintoStartScreen`, `AccExt`, `NvCplDesktopContext` etc.
- **Third-party**: anything under vendor folders (`WPS Office`, `Baidu`, `Sogou`, `Tencent`, `Foxit`, `Kingsoft`, `360`, `Lenovo`, ...). Map DLL file names to friendly vendor names for the user, e.g. `kwpsshellext64.dll`/`qingshellext64.dll`/`qingnse64.dll` -> WPS Office; `YunShellExt*.dll` -> Baidu Netdisk; `QQShellExt*.dll` -> QQ/TIM; `FileSyncShell*.dll` -> OneDrive; `biz_shellext*.dll` -> Sogou Input.

Present a vendor-labeled table and let the user multi-select which vendors to disable. Never disable system entries.

### Step 3 — Disable via the blocklist (reversible)

Add each chosen CLSID as a value name under:

```
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked
```

(value type `REG_SZ`, data empty). This is the official Shell Extension blocklist: Explorer refuses to load the handler, but the software itself is untouched. Restoring = deleting the value.

### Step 4 — Apply and restart Explorer

`taskkill /f /im explorer.exe` then `start explorer.exe`.

## Critical pitfalls (learned the hard way)

1. **HKCR provider**: must use `Registry::HKEY_CLASSES_ROOT\...`, not `HKCR:\`.
2. **Admin rights / UAC**: writing HKLM needs elevation. If `Start-Process -Verb RunAs` from the agent returns exit code `-196608`, the UAC prompt was cancelled or missed (it flashes on a separate desktop). After two failed attempts, **stop retrying and generate a .bat script for the user to run manually** as administrator instead.
3. **.bat encoding**: cmd cannot run scripts saved as UTF-8-with-BOM containing Chinese text — lines turn into mojibake (`'x1銆...' 不是内部或外部命令`) and every command fails. Always write .bat files in **pure ASCII/English only**. Do not rely on `chcp 65001` to save Chinese content.
4. **Quoting**: when elevating inline via `Start-Process powershell -ArgumentList '-Command', "<script>"`, complex quoting breaks silently (command exits 0 but does nothing). Always write the logic to a `.ps1`/`.bat` file and elevate the file instead.
5. **Verification**: after any registry write, read back `(Get-Item <key>).Property` to confirm values actually exist; do not trust exit codes alone.

## Deliverables to produce for the user

- A vendor-labeled scan table (extension name, CLSID, DLL path, vendor, keep/disable recommendation).
- `disable-context-menu.bat` — pure-English admin script that adds chosen CLSIDs to the Blocked key and restarts Explorer; echo success per line so the user can verify.
- `restore-context-menu.bat` — same CLSIDs, `reg delete ... /f` (with `>nul 2>&1` on deletes since already-deleted values are fine), restarts Explorer.

Both scripts go in the user's workspace folder; tell the user to run them via right-click → "以管理员身份运行".
