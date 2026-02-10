import XCTest

final class CryptoPulseUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchOpenDetails() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-use-mock-data", "-ui-testing"]
        app.launch()

        var marketRow = app.buttons["market_row_bitcoin"].firstMatch
        if !marketRow.exists { marketRow = app.otherElements["market_row_bitcoin"].firstMatch }
        XCTAssertTrue(marketRow.waitForExistence(timeout: 5))
        marketRow.tap()

        let favoriteButton = app.buttons["favorite_button"].firstMatch
        XCTAssertTrue(favoriteButton.waitForExistence(timeout: 5))
    }

    @MainActor
    func testAddFavoriteAndSeeInFavoritesTab() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-use-mock-data", "-ui-testing"]
        app.launch()

        var marketRow = app.buttons["market_row_bitcoin"].firstMatch
        if !marketRow.exists { marketRow = app.otherElements["market_row_bitcoin"].firstMatch }
        XCTAssertTrue(marketRow.waitForExistence(timeout: 5))
        marketRow.tap()

        let favoriteButton = app.buttons["favorite_button"].firstMatch
        XCTAssertTrue(favoriteButton.waitForExistence(timeout: 5))
        favoriteButton.tap()

        let favoritesTab = app.tabBars.buttons["Favorites"].firstMatch
        XCTAssertTrue(favoritesTab.waitForExistence(timeout: 3))
        favoritesTab.tap()

        var favoriteRow = app.buttons["favorite_row_bitcoin"].firstMatch
        if !favoriteRow.exists { favoriteRow = app.otherElements["favorite_row_bitcoin"].firstMatch }
        XCTAssertTrue(favoriteRow.waitForExistence(timeout: 5))
    }
}
