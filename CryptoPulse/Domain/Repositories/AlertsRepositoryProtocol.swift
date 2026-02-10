import Foundation

protocol AlertsRepositoryProtocol {
    func alerts() -> [PriceAlert]
    func upsertAlert(_ alert: PriceAlert)
    func deleteAlert(id: String)
    func markTriggered(id: String, date: Date)
    func setArmed(id: String, isArmed: Bool)
}
