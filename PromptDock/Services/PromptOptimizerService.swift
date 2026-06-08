import Foundation

final class PromptOptimizerService {
    private let client: ModelClient
    private let templateManager: PromptTemplateManager

    init(
        client: ModelClient = OpenAICompatibleClient(),
        templateManager: PromptTemplateManager = PromptTemplateManager()
    ) {
        self.client = client
        self.templateManager = templateManager
    }

    func optimize(
        request: PromptOptimizationRequest,
        configuration: APIConfiguration,
        apiKey: String,
        userPreferences: String? = nil
    ) async throws -> PromptOptimizationResult {
        guard !request.rawInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.emptyInput
        }

        let content = try await client.complete(
            systemPrompt: templateManager.systemPrompt,
            userPrompt: templateManager.makeUserPrompt(for: request, userPreferences: userPreferences),
            configuration: configuration,
            apiKey: apiKey
        )

        let optimizedPrompt = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !optimizedPrompt.isEmpty else {
            throw AppError.emptyModelResponse
        }

        return PromptOptimizationResult(
            optimizedPrompt: optimizedPrompt,
            rationale: nil,
            suggestedNextSteps: nil
        )
    }

    func testConnection(configuration: APIConfiguration, apiKey: String) async throws {
        let request = PromptOptimizationRequest(
            rawInput: "Create a concise test prompt that replies with OK only.",
            mode: .generalOptimization,
            targetTool: .genericAgent
        )

        _ = try await optimize(
            request: request,
            configuration: configuration,
            apiKey: apiKey,
            userPreferences: "Return only a minimal response."
        )
    }
}
