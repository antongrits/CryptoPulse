import Foundation

enum NetworkRetry {
    static func run<T>(
        maxAttempts: Int = 2,
        initialDelay: TimeInterval = 0.6,
        operation: () async throws -> T
    ) async throws -> T {
        var attempt = 0
        var delay = initialDelay
        while true {
            do {
                return try await operation()
            } catch {
                attempt += 1
                guard attempt < maxAttempts else { throw error }
                if case let .rateLimited(retryAfter) = error as? NetworkError {
                    let wait = max(retryAfter ?? delay, delay)
                    let nanos = UInt64(wait * 1_000_000_000)
                    try? await Task.sleep(nanoseconds: nanos)
                    delay *= 1.6
                    continue
                }
                guard shouldRetry(error) else { throw error }
                let nanos = UInt64(delay * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanos)
                delay *= 1.6
            }
        }
    }

    private static func shouldRetry(_ error: Error) -> Bool {
        guard let networkError = error as? NetworkError else { return false }
        switch networkError {
        case .server(let statusCode):
            return statusCode >= 500 && statusCode <= 599
        case .unknown:
            return true
        default:
            return false
        }
    }
}
