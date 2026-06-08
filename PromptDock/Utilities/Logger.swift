import Foundation

enum Logger {
    static func info(_ message: String) {
        #if DEBUG
        print("[PromptDock] \(sanitize(message))")
        #endif
    }

    static func error(_ message: String) {
        #if DEBUG
        print("[PromptDock][Error] \(sanitize(message))")
        #endif
    }

    static func sanitize(_ message: String) -> String {
        var sanitized = message
        let patterns = [
            #"(?i)Authorization:\s*Bearer\s+[A-Za-z0-9._\-+/=]+"#,
            #"(?i)Bearer\s+[A-Za-z0-9._\-+/=]+"#
        ]

        for pattern in patterns {
            sanitized = sanitized.replacingOccurrences(
                of: pattern,
                with: "Authorization: Bearer [REDACTED]",
                options: .regularExpression
            )
        }

        return sanitized
    }
}
