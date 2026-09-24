# menuslim — MenuSlim（右键瘦身）

Slim down and repair the Windows right-click context menu. An agent Skill (works with any agent that follows the `SKILL.md` convention): it restores the one-step full menu on Windows 11, scans every menu entry, labels third-party vendors, backs up the registry, and lets you selectively hide/restore entries — without uninstalling anything.

## What it does

1. **Remove the Windows 11 "Show more options" extra click** — restore the Windows 10-style full menu that appears in one click.
2. **Full scan** — COM context-menu handlers across every scope, including 32-bit (`WOW6432Node`), per-extension (`SystemFileAssociations`) and per-ProgID registrations, plus static (non-COM) shell verbs.
3. **Vendor labeling & selective hiding** — third-party entries (cloud drives, input methods, chat apps, "open in editor" verbs, etc.) are labeled by vendor; you choose what to hide. System entries are never touched.
4. **Backup first, fully reversible** — registry keys are exported before any change; one script restores everything.

All changes happen at the **current-user** level (`HKCU`), so administrator rights are normally not required, and no application is uninstalled.

## Install

### One-line (auto-detects supported tools)

```powershell
irm https://raw.githubusercontent.com/TJCSGAO/menuslim/main/install.ps1 | iex
```

Target a specific tool:

```powershell
irm https://raw.githubusercontent.com/TJCSGAO/menuslim/main/install.ps1 -OutFile install.ps1
./install.ps1 -Target codex   # trae | codex | claude | cursor | windsurf
```

### Manual

Copy the repository files into a `menuslim/` folder under your tool's skill directory:

| Tool | Skill directory |
|---|---|
| TRAE | `~/.trae/skills/menuslim/` (China edition: `~/.trae-cn/skills/menuslim/`) |
| Codex | `~/.codex/skills/menuslim/` |
| Claude Code | `~/.claude/skills/menuslim/` |
| Cursor | `~/.cursor/skills/menuslim/` |
| Windsurf | `~/.windsurf/skills/menuslim/` |

## Usage

- Ask your agent, e.g. `清理右键菜单` / `恢复右键扩展` / `恢复完整右键菜单`.
- No agent? Double-click `enable-classic-menu.bat` to get the one-step full menu, or `restore-new-menu.bat` to undo it.

Typical scripted flow:

```powershell
# 1. scan and classify
powershell -ExecutionPolicy Bypass -File .\scan-context-menu.ps1
powershell -ExecutionPolicy Bypass -File .\analyze-scan.ps1
# 2. apply (user level) — pass the CLSIDs / verb paths you chose from the scan
.\block-handlers.ps1 -ClassicMenu -Clsids @('{...}') -HideStaticVerbs @('Software\Classes\Directory\shell\ExampleVerb') -RestartExplorer
# 3. undo
.\unblock-handlers.ps1 -RemoveClassicMenu -Clsids @('{...}') -HideStaticVerbs @('Software\Classes\Directory\shell\ExampleVerb') -RestartExplorer
```

## How it works

- **Classic menu**: an empty-data default value at `HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32` disables the truncated Windows 11 menu. (It must be written with `reg add ... /ve`; see `SKILL.md`.)
- **COM handlers**: the CLSID is listed under `...\CurrentVersion\Shell Extensions\Blocked`, so Explorer skips loading it.
- **Static verbs**: a `ProgrammaticAccessOnly` value hides the item from the normal menu while keeping it reachable via the extended keyboard menu.

## Files

| File | Purpose |
|---|---|
| `SKILL.md` | Full workflow, registry references, vendor mapping, pitfalls, privacy rules |
| `scan-context-menu.ps1` | Full scan (COM + static, 64/32-bit), writes `scan-result.json` |
| `analyze-scan.ps1` | Splits third-party entries from system entries |
| `block-handlers.ps1` | User-level: enable classic menu, block CLSIDs, hide static verbs |
| `unblock-handlers.ps1` | Reverse of `block-handlers.ps1` |
| `enable-classic-menu.bat` | One-click full menu (no admin needed) |
| `restore-new-menu.bat` | Restore the default Windows 11 menu |
| `install.ps1` | Installer for common agent tools |

## Privacy

This repository publishes only the generic workflow and scripts. It contains no personal paths, usernames, machine names, scan results, or lists of software installed on any individual machine. See the "Privacy rules" section in `SKILL.md` before redistributing.

## Disclaimer

Use at your own discretion. The scripts only read/write documented registry locations and are designed to be reversible; always review them and keep the backup before applying changes.
