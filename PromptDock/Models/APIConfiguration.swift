import Foundation

struct APIConfiguration: Codable, Equatable {
    var providerName: String
    var baseURL: String
    var modelName: String
    var temperature: Double
    var maxTokens: Int
    var extraHeaders: [String: String]

    init(
        providerName: String = "OpenAI 兼容",
        baseURL: String = "https://api.openai.com/v1",
        modelName: String = "gpt-4.1-mini",
        temperature: Double = 0.3,
        maxTokens: Int = 2000,
        extraHeaders: [String: String] = [:]
    ) {
        self.providerName = providerName
        self.baseURL = baseURL
        self.modelName = modelName
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.extraHeaders = extraHeaders
    }

    var normalizedBaseURL: URL? {
        let trimmed = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            let url = URL(string: trimmed),
            let scheme = url.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            url.host?.isEmpty == false
        else {
            return nil
        }
        return url
    }

    var isValidBaseURL: Bool {
        normalizedBaseURL != nil
    }

    func validated() throws -> APIConfiguration {
        guard isValidBaseURL else {
            throw AppError.invalidBaseURL
        }

        guard !modelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.missingModelName
        }

        var copy = self
        copy.temperature = min(max(temperature, 0), 2)
        copy.maxTokens = max(maxTokens, 1)
        return copy
    }
}
