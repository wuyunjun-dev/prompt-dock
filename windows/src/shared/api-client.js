const { chatCompletionsEndpoint, validatedConfiguration } = require("./api-configuration");
const { limitForDisplay, sanitizeMessage } = require("./sanitize");

function appError(message) {
  return new Error(message);
}

function parseContent(content) {
  if (typeof content === "string") {
    return content;
  }
  if (Array.isArray(content)) {
    return content
      .map((part) => {
        if (typeof part === "string") return part;
        if (part && typeof part.text === "string") return part.text;
        return "";
      })
      .filter(Boolean)
      .join("\n");
  }
  return "";
}

function parseAPIErrorMessage(text) {
  const trimmed = String(text ?? "").trim();
  if (!trimmed) return "";

  try {
    const decoded = JSON.parse(trimmed);
    const message = decoded?.error?.message ?? decoded?.message ?? decoded?.error;
    if (typeof message === "string" && message.trim()) {
      return limitForDisplay(sanitizeMessage(message.trim()));
    }
  } catch {
    // Fall through to raw text.
  }

  return limitForDisplay(sanitizeMessage(trimmed));
}

async function complete({ systemPrompt, userPrompt, configuration, apiKey, fetchImpl = globalThis.fetch }) {
  const config = validatedConfiguration(configuration);
  const key = String(apiKey ?? "").trim();
  if (!key) {
    throw appError("尚未配置 API 密钥。请先在设置中添加。");
  }
  if (typeof fetchImpl !== "function") {
    throw appError("当前运行环境不支持网络请求。");
  }

  const headers = {
    "Content-Type": "application/json",
    Accept: "application/json",
    Authorization: `Bearer ${key}`,
    ...config.extraHeaders
  };
  delete headers.authorization;
  delete headers.Authorization;
  headers.Authorization = `Bearer ${key}`;

  const body = {
    model: config.modelName,
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: userPrompt }
    ],
    temperature: config.temperature,
    max_tokens: config.maxTokens
  };

  let response;
  try {
    response = await fetchImpl(chatCompletionsEndpoint(config.baseURL), {
      method: "POST",
      headers,
      body: JSON.stringify(body)
    });
  } catch (error) {
    throw appError(`网络请求失败：${limitForDisplay(sanitizeMessage(error?.message ?? error))}`);
  }

  const responseText = await response.text();
  if (!response.ok) {
    const message = parseAPIErrorMessage(responseText);
    throw appError(message ? `API 返回 HTTP ${response.status}：${message}` : `API 返回 HTTP ${response.status}。`);
  }

  let decoded;
  try {
    decoded = JSON.parse(responseText);
  } catch {
    throw appError("无法解析 API 响应。");
  }

  const content = parseContent(decoded?.choices?.[0]?.message?.content).trim();
  if (!content) {
    throw appError("模型返回了空内容。");
  }
  return content;
}

module.exports = {
  complete,
  parseAPIErrorMessage,
  parseContent
};
