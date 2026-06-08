import Foundation

enum TargetTool: String, CaseIterable, Codable, Identifiable {
    case codex
    case claudeCode
    case cursor
    case chatGPT
    case genericAgent

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .codex:
            return "Codex"
        case .claudeCode:
            return "Claude Code"
        case .cursor:
            return "Cursor"
        case .chatGPT:
            return "ChatGPT"
        case .genericAgent:
            return "通用 Agent"
        }
    }
}
