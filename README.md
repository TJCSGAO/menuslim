# menuslim

MenuSlim（右键瘦身）— Windows 右键菜单第三方 Shell 扩展的管理工具（Agent Skill）。

扫描资源管理器右键菜单的第三方扩展（WPS、百度网盘、搜狗、QQ/TIM、各类网盘等），按厂商标注列表，让用户选择后通过注册表 Shell Extension Blocked 列表禁用；支持一键恢复。

适用于任何支持 SKILL.md 约定的 Agent 工具（TRAE、Codex、Claude Code、Cursor、Windsurf 等）。

## 安装

### 方式一：一行命令（自动探测已安装的工具）

```powershell
irm https://raw.githubusercontent.com/TJCSGAO/menuslim/main/install.ps1 | iex
```

或指定目标工具：

```powershell
irm https://raw.githubusercontent.com/TJCSGAO/menuslim/main/install.ps1 -OutFile install.ps1
./install.ps1 -Target codex   # trae | codex | claude | cursor | windsurf
```

### 方式二：按各工具常规 Skill 安装方法

将本仓库的 `SKILL.md`、`disable-context-menu.bat`、`restore-context-menu.bat` 三个文件放入对应工具的 skill 目录下的 `menuslim/` 子目录，即标准的「下载仓库 → 拷入 skill 目录」流程，与安装其他第三方 skill 完全一致：

| 工具 | Skill 目录 |
|---|---|
| TRAE | `~/.trae/skills/menuslim/`（国内版为 `~/.trae-cn/skills/menuslim/`） |
| Codex | `~/.codex/skills/menuslim/` |
| Claude Code | `~/.claude/skills/menuslim/` |
| Cursor | `~/.cursor/skills/menuslim/` |
| Windsurf | `~/.windsurf/skills/menuslim/` |

## 使用

- 对话中触发：`清理右键菜单` / `恢复右键扩展`。
- Agent 会扫描注册表并列出厂商表，确认后生成脚本。

## 文件

- `SKILL.md` — Skill 定义（扫描/分类/禁用/恢复完整流程与踩坑记录）
- `disable-context-menu.bat` — 禁用所选扩展（管理员运行）
- `restore-context-menu.bat` — 恢复（管理员运行）
- `install.ps1` — 安装器（自动探测或 `-Target` 指定工具）

## 原理

将扩展的 CLSID 写入 `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked`，不动源文件，随时可逆。

## 卸载

删除 skill 目录下的 `menuslim/` 目录即可（如已禁用扩展，请先运行 restore 脚本恢复）。
