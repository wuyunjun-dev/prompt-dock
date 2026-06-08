import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: PromptDockViewModel
    @State private var selectedItemIDs: Set<HistoryItem.ID> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("历史记录")
                    .font(.headline)
                Spacer()

                if !viewModel.historyItems.isEmpty {
                    Button {
                        toggleSelectAll()
                    } label: {
                        Label(isAllSelected ? "取消全选" : "全选", systemImage: isAllSelected ? "checkmark.square" : "square")
                    }
                    .buttonStyle(.borderless)

                    Button(role: .destructive) {
                        deleteSelectedItems()
                    } label: {
                        Label("删除所选", systemImage: "trash")
                    }
                    .buttonStyle(.borderless)
                    .disabled(selectedItemIDs.isEmpty)
                    .help(selectedItemIDs.isEmpty ? "先选择要删除的历史记录" : "删除选中的历史记录")
                }

                Button {
                    viewModel.reloadHistory()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("重新加载历史记录")
            }

            if viewModel.historyItems.isEmpty {
                ContentUnavailableView("暂无历史记录", systemImage: "clock", description: Text("保存后的提示词会显示在这里。"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.historyItems) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Toggle("", isOn: selectionBinding(for: item))
                            .toggleStyle(.checkbox)
                            .labelsHidden()
                            .padding(.top, 2)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(item.request.mode.displayName)
                                    .font(.subheadline.weight(.semibold))
                                Text(item.request.targetTool.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(item.createdAt, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Text(item.result.optimizedPrompt)
                                .font(.body.monospaced())
                                .lineLimit(4)
                                .foregroundStyle(.primary)

                            HStack {
                                Button {
                                    viewModel.useHistoryItem(item)
                                } label: {
                                    Label("载入", systemImage: "arrow.up.left.square")
                                }

                                Button {
                                    ClipboardService().writeText(item.result.optimizedPrompt)
                                } label: {
                                    Label("复制", systemImage: "doc.on.doc")
                                }

                                Button(role: .destructive) {
                                    deleteItem(item)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: viewModel.historyItems) { _, items in
            selectedItemIDs.formIntersection(Set(items.map(\.id)))
        }
    }

    private var isAllSelected: Bool {
        !viewModel.historyItems.isEmpty && selectedItemIDs.count == viewModel.historyItems.count
    }

    private func selectionBinding(for item: HistoryItem) -> Binding<Bool> {
        Binding {
            selectedItemIDs.contains(item.id)
        } set: { isSelected in
            if isSelected {
                selectedItemIDs.insert(item.id)
            } else {
                selectedItemIDs.remove(item.id)
            }
        }
    }

    private func toggleSelectAll() {
        if isAllSelected {
            selectedItemIDs.removeAll()
        } else {
            selectedItemIDs = Set(viewModel.historyItems.map(\.id))
        }
    }

    private func deleteItem(_ item: HistoryItem) {
        selectedItemIDs.remove(item.id)
        viewModel.deleteHistoryItem(item)
    }

    private func deleteSelectedItems() {
        let ids = selectedItemIDs
        selectedItemIDs.removeAll()
        viewModel.deleteHistoryItems(ids: ids)
    }
}
