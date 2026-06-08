import XCTest
@testable import PromptDock

final class APIConfigurationTests: XCTestCase {
    func testDefaultConfigurationIsReasonable() {
        let configuration = APIConfiguration()

        XCTAssertEqual(configuration.providerName, "OpenAI 兼容")
        XCTAssertTrue(configuration.isValidBaseURL)
        XCTAssertFalse(configuration.modelName.isEmpty)
        XCTAssertEqual(configuration.temperature, 0.3, accuracy: 0.0001)
        XCTAssertEqual(configuration.maxTokens, 2000)
    }

    func testInvalidBaseURLIsRejected() {
        let configuration = APIConfiguration(baseURL: "not a url")

        XCTAssertFalse(configuration.isValidBaseURL)
        XCTAssertThrowsError(try configuration.validated()) { error in
            XCTAssertEqual((error as? AppError)?.localizedDescription, AppError.invalidBaseURL.localizedDescription)
        }
    }

    func testValidationClampsTemperatureAndMaxTokens() throws {
        let configuration = APIConfiguration(temperature: 8, maxTokens: -4)
        let validated = try configuration.validated()

        XCTAssertEqual(validated.temperature, 2)
        XCTAssertEqual(validated.maxTokens, 1)
    }
}
