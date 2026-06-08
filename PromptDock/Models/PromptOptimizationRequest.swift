import Foundation

struct PromptOptimizationRequest: Codable, Equatable {
    var rawInput: String
    var mode: PromptMode
    var targetTool: TargetTool
    var optionalContext: String?
    var createdAt: Date

    init(
        rawInput: String,
        mode: PromptMode,
        targetTool: TargetTool,
        optionalContext: String? = nil,
        createdAt: Date = Date()
    ) {
        self.rawInput = rawInput
        self.mode = mode
        self.targetTool = targetTool
        self.optionalContext = optionalContext
        self.createdAt = createdAt
    }
}
