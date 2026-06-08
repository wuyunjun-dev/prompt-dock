# PromptDock Windows

这是 PromptDock 的 Windows 桌面版本，使用 Electron 实现。

## 功能

- Windows 系统托盘应用。
- 点击托盘图标打开主窗口。
- 全局快捷键：`Ctrl + Alt + P`。
- 支持 OpenAI-compatible Chat Completions API。
- API Key 使用 Windows DPAPI 加密后保存在当前用户目录，不写入明文配置文件。
- 支持提示词优化、剪贴板优化、复制结果、历史记录查看、单条删除和批量删除。
- 全中文界面。

## 开发环境

- Windows 10/11。
- Node.js 20 或更新版本。
- npm。

## 运行

```powershell
cd windows
npm install
npm start
```

## 测试

```powershell
cd windows
npm test
```

## 打包 Windows x64

```powershell
cd windows
npm install
npm run package:win
```

打包产物会输出到：

```text
windows/dist/PromptDock-win32-x64/
```

将该目录压缩后分发给 Windows 用户，用户解压后运行 `PromptDock.exe`。

本仓库 Release 中的 Windows x64 包名为：

```text
PromptDock-Windows-1.1-x64.zip
```

## 安全和隐私

- API Key 不会写入 `configuration.json`。
- API Key 使用 Windows DPAPI 的 `CurrentUser` 范围加密，只能由当前 Windows 用户解密。
- 历史记录保存在本机 Electron userData 目录，内容目前未加密。
- 剪贴板内容只有在用户点击“优化剪贴板”或从托盘选择“优化剪贴板”时才会进入应用流程。

## 已知限制

- 当前 Windows 版未做代码签名。
- 当前打包脚本输出的是可执行目录，不是 MSI/NSIS 安装器。
- 当前快捷键固定为 `Ctrl + Alt + P`。
- 当前 API 客户端支持 Chat Completions，不支持 streaming 或 Responses API。
