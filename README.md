# menuslim

MenuSlim（右键瘦身）— Windows 右键菜单第三方 Shell 扩展的管理工具（TRAE Skill）。

扫描资源管理器右键菜单的第三方扩展（WPS、百度网盘、搜狗、QQ/TIM、各类网盘等），按厂商标注列表，让用户选择后通过注册表 Shell Extension Blocklist 可逆地禁用或恢复，不修改、不卸载任何软件。

## 使用

1. 将 `SKILL.md` 放入 TRAE 的 skill 目录（`.trae/skills/menuslim/`）。
2. 对话中触发：清理右键菜单 / 恢复右键扩展。
3. Agent 会扫描注册表并列出厂商表，确认后生成脚本。

## 文件

- `SKILL.md` — Skill 定义（扫描/分类/禁用/恢复完整流程与踩坑记录）
- `disable-context-menu.bat` — 禁用所选扩展（管理员运行）
- `restore-context-menu.bat` — 恢复（管理员运行）

## 原理

将扩展的 CLSID 写入 `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked`，Explorer 拒绝加载该处理器；删除该值即恢复。全程可逆。
