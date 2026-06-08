import Foundation

@MainActor
final class PromptDockViewModel: ObservableObject {
    @Published var rawInput = ""
    @Published var optimizedOutput = ""
    @Published var mode: PromptMode = .codexDevelopment
    @Published var targetTool: TargetTool = .codex
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var statusMessage: String?
    @Published var configuration: APIConfiguration
    @Published var historyItems: [HistoryItem] = []

    private let optimizerService: PromptOptimizerService
    private let configurationStore: ConfigurationStore
    private let keychainService: KeychainService
    private let clipboardService: ClipboardService
    private let historyStore: HistoryStore
    private var currentTask: Task<Void, Never>?
    private var currentTaskID: UUID?
    private var lastRequest: PromptOptimizationRequest?
    private var lastResult: PromptOptimizationResult?

    init(
        optimizerService: PromptOptimizerService = PromptOptimizerService(),
        configurationStore: ConfigurationStore = .shared,
        keychainService: KeychainService = .shared,
        clipboardService: ClipboardService = ClipboardService(),
        historyStore: HistoryStore = .shared
    ) {
        self.optimizerService = optimizerService
        self.configurationStore = configurationStore
        self.keychainService = keychainService
        self.clipboardService = clipboardService
        self.historyStore = historyStore
        configuration = configurationStore.load()
        reloadHistory()
    }

    func optimize() {
        currentTask?.cancel()
        errorMessage = nil
        statusMessage = nil

        guard !rawInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = AppError.emptyInput.localizedDescription
            return
        }

        let request = PromptOptimizationRequest(
            rawInput: rawInput,
            mode: mode,
            targetTool: targetTool
        )

        let taskID = UUID()
        currentTaskID = taskID
        isLoading = true
        currentTask = Task { [weak self] in
            guard let self else { return }
            defer {
                if currentTaskID == taskID {
                    isLoading = false
                    currentTask = nil
                    currentTaskID = nil
                }
            }

            do {
                guard let apiKey = try keychainService.readAPIKey(),
                      !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                else {
                    throw AppError.missingAPIKey
                }

                let result = try await optimizerService.optimize(
                    request: request,
                    configuration: configuration,
                    apiKey: apiKey
                )

                guard !Task.isCancelled, currentTaskID == taskID else { return }
                optimizedOutput = result.optimizedPrompt
                lastRequest = request
                lastResult = result
                statusMessage = "优化完成。"
            } catch is CancellationError {
                if currentTaskID == taskID {
                    statusMessage = "请求已取消。"
                }
            } catch {
                if currentTaskID == taskID {
                    errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
            }
        }
    }

    func optimizeClipboard() {
        guard let clipboardText = clipboardService.readText()?.trimmingCharacters(in: .whitespacesAndNewlines),
              !clipboardText.isEmpty
        else {
            errorMessage = AppError.clipboardEmpty.localizedDescription
            return
        }

        rawInput = clipboardText
        optimize()
    }

    func cancelOptimization() {
        currentTask?.cancel()
        currentTask = nil
        currentTaskID = nil
        isLoading = false
        statusMessage = "请求已取消。"
    }

    func copyOutput() {
        guard !optimizedOutput.isEmpty else { return }
        clipboardService.writeText(optimizedOutput)
        statusMessage = "结果已复制。"
    }

    func clearEditor() {
        currentTask?.cancel()
        currentTask = nil
        rawInput = ""
        optimizedOutput = ""
        errorMessage = nil
        statusMessage = nil
        lastRequest = nil
        lastResult = nil
        currentTaskID = nil
        isLoading = false
    }

    func saveCurrentResultToHistory() {
        guard let lastRequest, let lastResult else {
            errorMessage = "当前没有可保存的结果。"
            return
        }

        do {
            try historyStore.append(HistoryItem(request: lastRequest, result: lastResult))
            reloadHistory()
            statusMessage = "已保存到历史记录。"
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func reloadHistory() {
        do {
            historyItems = try historyStore.load()
        } catch {
            historyItems = []
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func clearHistory() {
        do {
            try historyStore.clear()
            historyItems = []
            statusMessage = "历史记录已清空。"
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func deleteHistoryItem(_ item: HistoryItem) {
        deleteHistoryItems(ids: [item.id])
    }

    func deleteHistoryItems(ids: Set<HistoryItem.ID>) {
        guard !ids.isEmpty else { return }

        do {
            try historyStore.delete(ids: ids)
            reloadHistory()
            statusMessage = ids.count == 1 ? "已删除 1 条历史记录。" : "已删除 \(ids.count) 条历史记录。"
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func hasStoredAPIKey() -> Bool {
        guard let apiKey = try? keychainService.readAPIKey() else {
            return false
        }

        return !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func saveSettings(configuration: APIConfiguration, apiKey: String) throws {
        let validatedConfiguration = try configuration.validated()
        let trimmedAPIKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedAPIKey.isEmpty {
            try keychainService.saveAPIKey(trimmedAPIKey)
        }
        try configurationStore.save(validatedConfiguration)
        self.configuration = validatedConfiguration
        statusMessage = "设置已保存。"
    }

    func clearAPIKey() {
        do {
            try keychainService.deleteAPIKey()
            statusMessage = "API 密钥已清除。"
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func testConnection(configuration: APIConfiguration, apiKey: String) async -> String {
        do {
            let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? try keychainService.readAPIKey()
                : apiKey
            guard let key, !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw AppError.missingAPIKey
            }

            try await optimizerService.testConnection(configuration: configuration, apiKey: key)
            return "连接测试成功。"
        } catch {
            return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func useHistoryItem(_ item: HistoryItem) {
        rawInput = item.request.rawInput
        optimizedOutput = item.result.optimizedPrompt
        mode = item.request.mode
        targetTool = item.request.targetTool
        lastRequest = item.request
        lastResult = item.result
        statusMessage = "已载入历史记录。"
    }
}
