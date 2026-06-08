const promptModes = [
  { id: "codexDevelopment", displayName: "Codex 开发任务" },
  { id: "bugFix", displayName: "Bug 修复提示词" },
  { id: "refactor", displayName: "重构提示词" },
  { id: "codeReview", displayName: "代码审查提示词" },
  { id: "requirementBreakdown", displayName: "需求拆解提示词" },
  { id: "generalOptimization", displayName: "通用提示词优化" }
];

const targetTools = [
  { id: "codex", displayName: "Codex" },
  { id: "claudeCode", displayName: "Claude Code" },
  { id: "cursor", displayName: "Cursor" },
  { id: "chatGPT", displayName: "ChatGPT" },
  { id: "genericAgent", displayName: "通用 Agent" }
];

function displayName(items, id) {
  return items.find((item) => item.id === id)?.displayName ?? id;
}

module.exports = {
  promptModes,
  targetTools,
  displayName
};
