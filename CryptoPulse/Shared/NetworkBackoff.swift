import Foundation

actor NetworkBackoff {
    static let shared = NetworkBackoff()
    private var suspendedUntil: Date?

    func waitIfNeeded() async {
        guard let until = suspendedUntil else { return }
        let now = Date()
        if now < until {
            let delay = until.timeIntervalSince(now)
            let nanos = UInt64(delay * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanos)
        }
    }

    func suspend(for seconds: TimeInterval) {
        let newUntil = Date().addingTimeInterval(max(0, seconds))
        if let existing = suspendedUntil, existing > newUntil { return }
        suspendedUntil = newUntil
    }
}
