import Foundation

enum PromptMode: String, CaseIterable, Codable, Identifiable {
    case codexDevelopment
    case bugFix
    case refactor
    case codeReview
    case requirementBreakdown
    case generalOptimization

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .codexDevelopment:
            return "Codex 开发任务"
        case .bugFix:
            return "Bug 修复提示词"
        case .refactor:
            return "重构提示词"
        case .codeReview:
            return "代码审查提示词"
        case .requirementBreakdown:
            return "需求拆解提示词"
        case .generalOptimization:
            return "通用提示词优化"
        }
    }
}
