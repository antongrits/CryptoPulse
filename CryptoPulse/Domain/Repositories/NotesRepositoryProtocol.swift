import Foundation

protocol NotesRepositoryProtocol {
    func note(for coinId: String) -> CoinNote?
    func notes(for coinId: String) -> [CoinNote]
    func allNotes() -> [CoinNote]
    func upsert(note: CoinNote)
    func addNote(coinId: String, coinName: String, coinSymbol: String, text: String) -> CoinNote
    func deleteNote(id: String)
    func deleteNotes(coinId: String)
    func deleteAllNotes()
}
