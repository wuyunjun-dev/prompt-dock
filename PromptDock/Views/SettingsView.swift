import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: PromptDockViewModel

    @State private var providerName: String
    @State private var baseURL: String
    @State private var apiKey: String
    @State private var modelName: String
    @State private var temperature: Double
    @State private var maxTokens: Int
    @State private var extraHeadersText: String
    @State private var message: String?
    @State private var isTesting = false
    @State private var hasStoredAPIKey: Bool

    init(viewModel: PromptDockViewModel) {
        self.viewModel = viewModel
        let configuration = viewModel.configuration
        _providerName = State(initialValue: configuration.providerName)
        _baseURL = State(initialValue: configuration.baseURL)
        _apiKey = State(initialValue: "")
        _modelName = State(initialValue: configuration.modelName)
        _temperature = State(initialValue: configuration.temperature)
        _maxTokens = State(initialValue: configuration.maxTokens)
        _extraHeadersText = State(initialValue: configuration.extraHeaders.map { "\($0.key): \($0.value)" }.sorted().joined(separator: "\n"))
        _hasStoredAPIKey = State(initialValue: viewModel.hasStoredAPIKey())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("设置")
                .font(.title2.weight(.semibold))

            Form {
                TextField("API 提供方名称", text: $providerName)
                TextField("基础 URL", text: $baseURL)
                VStack(alignment: .leading, spacing: 6) {
                    SecureField(hasStoredAPIKey ? "新的 API 密钥" : "API 密钥", text: $apiKey)
                    Text(hasStoredAPIKey ? "钥匙串中已保存 API 密钥。留空可保留现有值。" : "尚未保存 API 密钥。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                TextField("模型名称", text: $modelName)

                VStack(alignment: .leading, spacing: 8) {
                    Text("温度：\(temperature, specifier: "%.2f")")
                    Slider(value: $temperature, in: 0...2, step: 0.05)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("最大 Token 数")
                    HStack(spacing: 8) {
                        TextField("最大 Token 数", value: $maxTokens, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 140)

                        Stepper("当前：\(maxTokens)", value: $maxTokens, in: 1...128000, step: 100)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("额外请求头")
                    TextEditor(text: $extraHeadersText)
                        .font(.body.monospaced())
                        .frame(height: 90)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(.separator, lineWidth: 1)
                        )
                    Text("每行一个请求头，格式为 Name: Value。Authorization 请求头由 PromptDock 自动管理。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let message, !message.isEmpty {
                Text(message)
                    .font(.callout)
                    .foregroundColor(isErrorMessage(message) ? .red : .secondary)
            }

            HStack {
                Button {
                    save()
                } label: {
                    Label("保存", systemImage: "checkmark.circle")
                }

                Button {
                    testConnection()
                } label: {
                    if isTesting {
                        Label("测试中", systemImage: "hourglass")
                    } else {
                        Label("测试连接", systemImage: "network")
                    }
                }
                .disabled(isTesting)

                Spacer()

                Button(role: .destructive) {
                    apiKey = ""
                    viewModel.clearAPIKey()
                    hasStoredAPIKey = false
                    message = "API 密钥已清除。"
                } label: {
                    Label("清除 API 密钥", systemImage: "key.slash")
                }

                Button(role: .destructive) {
                    viewModel.clearHistory()
                    message = "历史记录已清空。"
                } label: {
                    Label("清空历史", systemImage: "trash")
                }
            }
        }
        .padding(22)
        .frame(minWidth: 520, minHeight: 580)
        .onChange(of: maxTokens) { _, newValue in
            maxTokens = min(max(newValue, 1), 128000)
        }
    }

    private func save() {
        do {
            let suppliedAPIKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            try viewModel.saveSettings(configuration: makeConfiguration(), apiKey: apiKey)
            if !suppliedAPIKey.isEmpty {
                hasStoredAPIKey = true
                apiKey = ""
            }
            message = "设置已保存。"
        } catch {
            message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func testConnection() {
        isTesting = true
        message = nil
        let configuration = makeConfiguration()
        let currentAPIKey = apiKey

        Task {
            let result = await viewModel.testConnection(configuration: configuration, apiKey: currentAPIKey)
            message = result
            isTesting = false
        }
    }

    private func makeConfiguration() -> APIConfiguration {
        APIConfiguration(
            providerName: providerName,
            baseURL: baseURL,
            modelName: modelName,
            temperature: temperature,
            maxTokens: maxTokens,
            extraHeaders: parseHeaders(extraHeadersText)
        )
    }

    private func parseHeaders(_ text: String) -> [String: String] {
        var headers: [String: String] = [:]
        for line in text.split(separator: "\n") {
            let parts = line.split(separator: ":", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }

            let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let value = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty, !value.isEmpty else { continue }
            guard key.caseInsensitiveCompare("Authorization") != .orderedSame else { continue }

            headers[key] = value
        }
        return headers
    }

    private func isErrorMessage(_ message: String) -> Bool {
        message.contains("失败")
            || message.contains("错误")
            || message.contains("无效")
            || message.contains("未配置")
            || message.contains("尚未")
            || message.contains("无法")
    }
}
