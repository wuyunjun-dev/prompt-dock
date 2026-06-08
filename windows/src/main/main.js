const path = require("node:path");
const { app, BrowserWindow, Tray, Menu, globalShortcut, ipcMain, clipboard, nativeImage, shell } = require("electron");
const { ConfigurationStore } = require("../shared/config-store");
const { HistoryStore } = require("../shared/history-store");
const { SecureStore } = require("../shared/secure-store");
const { complete } = require("../shared/api-client");
const { makeUserPrompt, systemPrompt } = require("../shared/prompt-template");

let mainWindow;
let tray;
let isQuitting = false;
let stores;

function userDataPath(fileName) {
  return path.join(app.getPath("userData"), fileName);
}

function createStores() {
  stores = {
    configuration: new ConfigurationStore(userDataPath("configuration.json")),
    history: new HistoryStore(userDataPath("history.json")),
    secure: new SecureStore(userDataPath("api-key.dpapi"))
  };
}

function createWindow() {
  if (mainWindow) {
    return mainWindow;
  }

  mainWindow = new BrowserWindow({
    width: 980,
    height: 660,
    minWidth: 860,
    minHeight: 560,
    title: "PromptDock",
    show: false,
    icon: assetPath("tray.png"),
    webPreferences: {
      preload: path.join(__dirname, "preload.cjs"),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false
    }
  });

  mainWindow.loadFile(path.join(__dirname, "..", "renderer", "index.html"));

  mainWindow.on("close", (event) => {
    if (!isQuitting) {
      event.preventDefault();
      mainWindow.hide();
    }
  });

  mainWindow.on("closed", () => {
    mainWindow = null;
  });

  return mainWindow;
}

function assetPath(fileName) {
  return path.join(__dirname, "..", "assets", fileName);
}

function showMainWindow() {
  const window = createWindow();
  window.show();
  window.focus();
}

function createTray() {
  const image = nativeImage.createFromPath(assetPath("tray.png"));
  tray = new Tray(image);
  tray.setToolTip("PromptDock");
  tray.setContextMenu(makeTrayMenu());
  tray.on("click", showMainWindow);
  tray.on("double-click", showMainWindow);
}

function makeTrayMenu() {
  return Menu.buildFromTemplate([
    { label: "打开 PromptDock", click: showMainWindow },
    { label: "优化剪贴板", click: optimizeClipboardFromTray },
    { type: "separator" },
    { label: "查看下载页面", click: () => shell.openExternal("https://github.com/wuyunjun-dev/prompt-dock/releases/tag/v1.0") },
    { type: "separator" },
    {
      label: "退出",
      click: () => {
        isQuitting = true;
        app.quit();
      }
    }
  ]);
}

function registerShortcuts() {
  const ok = globalShortcut.register("CommandOrControl+Alt+P", showMainWindow);
  if (!ok) {
    console.error("[PromptDock] 无法注册全局快捷键 Ctrl + Alt + P");
  }
}

async function optimizeClipboardFromTray() {
  const text = clipboard.readText().trim();
  showMainWindow();
  if (text) {
    mainWindow.webContents.once("did-finish-load", () => {
      mainWindow.webContents.send("clipboard-text", text);
    });
    mainWindow.webContents.send("clipboard-text", text);
  }
}

async function bootstrap() {
  const [configuration, historyItems, hasStoredAPIKey] = await Promise.all([
    stores.configuration.load(),
    stores.history.load(),
    stores.secure.hasAPIKey()
  ]);
  return {
    configuration,
    historyItems,
    hasStoredAPIKey,
    platform: "windows"
  };
}

async function optimizePrompt(payload) {
  const rawInput = String(payload?.rawInput ?? "").trim();
  if (!rawInput) {
    throw new Error("输入为空。请先输入想法、任务、报错信息或剪贴板文本。");
  }

  const apiKey = await stores.secure.readAPIKey();
  if (!apiKey || !apiKey.trim()) {
    throw new Error("尚未配置 API 密钥。请先在设置中添加。");
  }

  const request = {
    rawInput,
    mode: payload?.mode || "codexDevelopment",
    targetTool: payload?.targetTool || "codex",
    optionalContext: "",
    createdAt: new Date().toISOString()
  };
  const configuration = await stores.configuration.load();
  const optimizedPrompt = await complete({
    systemPrompt,
    userPrompt: makeUserPrompt(request),
    configuration,
    apiKey
  });
  return {
    request,
    result: {
      optimizedPrompt,
      rationale: null,
      suggestedNextSteps: null
    }
  };
}

function registerIPC() {
  ipcMain.handle("app:bootstrap", bootstrap);

  ipcMain.handle("settings:save", async (_event, payload) => {
    const configuration = await stores.configuration.save(payload?.configuration ?? {});
    const suppliedAPIKey = String(payload?.apiKey ?? "").trim();
    if (suppliedAPIKey) {
      await stores.secure.saveAPIKey(suppliedAPIKey);
    }
    return {
      configuration,
      hasStoredAPIKey: await stores.secure.hasAPIKey()
    };
  });

  ipcMain.handle("settings:testConnection", async (_event, payload) => {
    const configuration = payload?.configuration ?? await stores.configuration.load();
    const suppliedAPIKey = String(payload?.apiKey ?? "").trim();
    const apiKey = suppliedAPIKey || await stores.secure.readAPIKey();
    if (!apiKey || !apiKey.trim()) {
      throw new Error("尚未配置 API 密钥。请先在设置中添加。");
    }
    await complete({
      systemPrompt: "You are a connection test assistant.",
      userPrompt: "Reply with OK.",
      configuration,
      apiKey
    });
    return "连接测试成功。";
  });

  ipcMain.handle("settings:clearAPIKey", async () => {
    await stores.secure.deleteAPIKey();
    return {
      hasStoredAPIKey: false
    };
  });

  ipcMain.handle("prompt:optimize", async (_event, payload) => optimizePrompt(payload));

  ipcMain.handle("clipboard:readText", async () => clipboard.readText());
  ipcMain.handle("clipboard:writeText", async (_event, text) => {
    clipboard.writeText(String(text ?? ""));
    return true;
  });

  ipcMain.handle("history:list", async () => stores.history.load());
  ipcMain.handle("history:append", async (_event, payload) => {
    await stores.history.append(payload?.request, payload?.result);
    return stores.history.load();
  });
  ipcMain.handle("history:delete", async (_event, ids) => {
    const deletedCount = await stores.history.delete(ids);
    return {
      deletedCount,
      historyItems: await stores.history.load()
    };
  });
  ipcMain.handle("history:clear", async () => {
    await stores.history.clear();
    return [];
  });
}

app.on("before-quit", () => {
  isQuitting = true;
});

app.whenReady().then(() => {
  app.setAppUserModelId("com.promptdock.PromptDock");
  createStores();
  registerIPC();
  createWindow();
  createTray();
  registerShortcuts();
  showMainWindow();
});

app.on("activate", showMainWindow);

app.on("will-quit", () => {
  globalShortcut.unregisterAll();
});
