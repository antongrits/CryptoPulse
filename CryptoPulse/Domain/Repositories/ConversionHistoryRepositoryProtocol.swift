import Foundation

protocol ConversionHistoryRepositoryProtocol {
    func recent(limit: Int) -> [ConversionRecord]
    func addRecord(_ record: ConversionRecord)
    func clear()
}
