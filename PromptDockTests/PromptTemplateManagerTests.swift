import XCTest
@testable import PromptDock

final class PromptTemplateManagerTests: XCTestCase {
    func testDifferentModesProduceDifferentUserPrompts() {
        let manager = PromptTemplateManager()
        let baseInput = "Build a todo app with add and delete."

        let codexPrompt = manager.makeUserPrompt(
            for: PromptOptimizationRequest(
                rawInput: baseInput,
                mode: .codexDevelopment,
                targetTool: .codex
            )
        )

        let reviewPrompt = manager.makeUserPrompt(
            for: PromptOptimizationRequest(
                rawInput: baseInput,
                mode: .codeReview,
                targetTool: .codex
            )
        )

        XCTAssertNotEqual(codexPrompt, reviewPrompt)
        XCTAssertTrue(reviewPrompt.localizedCaseInsensitiveContains("prioritized findings"))
        XCTAssertTrue(reviewPrompt.localizedCaseInsensitiveContains("security and privacy"))
    }

    func testDifferentTargetsProduceDifferentUserPrompts() {
        let manager = PromptTemplateManager()
        let request = PromptOptimizationRequest(
            rawInput: "Refactor the networking layer.",
            mode: .refactor,
            targetTool: .codex
        )

        let codexPrompt = manager.makeUserPrompt(for: request)
        let cursorPrompt = manager.makeUserPrompt(
            for: PromptOptimizationRequest(
                rawInput: request.rawInput,
                mode: request.mode,
                targetTool: .cursor
            )
        )

        XCTAssertNotEqual(codexPrompt, cursorPrompt)
        XCTAssertTrue(codexPrompt.localizedCaseInsensitiveContains("inspect the repository"))
        XCTAssertTrue(cursorPrompt.localizedCaseInsensitiveContains("IDE coding workflow"))
    }

    func testCodexModeContainsRequiredSections() {
        let manager = PromptTemplateManager()
        let prompt = manager.makeUserPrompt(
            for: PromptOptimizationRequest(
                rawInput: "Add search to the app.",
                mode: .codexDevelopment,
                targetTool: .codex
            )
        )

        XCTAssertTrue(prompt.localizedCaseInsensitiveContains("inspect the repository"))
        XCTAssertTrue(prompt.localizedCaseInsensitiveContains("Validation"))
        XCTAssertTrue(prompt.localizedCaseInsensitiveContains("Deliverables"))
    }
}
