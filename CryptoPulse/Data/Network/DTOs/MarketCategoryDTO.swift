import Foundation

struct MarketCategoryDTO: Decodable {
    let categoryId: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case categoryId = "category_id"
        case name
    }
}
