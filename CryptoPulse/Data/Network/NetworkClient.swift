import Foundation

protocol NetworkClientProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}

final class NetworkClient: NetworkClientProtocol {
    private let session: URLSession
    private let baseURL: URL

    init(session: URLSession = .shared, baseURL: URL = URL(string: "https://api.coingecko.com") ?? URL(fileURLWithPath: "/")) {
        self.session = session
        self.baseURL = baseURL
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        guard let url = endpoint.url(baseURL: baseURL) else { throw NetworkError.unknown }
        await NetworkBackoff.shared.waitIfNeeded()
        await NetworkThrottle.shared.throttle()
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        endpoint.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw NetworkError.unknown }
            if http.statusCode == 429 {
                let retryAfter = http.value(forHTTPHeaderField: "Retry-After").flatMap { TimeInterval($0) }
                await NetworkBackoff.shared.suspend(for: retryAfter ?? 60)
                throw NetworkError.rateLimited(retryAfter: retryAfter)
            }
            guard (200..<300).contains(http.statusCode) else {
                throw NetworkError.server(statusCode: http.statusCode)
            }
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                return decoded
            } catch {
                throw NetworkError.decoding
            }
        } catch let urlError as URLError where urlError.code == .notConnectedToInternet {
            throw NetworkError.offline
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.unknown
        }
    }
}
