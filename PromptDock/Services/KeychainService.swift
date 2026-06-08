import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()

    private let service: String
    private let apiKeyAccount = "PromptDock.APIKey"

    init(service: String = Bundle.main.bundleIdentifier ?? "PromptDock") {
        self.service = service
    }

    func saveAPIKey(_ apiKey: String) throws {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            try deleteAPIKey()
            return
        }

        guard let data = trimmed.data(using: .utf8) else {
            throw AppError.keychainFailed("无法编码 API 密钥。")
        }

        let query = baseQuery()
        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AppError.keychainFailed(SecCopyErrorMessageString(status, nil) as String? ?? "Status \(status)")
        }
    }

    func readAPIKey() throws -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw AppError.keychainFailed(SecCopyErrorMessageString(status, nil) as String? ?? "Status \(status)")
        }

        guard let data = item as? Data else {
            throw AppError.keychainFailed("已保存的 API 密钥格式异常。")
        }
        return String(data: data, encoding: .utf8)
    }

    func deleteAPIKey() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AppError.keychainFailed(SecCopyErrorMessageString(status, nil) as String? ?? "Status \(status)")
        }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount
        ]
    }
}
