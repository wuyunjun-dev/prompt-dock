const { displayName, promptModes, targetTools } = require("./prompt-options");

const systemPrompt = `You are an expert prompt architect for AI coding agents. Your job is to rewrite rough user intentions into precise, executable prompts for coding agents such as Codex, Claude Code, Cursor, ChatGPT, and other software engineering assistants.

Your output must be practical, specific, and directly usable.

When rewriting a prompt:
1. Clarify the objective.
2. Add relevant technical constraints.
3. Ask the agent to inspect the existing repository before changing code.
4. Require minimal, high-confidence changes unless the user asks for a large redesign.
5. Require tests or validation steps.
6. Require the agent to explain important assumptions.
7. Avoid vague language.
8. Avoid overengineering.
9. Preserve the user's original intent.
10. If the input is underspecified, make reasonable assumptions and state them inside the generated prompt.

Default output format:
- Task
- Context
- Requirements
- Constraints
- Implementation Plan
- Validation
- Deliverables

For Codex-specific prompts, emphasize:
- inspect the repository first
- identify existing architecture
- make a plan before editing
- keep changes scoped
- run available tests/build commands
- summarize changed files
- mention any commands that could not be run

Do not include unnecessary commentary before or after the optimized prompt unless explicitly requested.`;

function targetGuidance(targetTool) {
  switch (targetTool) {
    case "codex":
      return `- Make the prompt suitable for Codex.
- Tell the agent to inspect the repository first and identify the existing architecture.
- Ask the agent to make a concise plan before editing.
- Keep changes scoped and high-confidence.
- Ask the agent to run available tests or build commands.
- Require a final summary of changed files, validation, deliverables, and commands that could not be run.`;
    case "claudeCode":
      return `- Make the prompt suitable for Claude Code.
- Ask for repository inspection, concise reasoning, small edits, and clear validation.
- Prefer direct implementation steps over broad brainstorming.`;
    case "cursor":
      return `- Make the prompt suitable for Cursor.
- Include enough file and behavior context for an IDE coding workflow.
- Ask for minimal edits and explicit validation steps.`;
    case "chatGPT":
      return `- Make the prompt suitable for ChatGPT as a coding assistant.
- Ask for assumptions, implementation guidance, and test or verification steps.
- Keep the requested answer directly actionable.`;
    default:
      return `- Make the prompt suitable for a generic AI coding agent.
- Include objective, constraints, implementation plan, validation, and deliverables.`;
  }
}

function modeGuidance(mode) {
  switch (mode) {
    case "codexDevelopment":
      return `- Produce a development-task prompt that can be pasted directly into Codex.
- Include Task, Context, Requirements, Constraints, Implementation Plan, Validation, and Deliverables.
- Require repository inspection before changes.`;
    case "bugFix":
      return `- Include steps to reproduce the issue.
- Locate the root cause before changing code.
- Propose a minimal fix.
- Add or update tests if possible.
- Avoid unrelated refactors.`;
    case "refactor":
      return `- Preserve existing behavior.
- Identify the current architecture.
- Refactor in small steps.
- Keep public APIs stable unless a change is necessary.
- Run regression tests.`;
    case "codeReview":
      return `- Review for correctness.
- Review for edge cases.
- Review for security and privacy risks.
- Review for maintainability.
- Provide prioritized findings.`;
    case "requirementBreakdown":
      return `- Convert the idea into milestones.
- Separate MVP from later enhancements.
- List assumptions.
- Define acceptance criteria.`;
    default:
      return `- Make the prompt clear, structured, and executable.
- Preserve the user's original intent.
- Add constraints and validation where helpful.`;
  }
}

function outputShape(mode) {
  switch (mode) {
    case "codexDevelopment":
      return "Task\nContext\nRequirements\nConstraints\nImplementation Plan\nValidation\nDeliverables";
    case "bugFix":
      return "Task\nReproduction\nRoot Cause Investigation\nMinimal Fix Requirements\nValidation\nDeliverables";
    case "refactor":
      return "Task\nCurrent Architecture\nRefactor Scope\nConstraints\nStep-by-step Plan\nRegression Validation\nDeliverables";
    case "codeReview":
      return "Review Scope\nCorrectness\nEdge Cases\nSecurity and Privacy\nMaintainability\nPrioritized Findings";
    case "requirementBreakdown":
      return "Objective\nAssumptions\nMVP Milestones\nLater Enhancements\nAcceptance Criteria\nRisks";
    default:
      return "Task\nContext\nRequirements\nConstraints\nValidation\nDeliverables";
  }
}

function makeUserPrompt(request, userPreferences = "") {
  const rawInput = String(request.rawInput ?? "").trim();
  const optionalContext = String(request.optionalContext ?? "").trim();
  const preferences = String(userPreferences ?? "").trim();
  const mode = request.mode || "codexDevelopment";
  const targetTool = request.targetTool || "codex";

  return `Rewrite the following rough request into a clear, executable prompt for ${displayName(targetTools, targetTool)}.

Mode: ${displayName(promptModes, mode)}
Target tool: ${displayName(targetTools, targetTool)}

Target-specific guidance:
${targetGuidance(targetTool)}

Mode-specific requirements:
${modeGuidance(mode)}

Required output shape:
${outputShape(mode)}

Original user input:
${rawInput}

Optional context:
${optionalContext || "None provided."}

User preferences:
${preferences || "None provided."}

Return only the optimized prompt. It must preserve the user's intent, state important assumptions, and avoid unrelated work.`;
}

module.exports = {
  makeUserPrompt,
  modeGuidance,
  outputShape,
  systemPrompt,
  targetGuidance
};
