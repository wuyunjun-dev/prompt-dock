import XCTest
@testable import PromptDock

final class OpenAICompatibleClientTests: XCTestCase {
    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testRequestBodyFormatAndResponseParsing() async throws {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: sessionConfiguration)
        let client = OpenAICompatibleClient(urlSession: session)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.absoluteString, "https://example.test/v1/chat/completions")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer secret-key")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-Test"), "yes")

            let body = try XCTUnwrap(request.httpBody ?? request.readBodyStream())
            let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
            XCTAssertEqual(json["model"] as? String, "model-a")
            XCTAssertEqual(json["temperature"] as? Double, 0.3)
            XCTAssertEqual(json["max_tokens"] as? Int, 2000)

            let messages = try XCTUnwrap(json["messages"] as? [[String: String]])
            XCTAssertEqual(messages.count, 2)
            XCTAssertEqual(messages[0]["role"], "system")
            XCTAssertEqual(messages[0]["content"], "system")
            XCTAssertEqual(messages[1]["role"], "user")
            XCTAssertEqual(messages[1]["content"], "user")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = Data(#"{"choices":[{"message":{"role":"assistant","content":"Optimized prompt"}}]}"#.utf8)
            return (response, data)
        }

        let result = try await client.complete(
            systemPrompt: "system",
            userPrompt: "user",
            configuration: APIConfiguration(
                baseURL: "https://example.test/v1",
                modelName: "model-a",
                extraHeaders: [
                    "Authorization": "Basic should-not-override",
                    "X-Test": "yes"
                ]
            ),
            apiKey: "secret-key"
        )

        XCTAssertEqual(result, "Optimized prompt")
    }

    func testBaseURLCanAlreadyPointAtChatCompletions() async throws {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: sessionConfiguration)
        let client = OpenAICompatibleClient(urlSession: session)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://example.test/v1/chat/completions")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = Data(#"{"choices":[{"message":{"content":"OK"}}]}"#.utf8)
            return (response, data)
        }

        let result = try await client.complete(
            systemPrompt: "system",
            userPrompt: "user",
            configuration: APIConfiguration(baseURL: "https://example.test/v1/chat/completions", modelName: "model-a"),
            apiKey: "secret-key"
        )

        XCTAssertEqual(result, "OK")
    }

    func testContentPartsResponseParsing() async throws {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: sessionConfiguration)
        let client = OpenAICompatibleClient(urlSession: session)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = Data(#"{"choices":[{"message":{"content":[{"type":"text","text":"Part one"},{"type":"text","text":"Part two"}]}}]}"#.utf8)
            return (response, data)
        }

        let result = try await client.complete(
            systemPrompt: "system",
            userPrompt: "user",
            configuration: APIConfiguration(baseURL: "https://example.test/v1", modelName: "model-a"),
            apiKey: "secret-key"
        )

        XCTAssertEqual(result, "Part one\nPart two")
    }

    func testEmptyModelResponseThrows() async {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: sessionConfiguration)
        let client = OpenAICompatibleClient(urlSession: session)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = Data(#"{"choices":[{"message":{"content":"   "}}]}"#.utf8)
            return (response, data)
        }

        do {
            _ = try await client.complete(
                systemPrompt: "system",
                userPrompt: "user",
                configuration: APIConfiguration(baseURL: "https://example.test/v1", modelName: "model-a"),
                apiKey: "secret-key"
            )
            XCTFail("Expected empty response error")
        } catch let error as AppError {
            XCTAssertEqual(error.localizedDescription, AppError.emptyModelResponse.localizedDescription)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testMissingAPIKeyThrowsBeforeRequest() async {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: sessionConfiguration)
        let client = OpenAICompatibleClient(urlSession: session)
        MockURLProtocol.requestHandler = { _ in
            XCTFail("Request should not be sent without an API key")
            throw URLError(.badServerResponse)
        }

        do {
            _ = try await client.complete(
                systemPrompt: "system",
                userPrompt: "user",
                configuration: APIConfiguration(baseURL: "https://example.test/v1", modelName: "model-a"),
                apiKey: " "
            )
            XCTFail("Expected missing API key error")
        } catch let error as AppError {
            XCTAssertEqual(error.localizedDescription, AppError.missingAPIKey.localizedDescription)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testAuthorizationHeaderIsRedactedFromLogs() {
        let sanitized = Logger.sanitize("Authorization: Bearer secret-key-123")

        XCTAssertFalse(sanitized.contains("secret-key-123"))
        XCTAssertTrue(sanitized.contains("[REDACTED]"))
    }

    func testNon2xxResponseBecomesAPIError() async {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: sessionConfiguration)
        let client = OpenAICompatibleClient(urlSession: session)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = Data(#"{"error":{"message":"Unauthorized"}}"#.utf8)
            return (response, data)
        }

        do {
            _ = try await client.complete(
                systemPrompt: "system",
                userPrompt: "user",
                configuration: APIConfiguration(baseURL: "https://example.test/v1", modelName: "model-a"),
                apiKey: "secret-key"
            )
            XCTFail("Expected API error")
        } catch let error as AppError {
            XCTAssertTrue(error.localizedDescription.contains("401"))
            XCTAssertTrue(error.localizedDescription.contains("Unauthorized"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testPlainTextAPIErrorIsSurfacedAndRedacted() async {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: sessionConfiguration)
        let client = OpenAICompatibleClient(urlSession: session)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = Data("Authorization: Bearer leaked-token failed".utf8)
            return (response, data)
        }

        do {
            _ = try await client.complete(
                systemPrompt: "system",
                userPrompt: "user",
                configuration: APIConfiguration(baseURL: "https://example.test/v1", modelName: "model-a"),
                apiKey: "secret-key"
            )
            XCTFail("Expected API error")
        } catch let error as AppError {
            XCTAssertTrue(error.localizedDescription.contains("500"))
            XCTAssertTrue(error.localizedDescription.contains("[REDACTED]"))
            XCTAssertFalse(error.localizedDescription.contains("leaked-token"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

final class PromptOptimizerServiceTests: XCTestCase {
    func testEmptyInputThrowsBeforeCallingModelClient() async {
        let service = PromptOptimizerService(client: FailingModelClient())
        let request = PromptOptimizationRequest(
            rawInput: "   ",
            mode: .codexDevelopment,
            targetTool: .codex
        )

        do {
            _ = try await service.optimize(
                request: request,
                configuration: APIConfiguration(),
                apiKey: "secret-key"
            )
            XCTFail("Expected empty input error")
        } catch let error as AppError {
            XCTAssertEqual(error.localizedDescription, AppError.emptyInput.localizedDescription)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private final class FailingModelClient: ModelClient {
    func complete(
        systemPrompt: String,
        userPrompt: String,
        configuration: APIConfiguration,
        apiKey: String
    ) async throws -> String {
        XCTFail("Model client should not be called for empty input")
        return ""
    }
}

private final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let requestHandler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try requestHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private extension URLRequest {
    func readBodyStream() -> Data? {
        guard let bodyStream = httpBodyStream else { return nil }
        bodyStream.open()
        defer { bodyStream.close() }

        var data = Data()
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while bodyStream.hasBytesAvailable {
            let count = bodyStream.read(buffer, maxLength: bufferSize)
            if count > 0 {
                data.append(buffer, count: count)
            } else {
                break
            }
        }

        return data
    }
}
