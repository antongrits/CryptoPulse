import Foundation

protocol PortfolioRepositoryProtocol {
    func holdings() -> [Holding]
    func upsertHolding(_ holding: Holding)
    func deleteHolding(id: String)
}
