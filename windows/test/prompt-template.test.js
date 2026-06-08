const test = require("node:test");
const assert = require("node:assert/strict");
const { makeUserPrompt } = require("../src/shared/prompt-template");

test("different modes produce different prompts", () => {
  const rawInput = "Build a todo app with add and delete.";
  const codexPrompt = makeUserPrompt({
    rawInput,
    mode: "codexDevelopment",
    targetTool: "codex"
  });
  const reviewPrompt = makeUserPrompt({
    rawInput,
    mode: "codeReview",
    targetTool: "codex"
  });

  assert.notEqual(codexPrompt, reviewPrompt);
  assert.match(reviewPrompt, /prioritized findings/i);
  assert.match(reviewPrompt, /security and privacy/i);
});

test("different targets produce different prompts", () => {
  const codexPrompt = makeUserPrompt({
    rawInput: "Refactor the networking layer.",
    mode: "refactor",
    targetTool: "codex"
  });
  const cursorPrompt = makeUserPrompt({
    rawInput: "Refactor the networking layer.",
    mode: "refactor",
    targetTool: "cursor"
  });

  assert.notEqual(codexPrompt, cursorPrompt);
  assert.match(codexPrompt, /inspect the repository/i);
  assert.match(cursorPrompt, /IDE coding workflow/i);
});
