import Foundation

struct PromptTemplateManager {
    let systemPrompt = """
    You are an expert prompt architect for AI coding agents. Your job is to rewrite rough user intentions into precise, executable prompts for coding agents such as Codex, Claude Code, Cursor, ChatGPT, and other software engineering assistants.

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

    Do not include unnecessary commentary before or after the optimized prompt unless explicitly requested.
    """

    func makeUserPrompt(
        for request: PromptOptimizationRequest,
        userPreferences: String? = nil
    ) -> String {
        let rawInput = request.rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let context = request.optionalContext?.trimmingCharacters(in: .whitespacesAndNewlines)
        let preferences = userPreferences?.trimmingCharacters(in: .whitespacesAndNewlines)

        return """
        Rewrite the following rough request into a clear, executable prompt for \(request.targetTool.displayName).

        Mode: \(request.mode.displayName)
        Target tool: \(request.targetTool.displayName)

        Target-specific guidance:
        \(targetGuidance(for: request.targetTool))

        Mode-specific requirements:
        \(modeGuidance(for: request.mode))

        Required output shape:
        \(outputShape(for: request.mode))

        Original user input:
        \(rawInput)

        Optional context:
        \(context?.isEmpty == false ? context! : "None provided.")

        User preferences:
        \(preferences?.isEmpty == false ? preferences! : "None provided.")

        Return only the optimized prompt. It must preserve the user's intent, state important assumptions, and avoid unrelated work.
        """
    }

    private func targetGuidance(for targetTool: TargetTool) -> String {
        switch targetTool {
        case .codex:
            return """
            - Make the prompt suitable for Codex.
            - Tell the agent to inspect the repository first and identify the existing architecture.
            - Ask the agent to make a concise plan before editing.
            - Keep changes scoped and high-confidence.
            - Ask the agent to run available tests or build commands.
            - Require a final summary of changed files, validation, deliverables, and commands that could not be run.
            """
        case .claudeCode:
            return """
            - Make the prompt suitable for Claude Code.
            - Ask for repository inspection, concise reasoning, small edits, and clear validation.
            - Prefer direct implementation steps over broad brainstorming.
            """
        case .cursor:
            return """
            - Make the prompt suitable for Cursor.
            - Include enough file and behavior context for an IDE coding workflow.
            - Ask for minimal edits and explicit validation steps.
            """
        case .chatGPT:
            return """
            - Make the prompt suitable for ChatGPT as a coding assistant.
            - Ask for assumptions, implementation guidance, and test or verification steps.
            - Keep the requested answer directly actionable.
            """
        case .genericAgent:
            return """
            - Make the prompt suitable for a generic AI coding agent.
            - Include objective, constraints, implementation plan, validation, and deliverables.
            """
        }
    }

    private func modeGuidance(for mode: PromptMode) -> String {
        switch mode {
        case .codexDevelopment:
            return """
            - Produce a development-task prompt that can be pasted directly into Codex.
            - Include Task, Context, Requirements, Constraints, Implementation Plan, Validation, and Deliverables.
            - Require repository inspection before changes.
            """
        case .bugFix:
            return """
            - Include steps to reproduce the issue.
            - Locate the root cause before changing code.
            - Propose a minimal fix.
            - Add or update tests if possible.
            - Avoid unrelated refactors.
            """
        case .refactor:
            return """
            - Preserve existing behavior.
            - Identify the current architecture.
            - Refactor in small steps.
            - Keep public APIs stable unless a change is necessary.
            - Run regression tests.
            """
        case .codeReview:
            return """
            - Review for correctness.
            - Review for edge cases.
            - Review for security and privacy risks.
            - Review for maintainability.
            - Provide prioritized findings.
            """
        case .requirementBreakdown:
            return """
            - Convert the idea into milestones.
            - Separate MVP from later enhancements.
            - List assumptions.
            - Define acceptance criteria.
            """
        case .generalOptimization:
            return """
            - Make the prompt clear, structured, and executable.
            - Preserve the user's original intent.
            - Add constraints and validation where helpful.
            """
        }
    }

    private func outputShape(for mode: PromptMode) -> String {
        switch mode {
        case .codexDevelopment:
            return """
            Task
            Context
            Requirements
            Constraints
            Implementation Plan
            Validation
            Deliverables
            """
        case .bugFix:
            return """
            Task
            Reproduction
            Root Cause Investigation
            Minimal Fix Requirements
            Validation
            Deliverables
            """
        case .refactor:
            return """
            Task
            Current Architecture
            Refactor Scope
            Constraints
            Step-by-step Plan
            Regression Validation
            Deliverables
            """
        case .codeReview:
            return """
            Review Scope
            Correctness
            Edge Cases
            Security and Privacy
            Maintainability
            Prioritized Findings
            """
        case .requirementBreakdown:
            return """
            Objective
            Assumptions
            MVP Milestones
            Later Enhancements
            Acceptance Criteria
            Risks
            """
        case .generalOptimization:
            return """
            Task
            Context
            Requirements
            Constraints
            Validation
            Deliverables
            """
        }
    }
}
