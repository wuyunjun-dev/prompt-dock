const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("promptDock", {
  bootstrap: () => ipcRenderer.invoke("app:bootstrap"),
  saveSettings: (payload) => ipcRenderer.invoke("settings:save", payload),
  testConnection: (payload) => ipcRenderer.invoke("settings:testConnection", payload),
  clearAPIKey: () => ipcRenderer.invoke("settings:clearAPIKey"),
  optimize: (payload) => ipcRenderer.invoke("prompt:optimize", payload),
  readClipboardText: () => ipcRenderer.invoke("clipboard:readText"),
  writeClipboardText: (text) => ipcRenderer.invoke("clipboard:writeText", text),
  listHistory: () => ipcRenderer.invoke("history:list"),
  appendHistory: (payload) => ipcRenderer.invoke("history:append", payload),
  deleteHistory: (ids) => ipcRenderer.invoke("history:delete", ids),
  clearHistory: () => ipcRenderer.invoke("history:clear"),
  onClipboardText: (callback) => {
    const listener = (_event, text) => callback(text);
    ipcRenderer.on("clipboard-text", listener);
    return () => ipcRenderer.removeListener("clipboard-text", listener);
  }
});
