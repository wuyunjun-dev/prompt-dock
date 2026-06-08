import XCTest
@testable import PromptDock

final class HistoryStoreTests: XCTestCase {
    func testSaveLoadAndClearHistory() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("history.json")
        let store = HistoryStore(fileURL: fileURL)
        defer {
            try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
        }

        let request = PromptOptimizationRequest(
            rawInput: "Build a todo app.",
            mode: .codexDevelopment,
            targetTool: .codex,
            createdAt: Date(timeIntervalSince1970: 100)
        )
        let result = PromptOptimizationResult(
            optimizedPrompt: "Task\nBuild a todo app.",
            rationale: nil,
            suggestedNextSteps: nil
        )
        let item = HistoryItem(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            request: request,
            result: result,
            createdAt: Date(timeIntervalSince1970: 200)
        )

        try store.append(item)
        let loaded = try store.load()

        XCTAssertEqual(loaded, [item])

        try store.clear()
        XCTAssertEqual(try store.load(), [])
    }

    func testDeleteHistoryItem() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("history.json")
        let store = HistoryStore(fileURL: fileURL)
        defer {
            try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
        }

        let first = makeHistoryItem(id: "11111111-1111-1111-1111-111111111111", rawInput: "First")
        let second = makeHistoryItem(id: "22222222-2222-2222-2222-222222222222", rawInput: "Second")
        try store.save([first, second])

        try store.delete(id: first.id)

        XCTAssertEqual(try store.load(), [second])
    }

    func testDeleteMultipleHistoryItems() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("history.json")
        let store = HistoryStore(fileURL: fileURL)
        defer {
            try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
        }

        let first = makeHistoryItem(id: "11111111-1111-1111-1111-111111111111", rawInput: "First")
        let second = makeHistoryItem(id: "22222222-2222-2222-2222-222222222222", rawInput: "Second")
        let third = makeHistoryItem(id: "33333333-3333-3333-3333-333333333333", rawInput: "Third")
        try store.save([first, second, third])

        try store.delete(ids: [first.id, third.id])

        XCTAssertEqual(try store.load(), [second])
    }

    private func makeHistoryItem(id: String, rawInput: String) -> HistoryItem {
        let request = PromptOptimizationRequest(
            rawInput: rawInput,
            mode: .codexDevelopment,
            targetTool: .codex,
            createdAt: Date(timeIntervalSince1970: 100)
        )
        let result = PromptOptimizationResult(
            optimizedPrompt: "Task\n\(rawInput)",
            rationale: nil,
            suggestedNextSteps: nil
        )
        return HistoryItem(
            id: UUID(uuidString: id)!,
            request: request,
            result: result,
            createdAt: Date(timeIntervalSince1970: 200)
        )
    }
}
