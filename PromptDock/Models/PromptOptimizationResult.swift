import Foundation

struct PromptOptimizationResult: Codable, Equatable {
    var optimizedPrompt: String
    var rationale: String?
    var suggestedNextSteps: [String]?
}
