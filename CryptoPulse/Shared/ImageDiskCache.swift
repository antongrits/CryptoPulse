import UIKit
import CryptoKit

final class ImageDiskCache {
    static let shared = ImageDiskCache()

    private let directory: URL

    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        directory = (caches ?? URL(fileURLWithPath: NSTemporaryDirectory()))
            .appendingPathComponent("cryptopulse_image_cache", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func image(for url: URL) -> UIImage? {
        let fileURL = directory.appendingPathComponent(filename(for: url))
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    func store(_ data: Data, for url: URL) {
        let fileURL = directory.appendingPathComponent(filename(for: url))
        try? data.write(to: fileURL, options: [.atomic])
    }

    private func filename(for url: URL) -> String {
        let input = Data(url.absoluteString.utf8)
        let hash = SHA256.hash(data: input).compactMap { String(format: "%02x", $0) }.joined()
        return "\(hash).img"
    }
}
