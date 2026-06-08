const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs/promises");
const os = require("node:os");
const path = require("node:path");
const { HistoryStore } = require("../src/shared/history-store");

test("save, load, delete and clear history", async () => {
  const directory = await fs.mkdtemp(path.join(os.tmpdir(), "promptdock-history-"));
  const store = new HistoryStore(path.join(directory, "history.json"));

  const request = {
    rawInput: "Build a todo app.",
    mode: "codexDevelopment",
    targetTool: "codex",
    createdAt: "2026-06-08T00:00:00.000Z"
  };
  const result = {
    optimizedPrompt: "Task\nBuild a todo app.",
    rationale: null,
    suggestedNextSteps: null
  };

  const first = await store.append(request, result);
  const second = await store.append({ ...request, rawInput: "Second" }, { ...result, optimizedPrompt: "Second" });

  assert.equal((await store.load()).length, 2);
  assert.equal(await store.delete([first.id]), 1);
  assert.deepEqual((await store.load()).map((item) => item.id), [second.id]);

  await store.clear();
  assert.deepEqual(await store.load(), []);
});
