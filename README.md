# PromptDock

PromptDock 是一个原生 macOS 菜单栏应用，用于把零散想法、Bug 描述、重构需求、代码审查请求或剪贴板文本，整理成更清晰、可直接交给 AI 编程助手执行的提示词。

它面向 Codex、Claude Code、Cursor、ChatGPT，以及其他兼容 OpenAI Chat Completions API 的模型服务。

## 功能特性

- 原生 macOS 菜单栏应用，默认不显示 Dock 图标。
- 左键点击菜单栏图标打开主窗口，右键或 Control 点击打开应用菜单。
- 全局快捷键：`Command + Option + P`。
- 支持从剪贴板一键优化文本。
- 支持多种提示词模式：
  - Codex 开发任务
  - Bug 修复提示词
  - 重构提示词
  - 代码审查提示词
  - 需求拆解提示词
  - 通用提示词优化
- 支持多种目标工具：
  - Codex
  - Claude Code
  - Cursor
  - ChatGPT
  - 通用 Agent
- 支持 OpenAI-compatible Chat Completions API。
- API Key 只存储在 macOS Keychain。
- 历史记录保存在本机 Application Support 目录。
- 历史记录支持查看、复制、载入、单条删除和批量删除。
- 主窗口支持拖拽调整大小，并限制在屏幕可见区域内。
- 最大 Token 数支持手动输入。

## 下载和安装 macOS 版

可以从 GitHub Release 页面下载：

[PromptDock v1.1](https://github.com/wuyunjun-dev/prompt-dock/releases/tag/v1.1)

macOS 推荐下载：

- `PromptDock-1.0.dmg`：打开后将 `PromptDock.app` 拖入 `Applications`。
- `PromptDock-1.0.zip`：备用压缩包，解压后手动放入 `Applications`。

Windows 推荐下载：

- `PromptDock-Windows-1.1-x64.zip`：解压后运行 `PromptDock-win32-x64/PromptDock.exe`。

当前发布包使用本地 adhoc 签名，尚未使用 Apple Developer ID 签名和公证。因此在其他 Mac 上首次打开时，macOS 可能提示“无法验证开发者”。

如果被 Gatekeeper 拦截，可以尝试：

1. 在 Finder 中右键点击 `PromptDock.app`。
2. 选择“打开”。
3. 在系统提示中再次确认打开。

也可以在“系统设置”里的“隐私与安全性”页面允许打开。

## macOS 系统要求

- macOS 14 或更新版本。
- 当前 Release 包主要面向 Apple Silicon Mac。
- 如果需要兼容 Intel Mac，建议从源码重新构建 Universal 版本。

## 首次使用

1. 启动 `PromptDock.app`。
2. 在菜单栏找到 PromptDock 图标。
3. 点击图标打开主窗口。
4. 点击右上角齿轮进入设置。
5. 填写 API 配置并保存。
6. 输入要优化的内容，选择模式和目标工具，然后点击“优化”。

如果 macOS 弹出 Keychain 权限提示，说明应用正在读取已保存的 API Key。请输入当前 Mac 登录密码并选择“始终允许”或“允许”。

## API 配置

在设置页中填写：

- API 提供方名称
- 基础 URL，例如 `https://api.openai.com/v1`
- API Key
- 模型名称
- 温度
- 最大 Token 数
- 额外请求头

PromptDock 会向以下地址发送请求：

```text
POST {baseURL}/chat/completions
```

API Key 会作为 Bearer Token 发送：

```text
Authorization: Bearer <API_KEY>
```

额外请求头使用每行一个 `Name: Value` 的格式配置。`Authorization` 请求头由 PromptDock 自动管理，即使在额外请求头中填写也不会覆盖 API Key。

## 隐私说明

- PromptDock 不包含固定后端服务。
- 用户输入只会发送到用户自己配置的 API 提供方。
- 剪贴板内容不会自动上传，只有用户选择“优化剪贴板”时才会发送。
- API Key 存储在 macOS Keychain，不写入 UserDefaults 或 JSON 文件。
- API 配置中的非密钥字段存储在 UserDefaults。
- 历史记录以本地 JSON 文件形式保存在 Application Support。
- Authorization/Bearer 信息会在调试日志和 API 错误展示中做脱敏处理。

请注意：历史记录包含原始输入和优化后的提示词，目前未加密。处理敏感内容后，可以在设置中清空历史，或在历史页删除指定记录。

## Windows 版

仓库内包含独立的 Windows 版本源码，位置：

```text
windows/
```

Windows 版使用 Electron 实现，提供系统托盘、`Ctrl + Alt + P` 全局快捷键、中文界面、OpenAI-compatible API 调用、历史记录，以及使用 Windows DPAPI 加密保存 API Key。

在 Windows 上运行：

```powershell
cd windows
npm install
npm start
```

运行 Windows 版测试：

```powershell
cd windows
npm test
```

打包 Windows x64 可执行目录：

```powershell
cd windows
npm run package:win
```

产物会输出到：

```text
windows/dist/PromptDock-win32-x64/
```

当前 Windows 版未做代码签名，也还不是 MSI/NSIS 安装器。正式分发前建议增加 Windows 代码签名和安装器。

## 从源码运行 macOS 版

克隆仓库：

```sh
git clone https://github.com/wuyunjun-dev/prompt-dock.git
cd prompt-dock
```

使用 Xcode 打开：

```sh
open PromptDock.xcodeproj
```

然后选择 `PromptDock` scheme，在 macOS 14 或更新系统上构建运行。

也可以使用命令行构建：

```sh
xcodebuild -scheme PromptDock -configuration Debug build
```

构建 Release：

```sh
xcodebuild -scheme PromptDock -configuration Release build
```

## 运行测试

```sh
xcodebuild -scheme PromptDock -configuration Debug test
```

当前单元测试覆盖：

- API 配置默认值、URL 校验和数值裁剪。
- OpenAI-compatible 请求体格式。
- OpenAI-compatible 响应解析。
- 非 2xx、空响应、空输入、缺少 API Key 等错误处理。
- Authorization 日志脱敏。
- 本地历史记录保存、读取、清空、单条删除和批量删除。
- 不同模式和目标工具的提示词模板生成。

## 项目结构

```text
PromptDock/
  HotKey/           全局快捷键注册
  MenuBar/          菜单栏图标、菜单和窗口控制
  Models/           配置、请求、结果、历史记录等数据模型
  Services/         API 客户端、Keychain、历史记录、剪贴板、模板服务
  Utilities/        错误类型、日志和通知
  ViewModels/       主视图状态和业务流程
  Views/            SwiftUI 界面
PromptDockTests/    XCTest 单元测试
```

## 已知限制

- 当前全局快捷键固定为 `Command + Option + P`，暂不支持自定义。
- 当前 API 客户端面向 OpenAI-compatible Chat Completions，不支持 streaming、Responses API 或 tool calls。
- 当前 Release 未使用 Developer ID 签名和 Apple 公证。
- 当前 Release 主要面向 Apple Silicon Mac。
- 历史记录使用本地 JSON 文件，暂未使用 SQLite/Core Data，也未加密。
- 应用不包含账号系统、同步功能或插件系统。

## 分发说明

如果要面向普通用户正式分发，建议补充：

1. Apple Developer ID Application 证书签名。
2. Apple Notary 公证。
3. Universal 构建，兼容 Apple Silicon 和 Intel Mac。
4. 自动更新机制。

当前 Release 更适合个人使用、内部测试或可信用户试用。
