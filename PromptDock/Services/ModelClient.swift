import Foundation

protocol ModelClient {
    func complete(
        systemPrompt: String,
        userPrompt: String,
        configuration: APIConfiguration,
        apiKey: String
    ) async throws -> String
}
