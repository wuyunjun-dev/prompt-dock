import Foundation

final class ConfigurationStore {
    static let shared = ConfigurationStore()

    private let defaults: UserDefaults
    private let configurationKey = "PromptDock.APIConfiguration"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> APIConfiguration {
        guard let data = defaults.data(forKey: configurationKey) else {
            return APIConfiguration()
        }

        do {
            return try JSONDecoder().decode(APIConfiguration.self, from: data)
        } catch {
            Logger.error("Failed to load configuration: \(error.localizedDescription)")
            return APIConfiguration()
        }
    }

    func save(_ configuration: APIConfiguration) throws {
        do {
            let data = try JSONEncoder().encode(configuration)
            defaults.set(data, forKey: configurationKey)
        } catch {
            throw AppError.configurationFailed(error.localizedDescription)
        }
    }
}
