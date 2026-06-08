import Foundation

struct HistoryItem: Codable, Equatable, Identifiable {
    var id: UUID
    var request: PromptOptimizationRequest
    var result: PromptOptimizationResult
    var createdAt: Date

    init(
        id: UUID = UUID(),
        request: PromptOptimizationRequest,
        result: PromptOptimizationResult,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.request = request
        self.result = result
        self.createdAt = createdAt
    }
}
