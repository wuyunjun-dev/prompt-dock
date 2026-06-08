const test = require("node:test");
const assert = require("node:assert/strict");
const {
  DEFAULT_CONFIGURATION,
  chatCompletionsEndpoint,
  sanitizeExtraHeaders,
  validatedConfiguration
} = require("../src/shared/api-configuration");

test("default configuration is valid", () => {
  const configuration = validatedConfiguration(DEFAULT_CONFIGURATION);
  assert.equal(configuration.providerName, "OpenAI 兼容");
  assert.equal(configuration.baseURL, "https://api.openai.com/v1");
  assert.equal(configuration.modelName, "gpt-4.1-mini");
});

test("invalid base URL is rejected", () => {
  assert.throws(() => validatedConfiguration({ baseURL: "not a url" }), /基础 URL 无效/);
});

test("temperature and max tokens are clamped", () => {
  const configuration = validatedConfiguration({
    ...DEFAULT_CONFIGURATION,
    temperature: 8,
    maxTokens: -20
  });
  assert.equal(configuration.temperature, 2);
  assert.equal(configuration.maxTokens, 1);
});

test("authorization extra header is ignored", () => {
  const headers = sanitizeExtraHeaders({
    Authorization: "Basic no",
    "X-Test": "yes"
  });
  assert.deepEqual(headers, {
    "X-Test": "yes"
  });
});

test("chat completions endpoint is appended once", () => {
  assert.equal(chatCompletionsEndpoint("https://example.test/v1"), "https://example.test/v1/chat/completions");
  assert.equal(chatCompletionsEndpoint("https://example.test/v1/chat/completions"), "https://example.test/v1/chat/completions");
});
