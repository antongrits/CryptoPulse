import Foundation
import Combine

@MainActor
final class NotesLibraryViewModel: ObservableObject {
    @Published var notes: [CoinNote] = []
    @Published var searchText: String = ""

    private let notesRepository: NotesRepositoryProtocol

    init(notesRepository: NotesRepositoryProtocol) {
        self.notesRepository = notesRepository
        load()
    }

    func load() {
        notes = notesRepository.allNotes()
    }

    func deleteNote(id: String) {
        notesRepository.deleteNote(id: id)
        load()
    }

    func clearAllNotes() {
        notesRepository.deleteAllNotes()
        load()
    }

    var filteredNotes: [CoinNote] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return notes }
        return notes.filter { note in
            note.coinName.localizedCaseInsensitiveContains(query) ||
            note.coinSymbol.localizedCaseInsensitiveContains(query) ||
            note.text.localizedCaseInsensitiveContains(query)
        }
    }

    var groupedNotes: [(date: Date, notes: [CoinNote])] {
        let grouped = Dictionary(grouping: filteredNotes) { note in
            Calendar.current.startOfDay(for: note.updatedAt)
        }
        return grouped
            .map { (date: $0.key, notes: $0.value.sorted(by: { $0.updatedAt > $1.updatedAt })) }
            .sorted(by: { $0.date > $1.date })
    }
}
