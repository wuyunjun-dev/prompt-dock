const test = require("node:test");
const assert = require("node:assert/strict");
const { complete, parseAPIErrorMessage } = require("../src/shared/api-client");

test("request body and response parsing are OpenAI-compatible", async () => {
  const result = await complete({
    systemPrompt: "system",
    userPrompt: "user",
    apiKey: "secret-key",
    configuration: {
      baseURL: "https://example.test/v1",
      modelName: "model-a",
      temperature: 0.3,
      maxTokens: 2000,
      extraHeaders: {
        Authorization: "Basic should-not-override",
        "X-Test": "yes"
      }
    },
    fetchImpl: async (url, request) => {
      assert.equal(url, "https://example.test/v1/chat/completions");
      assert.equal(request.method, "POST");
      assert.equal(request.headers.Authorization, "Bearer secret-key");
      assert.equal(request.headers["X-Test"], "yes");

      const body = JSON.parse(request.body);
      assert.equal(body.model, "model-a");
      assert.equal(body.temperature, 0.3);
      assert.equal(body.max_tokens, 2000);
      assert.deepEqual(body.messages, [
        { role: "system", content: "system" },
        { role: "user", content: "user" }
      ]);

      return response(200, {
        choices: [{ message: { content: "Optimized prompt" } }]
      });
    }
  });

  assert.equal(result, "Optimized prompt");
});

test("content parts are joined", async () => {
  const result = await complete({
    systemPrompt: "system",
    userPrompt: "user",
    apiKey: "secret-key",
    configuration: {
      baseURL: "https://example.test/v1",
      modelName: "model-a"
    },
    fetchImpl: async () => response(200, {
      choices: [{ message: { content: [{ type: "text", text: "Part one" }, { type: "text", text: "Part two" }] } }]
    })
  });

  assert.equal(result, "Part one\nPart two");
});

test("missing API key throws before request", async () => {
  await assert.rejects(() => complete({
    systemPrompt: "system",
    userPrompt: "user",
    apiKey: " ",
    configuration: {
      baseURL: "https://example.test/v1",
      modelName: "model-a"
    },
    fetchImpl: async () => {
      throw new Error("should not be called");
    }
  }), /尚未配置 API 密钥/);
});

test("non-2xx response becomes sanitized API error", async () => {
  await assert.rejects(() => complete({
    systemPrompt: "system",
    userPrompt: "user",
    apiKey: "secret-key",
    configuration: {
      baseURL: "https://example.test/v1",
      modelName: "model-a"
    },
    fetchImpl: async () => ({
      ok: false,
      status: 500,
      text: async () => "Authorization: Bearer leaked-token failed"
    })
  }), (error) => {
    assert.match(error.message, /500/);
    assert.match(error.message, /\[REDACTED\]/);
    assert.doesNotMatch(error.message, /leaked-token/);
    return true;
  });
});

test("empty model response throws", async () => {
  await assert.rejects(() => complete({
    systemPrompt: "system",
    userPrompt: "user",
    apiKey: "secret-key",
    configuration: {
      baseURL: "https://example.test/v1",
      modelName: "model-a"
    },
    fetchImpl: async () => response(200, {
      choices: [{ message: { content: "   " } }]
    })
  }), /模型返回了空内容/);
});

test("plain and json API errors are parsed", () => {
  assert.equal(parseAPIErrorMessage('{"error":{"message":"Unauthorized"}}'), "Unauthorized");
  assert.equal(parseAPIErrorMessage("Bearer hidden"), "Bearer [REDACTED]");
});

function response(status, body) {
  return {
    ok: status >= 200 && status <= 299,
    status,
    text: async () => JSON.stringify(body)
  };
}
