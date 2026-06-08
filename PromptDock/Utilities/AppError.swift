import Foundation

enum AppError: LocalizedError {
    case missingAPIKey
    case invalidBaseURL
    case missingModelName
    case emptyInput
    case networkFailed(String)
    case apiError(statusCode: Int, message: String?)
    case jsonDecodingFailed
    case emptyModelResponse
    case keychainFailed(String)
    case historyFailed(String)
    case configurationFailed(String)
    case clipboardEmpty

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "尚未配置 API 密钥。请先在设置中添加。"
        case .invalidBaseURL:
            return "基础 URL 无效。请使用完整地址，例如 https://api.example.com/v1。"
        case .missingModelName:
            return "必须填写模型名称。"
        case .emptyInput:
            return "输入为空。请先输入想法、任务、报错信息或剪贴板文本。"
        case .networkFailed(let message):
            return "网络请求失败：\(message)"
        case .apiError(let statusCode, let message):
            if let message, !message.isEmpty {
                return "API 返回 HTTP \(statusCode)：\(message)"
            }
            return "API 返回 HTTP \(statusCode)。"
        case .jsonDecodingFailed:
            return "无法解析 API 响应。"
        case .emptyModelResponse:
            return "模型返回了空内容。"
        case .keychainFailed(let message):
            return "钥匙串错误：\(message)"
        case .historyFailed(let message):
            return "历史记录错误：\(message)"
        case .configurationFailed(let message):
            return "配置错误：\(message)"
        case .clipboardEmpty:
            return "剪贴板中没有文本。"
        }
    }
}
