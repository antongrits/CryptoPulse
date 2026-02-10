import Foundation

struct CacheResult<T> {
    let value: T
    let updatedAt: Date
    let isFresh: Bool
}

final class DiskCache: @unchecked Sendable {
    static let shared = DiskCache()

    private let directory: URL
    private let queue = DispatchQueue(label: "DiskCacheQueue")
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        directory = (caches ?? URL(fileURLWithPath: NSTemporaryDirectory()))
            .appendingPathComponent("cryptopulse_cache", isDirectory: true)
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func store<T: Codable>(_ value: T, key: String) {
        let envelope = CacheEnvelope(value: value, updatedAt: Date())
        let url = fileURL(for: key)
        let data: Data
        do {
            data = try encoder.encode(envelope)
        } catch {
            return
        }
        queue.async {
            do {
                try data.write(to: url, options: [.atomic])
            } catch {
                // Ignore cache write failures.
            }
        }
    }

    func load<T: Codable>(key: String, ttl: TimeInterval) -> CacheResult<T>? {
        let url = fileURL(for: key)
        let data: Data? = queue.sync {
            try? Data(contentsOf: url)
        }
        guard let data else { return nil }
        guard let envelope = try? decoder.decode(CacheEnvelope<T>.self, from: data) else { return nil }
        let isFresh = CachePolicy.isFresh(envelope.updatedAt, ttl: ttl)
        return CacheResult(value: envelope.value, updatedAt: envelope.updatedAt, isFresh: isFresh)
    }

    private func fileURL(for key: String) -> URL {
        let safeKey = key.replacingOccurrences(of: "/", with: "_")
        return directory.appendingPathComponent("\(safeKey).json")
    }
}

private struct CacheEnvelope<T: Codable>: Codable {
    let value: T
    let updatedAt: Date
}
