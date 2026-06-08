import SwiftUI

struct PromptEditorView: View {
    @ObservedObject var viewModel: PromptDockViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            selectors
            editors
            messages
            controls
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var selectors: some View {
        HStack(spacing: 12) {
            Picker("模式", selection: $viewModel.mode) {
                ForEach(PromptMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .frame(width: 260)

            Picker("目标工具", selection: $viewModel.targetTool) {
                ForEach(TargetTool.allCases) { target in
                    Text(target.displayName).tag(target)
                }
            }
            .frame(width: 200)

            Spacer()

            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private var editors: some View {
        HStack(alignment: .top, spacing: 12) {
            editorColumn(title: "原始输入", text: $viewModel.rawInput, prompt: "粘贴粗略想法、任务、报错信息或剪贴板内容。")
            editorColumn(title: "优化结果", text: $viewModel.optimizedOutput, prompt: "优化后的提示词会显示在这里。")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func editorColumn(title: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            ZStack(alignment: .topLeading) {
                TextEditor(text: text)
                    .font(.body.monospaced())
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(.quaternary.opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                if text.wrappedValue.isEmpty {
                    Text(prompt)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .allowsHitTesting(false)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder
    private var messages: some View {
        if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
            Text(errorMessage)
                .font(.callout)
                .foregroundStyle(.red)
                .lineLimit(2)
        } else if let statusMessage = viewModel.statusMessage, !statusMessage.isEmpty {
            Text(statusMessage)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Button {
                viewModel.optimize()
            } label: {
                Label("优化", systemImage: "wand.and.stars")
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .disabled(viewModel.isLoading)

            if viewModel.isLoading {
                Button {
                    viewModel.cancelOptimization()
                } label: {
                    Label("取消", systemImage: "xmark.circle")
                }
            }

            Button {
                viewModel.copyOutput()
            } label: {
                Label("复制结果", systemImage: "doc.on.doc")
            }
            .disabled(viewModel.optimizedOutput.isEmpty)

            Button {
                viewModel.saveCurrentResultToHistory()
            } label: {
                Label("保存到历史", systemImage: "tray.and.arrow.down")
            }
            .disabled(viewModel.optimizedOutput.isEmpty)

            Spacer()

            Button {
                viewModel.clearEditor()
            } label: {
                Label("清空", systemImage: "trash")
            }
        }
    }
}
