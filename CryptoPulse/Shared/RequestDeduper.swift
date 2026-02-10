import Foundation

actor RequestDeduper<Value> {
    private var tasks: [String: Task<Value, Error>] = [:]

    func run(key: String, operation: @escaping () async throws -> Value) async throws -> Value {
        if let task = tasks[key] {
            return try await task.value
        }
        let task = Task { try await operation() }
        tasks[key] = task
        do {
            let value = try await task.value
            tasks[key] = nil
            return value
        } catch {
            tasks[key] = nil
            throw error
        }
    }
}
