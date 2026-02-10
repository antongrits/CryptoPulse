import Foundation

struct Endpoint {
    let path: String
    let queryItems: [URLQueryItem]
    let method: String
    let headers: [String: String]

    func url(baseURL: URL) -> URL? {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems
        return components?.url
    }
}
