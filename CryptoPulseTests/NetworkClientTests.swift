import XCTest
@testable import CryptoPulse

@MainActor
final class NetworkClientTests: XCTestCase {
    func testCoinGeckoServiceUsesMockNetworkClient() async throws {
        let json = """
        [
          {"id":"btc","name":"Bitcoin","symbol":"btc","image":null,"current_price":1,"price_change_percentage_24h":0}
        ]
        """
        let mock = MockNetworkClient(responses: [
            "/api/v3/coins/markets": Data(json.utf8)
        ])
        let service = CoinGeckoService(client: mock)
        let markets = try await service.fetchMarkets(page: 1, perPage: 1, sort: .marketCapDesc)
        XCTAssertEqual(markets.count, 1)
        XCTAssertEqual(markets.first?.id, "btc")
    }
}

final class MockNetworkClient: NetworkClientProtocol {
    private let responses: [String: Data]

    init(responses: [String: Data]) {
        self.responses = responses
    }

    func request<T>(_ endpoint: Endpoint) async throws -> T where T : Decodable {
        guard let data = responses[endpoint.path] else { throw NetworkError.unknown }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
