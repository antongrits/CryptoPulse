import Foundation

struct RecentSearch: Identifiable, Hashable {
    let id: String
    let query: String
    let createdAt: Date
}
