const modeOptions = [
  ["codexDevelopment", "Codex 开发任务"],
  ["bugFix", "Bug 修复提示词"],
  ["refactor", "重构提示词"],
  ["codeReview", "代码审查提示词"],
  ["requirementBreakdown", "需求拆解提示词"],
  ["generalOptimization", "通用提示词优化"]
];

const targetOptions = [
  ["codex", "Codex"],
  ["claudeCode", "Claude Code"],
  ["cursor", "Cursor"],
  ["chatGPT", "ChatGPT"],
  ["genericAgent", "通用 Agent"]
];

const state = {
  configuration: null,
  hasStoredAPIKey: false,
  historyItems: [],
  lastRequest: null,
  lastResult: null,
  selectedHistoryIds: new Set()
};

const $ = (id) => document.getElementById(id);

function optionLabel(options, id) {
  return options.find(([value]) => value === id)?.[1] ?? id;
}

function fillSelect(select, options) {
  select.innerHTML = "";
  for (const [value, label] of options) {
    const option = document.createElement("option");
    option.value = value;
    option.textContent = label;
    select.append(option);
  }
}

function setMessage(text, isError = false) {
  $("message").textContent = text || "";
  $("message").classList.toggle("error", isError);
}

function setSettingsMessage(text, isError = false) {
  $("settingsMessage").textContent = text || "";
  $("settingsMessage").classList.toggle("error", isError);
}

function showTab(tabName) {
  document.querySelectorAll(".tab").forEach((button) => {
    button.classList.toggle("active", button.dataset.tab === tabName);
  });
  $("optimizePanel").classList.toggle("active", tabName === "optimize");
  $("historyPanel").classList.toggle("active", tabName === "history");
}

function parseHeaders(text) {
  const headers = {};
  for (const line of String(text ?? "").split(/\r?\n/)) {
    const index = line.indexOf(":");
    if (index < 0) continue;
    const key = line.slice(0, index).trim();
    const value = line.slice(index + 1).trim();
    if (!key || !value) continue;
    if (key.toLowerCase() === "authorization") continue;
    headers[key] = value;
  }
  return headers;
}

function headersToText(headers) {
  return Object.entries(headers ?? {})
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([key, value]) => `${key}: ${value}`)
    .join("\n");
}

function configurationFromForm() {
  return {
    providerName: $("providerName").value,
    baseURL: $("baseURL").value,
    modelName: $("modelName").value,
    temperature: Number($("temperature").value),
    maxTokens: Number.parseInt($("maxTokens").value, 10),
    extraHeaders: parseHeaders($("extraHeaders").value)
  };
}

function loadSettingsForm() {
  const configuration = state.configuration;
  $("providerName").value = configuration.providerName;
  $("baseURL").value = configuration.baseURL;
  $("modelName").value = configuration.modelName;
  $("temperature").value = configuration.temperature;
  $("maxTokens").value = configuration.maxTokens;
  $("extraHeaders").value = headersToText(configuration.extraHeaders);
  $("apiKey").value = "";
  $("apiKey").placeholder = state.hasStoredAPIKey ? "新的 API Key" : "API Key";
  $("apiKeyHint").textContent = state.hasStoredAPIKey
    ? "已保存 API Key。留空可保留现有值。"
    : "尚未保存 API Key。";
}

function renderHistory() {
  const list = $("historyList");
  list.innerHTML = "";
  state.selectedHistoryIds = new Set([...state.selectedHistoryIds].filter((id) => state.historyItems.some((item) => item.id === id)));
  $("deleteSelectedButton").disabled = state.selectedHistoryIds.size === 0;
  $("selectAllHistoryButton").textContent =
    state.historyItems.length > 0 && state.selectedHistoryIds.size === state.historyItems.length ? "取消全选" : "全选";

  if (state.historyItems.length === 0) {
    const empty = document.createElement("div");
    empty.className = "history-empty";
    empty.textContent = "暂无历史记录";
    list.append(empty);
    return;
  }

  for (const item of state.historyItems) {
    const row = document.createElement("article");
    row.className = "history-item";

    const checkbox = document.createElement("input");
    checkbox.type = "checkbox";
    checkbox.checked = state.selectedHistoryIds.has(item.id);
    checkbox.addEventListener("change", () => {
      if (checkbox.checked) state.selectedHistoryIds.add(item.id);
      else state.selectedHistoryIds.delete(item.id);
      renderHistory();
    });

    const body = document.createElement("div");

    const meta = document.createElement("div");
    meta.className = "history-meta";
    const date = item.createdAt ? new Date(item.createdAt).toLocaleString() : "";
    meta.textContent = `${optionLabel(modeOptions, item.request?.mode)} · ${optionLabel(targetOptions, item.request?.targetTool)} · ${date}`;

    const text = document.createElement("div");
    text.className = "history-text";
    text.textContent = item.result?.optimizedPrompt ?? "";

    const actions = document.createElement("div");
    actions.className = "row-actions";
    actions.append(
      makeButton("载入", () => useHistoryItem(item)),
      makeButton("复制", () => copyText(item.result?.optimizedPrompt ?? "")),
      makeButton("删除", () => deleteHistory([item.id]), "danger")
    );

    body.append(meta, text, actions);
    row.append(checkbox, body);
    list.append(row);
  }
}

function makeButton(label, onClick, className = "") {
  const button = document.createElement("button");
  button.textContent = label;
  if (className) button.className = className;
  button.addEventListener("click", onClick);
  return button;
}

async function refreshHistory() {
  state.historyItems = await window.promptDock.listHistory();
  renderHistory();
}

async function copyText(text) {
  if (!text) return;
  await window.promptDock.writeClipboardText(text);
  setMessage("结果已复制。");
}

function useHistoryItem(item) {
  $("rawInput").value = item.request?.rawInput ?? "";
  $("optimizedOutput").value = item.result?.optimizedPrompt ?? "";
  $("modeSelect").value = item.request?.mode ?? "codexDevelopment";
  $("targetSelect").value = item.request?.targetTool ?? "codex";
  state.lastRequest = item.request;
  state.lastResult = item.result;
  showTab("optimize");
  setMessage("已载入历史记录。");
}

async function optimizeCurrentInput() {
  setMessage("正在优化...");
  $("optimizeButton").disabled = true;
  try {
    const response = await window.promptDock.optimize({
      rawInput: $("rawInput").value,
      mode: $("modeSelect").value,
      targetTool: $("targetSelect").value
    });
    state.lastRequest = response.request;
    state.lastResult = response.result;
    $("optimizedOutput").value = response.result.optimizedPrompt;
    setMessage("优化完成。");
  } catch (error) {
    setMessage(error.message, true);
  } finally {
    $("optimizeButton").disabled = false;
  }
}

async function optimizeClipboard() {
  const text = (await window.promptDock.readClipboardText()).trim();
  if (!text) {
    setMessage("剪贴板中没有文本。", true);
    return;
  }
  $("rawInput").value = text;
  await optimizeCurrentInput();
}

async function saveHistory() {
  if (!state.lastRequest || !state.lastResult) {
    setMessage("当前没有可保存的结果。", true);
    return;
  }
  state.historyItems = await window.promptDock.appendHistory({
    request: state.lastRequest,
    result: state.lastResult
  });
  renderHistory();
  setMessage("已保存到历史记录。");
}

async function deleteHistory(ids) {
  const confirmed = ids.length === 1
    ? confirm("确定删除这条历史记录吗？")
    : confirm(`确定删除选中的 ${ids.length} 条历史记录吗？`);
  if (!confirmed) return;

  const response = await window.promptDock.deleteHistory(ids);
  state.historyItems = response.historyItems;
  state.selectedHistoryIds.clear();
  renderHistory();
  setMessage(response.deletedCount > 0 ? `已删除 ${response.deletedCount} 条历史记录。` : "没有删除任何历史记录。");
}

async function saveSettings() {
  setSettingsMessage("正在保存...");
  try {
    const response = await window.promptDock.saveSettings({
      configuration: configurationFromForm(),
      apiKey: $("apiKey").value
    });
    state.configuration = response.configuration;
    state.hasStoredAPIKey = response.hasStoredAPIKey;
    loadSettingsForm();
    setSettingsMessage("设置已保存。");
  } catch (error) {
    setSettingsMessage(error.message, true);
  }
}

async function testConnection() {
  setSettingsMessage("正在测试连接...");
  $("testConnectionButton").disabled = true;
  try {
    const message = await window.promptDock.testConnection({
      configuration: configurationFromForm(),
      apiKey: $("apiKey").value
    });
    setSettingsMessage(message);
  } catch (error) {
    setSettingsMessage(error.message, true);
  } finally {
    $("testConnectionButton").disabled = false;
  }
}

async function clearAPIKey() {
  if (!confirm("确定清除已保存的 API Key 吗？")) return;
  const response = await window.promptDock.clearAPIKey();
  state.hasStoredAPIKey = response.hasStoredAPIKey;
  loadSettingsForm();
  setSettingsMessage("API Key 已清除。");
}

async function clearHistory() {
  if (!confirm("确定清空所有历史记录吗？")) return;
  state.historyItems = await window.promptDock.clearHistory();
  state.selectedHistoryIds.clear();
  renderHistory();
  setSettingsMessage("历史记录已清空。");
}

function bindEvents() {
  document.querySelectorAll(".tab").forEach((button) => {
    button.addEventListener("click", () => showTab(button.dataset.tab));
  });
  $("settingsButton").addEventListener("click", () => {
    loadSettingsForm();
    setSettingsMessage("");
    $("settingsDialog").showModal();
  });
  $("closeSettingsButton").addEventListener("click", () => $("settingsDialog").close());
  $("optimizeButton").addEventListener("click", optimizeCurrentInput);
  $("clipboardButton").addEventListener("click", optimizeClipboard);
  $("copyButton").addEventListener("click", () => copyText($("optimizedOutput").value));
  $("saveHistoryButton").addEventListener("click", saveHistory);
  $("clearButton").addEventListener("click", () => {
    $("rawInput").value = "";
    $("optimizedOutput").value = "";
    state.lastRequest = null;
    state.lastResult = null;
    setMessage("");
  });
  $("reloadHistoryButton").addEventListener("click", refreshHistory);
  $("selectAllHistoryButton").addEventListener("click", () => {
    if (state.historyItems.length > 0 && state.selectedHistoryIds.size === state.historyItems.length) {
      state.selectedHistoryIds.clear();
    } else {
      state.selectedHistoryIds = new Set(state.historyItems.map((item) => item.id));
    }
    renderHistory();
  });
  $("deleteSelectedButton").addEventListener("click", () => deleteHistory([...state.selectedHistoryIds]));
  $("saveSettingsButton").addEventListener("click", saveSettings);
  $("testConnectionButton").addEventListener("click", testConnection);
  $("clearAPIKeyButton").addEventListener("click", clearAPIKey);
  $("clearHistoryButton").addEventListener("click", clearHistory);
  window.promptDock.onClipboardText((text) => {
    if (text) {
      $("rawInput").value = text;
      setMessage("已载入剪贴板文本。");
      showTab("optimize");
    }
  });
}

async function init() {
  fillSelect($("modeSelect"), modeOptions);
  fillSelect($("targetSelect"), targetOptions);
  bindEvents();
  const bootstrap = await window.promptDock.bootstrap();
  state.configuration = bootstrap.configuration;
  state.historyItems = bootstrap.historyItems;
  state.hasStoredAPIKey = bootstrap.hasStoredAPIKey;
  renderHistory();
  setMessage("准备就绪。");
}

init().catch((error) => {
  setMessage(error.message, true);
});
