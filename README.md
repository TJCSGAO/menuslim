# menuslim

MenuSlim（右键瘦身）— Windows 右键菜单第三方 Shell 扩展的管理工具（TRAE Skill）。

扫描资源管理器右键菜单的第三方扩展（WPS、百度网盘、搜狗、QQ/TIM、各类网盘等），按厂商标注列表，让用户选择后通过注册表 Shell Extension Blocked 列表禁用；支持一键恢复。

## 快速安装（一行命令）

在 PowerShell 中运行：

```powershell
irm https://raw.githubusercontent.com/TJCSGAO/menuslim/main/install.ps1 | iex
```

安装器会自动探测 `.trae/skills` 或 `.trae-cn/skills` 目录并下载 SKILL.md 与脚本。

## 手动安装

1. 下载或克隆本仓库。
2. 将 `SKILL.md`、`disable-context-menu.bat`、`restore-context-menu.bat` 放入 TRAE 的 skill 目录（`.trae/skills/menuslim/`）。

## 使用

- 对话中触发：`清理右键菜单` / `恢复右键扩展`。
- Agent 会扫描注册表并列出厂商表，确认后生成脚本。

## 文件

- `SKILL.md` — Skill 定义（扫描/分类/禁用/恢复完整流程与踩坑记录）
- `disable-context-menu.bat` — 禁用所选扩展（管理员运行）
- `restore-context-menu.bat` — 恢复（管理员运行）
- `install.ps1` — 一行命令安装器

## 原理

将扩展的 CLSID 写入 `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked`，不动源文件，随时可逆。

## 卸载

删除 `.trae/skills/menuslim/` 目录即可（如已禁用扩展，请先运行 restore 脚本恢复）。
