import Foundation

final class OpenAICompatibleClient: ModelClient {
    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func complete(
        systemPrompt: String,
        userPrompt: String,
        configuration: APIConfiguration,
        apiKey: String
    ) async throws -> String {
        let configuration = try configuration.validated()
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.missingAPIKey
        }
        guard let baseURL = configuration.normalizedBaseURL else {
            throw AppError.invalidBaseURL
        }

        let endpoint = baseURL.chatCompletionsEndpoint()

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        for (key, value) in configuration.extraHeaders where !key.isEmpty {
            if key.caseInsensitiveCompare("Authorization") != .orderedSame {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        let body = ChatCompletionRequest(
            model: configuration.modelName,
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: userPrompt)
            ],
            temperature: configuration.temperature,
            maxTokens: configuration.maxTokens
        )
        request.httpBody = try JSONEncoder().encode(body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            Logger.error("Network request failed without sensitive headers: \(error.localizedDescription)")
            throw AppError.networkFailed(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.networkFailed("缺少 HTTP 响应。")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let apiMessage = Self.extractAPIErrorMessage(from: data)
            throw AppError.apiError(statusCode: httpResponse.statusCode, message: apiMessage)
        }

        let decoded: ChatCompletionResponse
        do {
            decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        } catch {
            Logger.error("Failed to decode response: \(error.localizedDescription)")
            throw AppError.jsonDecodingFailed
        }

        guard let content = decoded.choices.first?.message.content?.text
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !content.isEmpty
        else {
            throw AppError.emptyModelResponse
        }

        return content
    }

    private static func extractAPIErrorMessage(from data: Data) -> String? {
        let decoder = JSONDecoder()
        if let decoded = try? decoder.decode(OpenAIErrorResponse.self, from: data),
           let message = decoded.error.message?.trimmingCharacters(in: .whitespacesAndNewlines),
           !message.isEmpty {
            return Logger.sanitize(message).limitedForDisplay()
        }

        if let decoded = try? decoder.decode(GenericErrorResponse.self, from: data),
           let message = decoded.message?.trimmingCharacters(in: .whitespacesAndNewlines),
           !message.isEmpty {
            return Logger.sanitize(message).limitedForDisplay()
        }

        if let decoded = try? decoder.decode(GenericErrorResponse.self, from: data),
           let error = decoded.error?.trimmingCharacters(in: .whitespacesAndNewlines),
           !error.isEmpty {
            return Logger.sanitize(error).limitedForDisplay()
        }

        guard let raw = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty
        else {
            return nil
        }

        return Logger.sanitize(raw).limitedForDisplay()
    }
}

private struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [RequestChatMessage]
    let temperature: Double
    let maxTokens: Int

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxTokens = "max_tokens"
    }
}

private struct RequestChatMessage: Encodable {
    let role: String
    let content: String
}

private struct ChatCompletionResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: ResponseChatMessage
    }
}

private struct ResponseChatMessage: Decodable {
    let content: ChatMessageContent?
}

private enum ChatMessageContent: Decodable {
    case string(String)
    case parts([ContentPart])

    var text: String {
        switch self {
        case .string(let string):
            return string
        case .parts(let parts):
            return parts
                .compactMap(\.text)
                .joined(separator: "\n")
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .string("")
            return
        }

        if let string = try? container.decode(String.self) {
            self = .string(string)
            return
        }

        if let parts = try? container.decode([ContentPart].self) {
            self = .parts(parts)
            return
        }

        throw DecodingError.typeMismatch(
            ChatMessageContent.self,
            DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected string or content parts.")
        )
    }
}

private struct ContentPart: Decodable {
    let text: String?
}

private struct OpenAIErrorResponse: Decodable {
    let error: APIErrorMessage

    struct APIErrorMessage: Decodable {
        let message: String?
    }
}

private struct GenericErrorResponse: Decodable {
    let error: String?
    let message: String?
}

private extension URL {
    func chatCompletionsEndpoint() -> URL {
        let withoutSlash = deletingTrailingSlash()
        if withoutSlash.path.lowercased().hasSuffix("/chat/completions") {
            return withoutSlash
        }

        return withoutSlash.appendingPathComponent("chat/completions")
    }

    private func deletingTrailingSlash() -> URL {
        var absoluteString = self.absoluteString
        while absoluteString.hasSuffix("/") {
            absoluteString.removeLast()
        }
        return URL(string: absoluteString) ?? self
    }
}

private extension String {
    func limitedForDisplay(maxLength: Int = 500) -> String {
        guard count > maxLength else { return self }
        return String(prefix(maxLength)) + "..."
    }
}
