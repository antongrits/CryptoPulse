import Foundation

protocol SearchRepositoryProtocol {
    func recentSearches() -> [RecentSearch]
    func addSearch(query: String)
    func clearSearches()
}
