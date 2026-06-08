const DEFAULT_CONFIGURATION = {
  providerName: "OpenAI 兼容",
  baseURL: "https://api.openai.com/v1",
  modelName: "gpt-4.1-mini",
  temperature: 0.3,
  maxTokens: 2000,
  extraHeaders: {}
};

function normalizedBaseURL(baseURL) {
  const value = String(baseURL ?? "").trim();
  try {
    const url = new URL(value);
    const scheme = url.protocol.toLowerCase();
    if ((scheme !== "http:" && scheme !== "https:") || !url.hostname) {
      return null;
    }
    return url;
  } catch {
    return null;
  }
}

function isValidBaseURL(baseURL) {
  return normalizedBaseURL(baseURL) !== null;
}

function sanitizeExtraHeaders(headers) {
  const result = {};
  for (const [rawKey, rawValue] of Object.entries(headers ?? {})) {
    const key = String(rawKey).trim();
    const value = String(rawValue).trim();
    if (!key || !value) continue;
    if (key.toLowerCase() === "authorization") continue;
    result[key] = value;
  }
  return result;
}

function validatedConfiguration(configuration = {}) {
  const merged = {
    ...DEFAULT_CONFIGURATION,
    ...configuration
  };

  if (!isValidBaseURL(merged.baseURL)) {
    throw new Error("基础 URL 无效。请使用完整地址，例如 https://api.example.com/v1。");
  }

  const modelName = String(merged.modelName ?? "").trim();
  if (!modelName) {
    throw new Error("必须填写模型名称。");
  }

  const temperature = Number(merged.temperature);
  const maxTokens = Number.parseInt(merged.maxTokens, 10);

  return {
    providerName: String(merged.providerName ?? DEFAULT_CONFIGURATION.providerName).trim() || DEFAULT_CONFIGURATION.providerName,
    baseURL: String(merged.baseURL).trim(),
    modelName,
    temperature: Number.isFinite(temperature) ? Math.min(Math.max(temperature, 0), 2) : DEFAULT_CONFIGURATION.temperature,
    maxTokens: Number.isFinite(maxTokens) ? Math.max(maxTokens, 1) : DEFAULT_CONFIGURATION.maxTokens,
    extraHeaders: sanitizeExtraHeaders(merged.extraHeaders)
  };
}

function chatCompletionsEndpoint(baseURL) {
  const url = normalizedBaseURL(baseURL);
  if (!url) {
    throw new Error("基础 URL 无效。请使用完整地址，例如 https://api.example.com/v1。");
  }

  const path = url.pathname.replace(/\/+$/, "");
  if (path.toLowerCase().endsWith("/chat/completions")) {
    url.pathname = path;
  } else {
    url.pathname = `${path}/chat/completions`;
  }
  url.hash = "";
  return url.toString();
}

module.exports = {
  DEFAULT_CONFIGURATION,
  chatCompletionsEndpoint,
  isValidBaseURL,
  sanitizeExtraHeaders,
  validatedConfiguration
};
