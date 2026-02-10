import Foundation

actor NetworkThrottle {
    static let shared = NetworkThrottle()
    private var lastRequest: Date?

    func throttle(minInterval: TimeInterval = 2.0) async {
        let now = Date()
        if let lastRequest {
            let elapsed = now.timeIntervalSince(lastRequest)
            if elapsed < minInterval {
                let delay = minInterval - elapsed
                let nanos = UInt64(delay * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanos)
            }
        }
        lastRequest = Date()
    }
}
