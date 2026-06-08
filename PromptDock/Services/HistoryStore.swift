import Foundation

final class HistoryStore {
    static let shared = HistoryStore()

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            self.fileURL = applicationSupport
                .appendingPathComponent("PromptDock", isDirectory: true)
                .appendingPathComponent("history.json")
        }

        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func load() throws -> [HistoryItem] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode([HistoryItem].self, from: data)
        } catch {
            throw AppError.historyFailed(error.localizedDescription)
        }
    }

    func append(_ item: HistoryItem) throws {
        var items = try load()
        items.insert(item, at: 0)
        try save(items)
    }

    func delete(id: HistoryItem.ID) throws {
        try delete(ids: [id])
    }

    func delete(ids: Set<HistoryItem.ID>) throws {
        guard !ids.isEmpty else { return }
        let items = try load()
        try save(items.filter { !ids.contains($0.id) })
    }

    func save(_ items: [HistoryItem]) throws {
        do {
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try encoder.encode(items)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            throw AppError.historyFailed(error.localizedDescription)
        }
    }

    func clear() throws {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                throw AppError.historyFailed(error.localizedDescription)
            }
        }
    }
}
