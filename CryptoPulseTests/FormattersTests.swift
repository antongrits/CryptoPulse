import XCTest
@testable import CryptoPulse

@MainActor
final class FormattersTests: XCTestCase {
    func testPriceFormatter() {
        let value = PriceFormatter.string(1234.56)
        XCTAssertTrue(value.contains("$") || value.contains("USD"))
    }

    func testPercentFormatter() {
        let value = PercentFormatter.string(1.23)
        XCTAssertTrue(value.contains("1.23"))
        XCTAssertTrue(value.hasPrefix("+"))
    }
}
