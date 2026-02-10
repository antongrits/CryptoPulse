import Foundation
import RealmSwift
import os

final class NotesRepository: NotesRepositoryProtocol {
    private let realmProvider: RealmProvider

    init(realmProvider: RealmProvider) {
        self.realmProvider = realmProvider
    }

    func note(for coinId: String) -> CoinNote? {
        notes(for: coinId).first
    }

    func notes(for coinId: String) -> [CoinNote] {
        do {
            let realm = try realmProvider.realm()
            migrateLegacyIfNeeded(coinId: coinId, in: realm)
            return Array(
                realm.objects(RMCoinNoteEntry.self)
                    .where { $0.coinId == coinId }
                    .sorted(byKeyPath: "updatedAt", ascending: false)
                    .map { $0.toDomain() }
            )
        } catch {
            AppLogger.realm.error("Failed to read notes: \(error.localizedDescription)")
            return []
        }
    }

    func allNotes() -> [CoinNote] {
        do {
            let realm = try realmProvider.realm()
            migrateAllLegacyIfNeeded(in: realm)
            return Array(
                realm.objects(RMCoinNoteEntry.self)
                    .sorted(byKeyPath: "updatedAt", ascending: false)
                    .map { $0.toDomain() }
            )
        } catch {
            AppLogger.realm.error("Failed to read all notes: \(error.localizedDescription)")
            return []
        }
    }

    func upsert(note: CoinNote) {
        do {
            let realm = try realmProvider.realm()
            try realm.write {
                let obj = realm.object(ofType: RMCoinNoteEntry.self, forPrimaryKey: note.id) ?? RMCoinNoteEntry()
                obj.noteId = note.id
                obj.coinId = note.coinId
                obj.coinName = note.coinName
                obj.coinSymbol = note.coinSymbol
                obj.text = note.text
                obj.createdAt = note.createdAt
                obj.updatedAt = note.updatedAt
                realm.add(obj, update: .modified)
            }
        } catch {
            AppLogger.realm.error("Failed to upsert note: \(error.localizedDescription)")
        }
    }

    @discardableResult
    func addNote(coinId: String, coinName: String, coinSymbol: String, text: String) -> CoinNote {
        let now = Date()
        let note = CoinNote(
            id: UUID().uuidString,
            coinId: coinId,
            coinName: coinName,
            coinSymbol: coinSymbol.uppercased(),
            text: text,
            createdAt: now,
            updatedAt: now
        )
        upsert(note: note)
        return note
    }

    func deleteNote(id: String) {
        do {
            let realm = try realmProvider.realm()
            guard let obj = realm.object(ofType: RMCoinNoteEntry.self, forPrimaryKey: id) else { return }
            try realm.write {
                realm.delete(obj)
            }
        } catch {
            AppLogger.realm.error("Failed to delete note: \(error.localizedDescription)")
        }
    }

    func deleteNotes(coinId: String) {
        do {
            let realm = try realmProvider.realm()
            let entries = realm.objects(RMCoinNoteEntry.self).where { $0.coinId == coinId }
            try realm.write {
                realm.delete(entries)
            }
        } catch {
            AppLogger.realm.error("Failed to delete notes by coin: \(error.localizedDescription)")
        }
    }

    func deleteAllNotes() {
        do {
            let realm = try realmProvider.realm()
            let entries = realm.objects(RMCoinNoteEntry.self)
            try realm.write {
                realm.delete(entries)
            }
        } catch {
            AppLogger.realm.error("Failed to delete all notes: \(error.localizedDescription)")
        }
    }

    private func migrateLegacyIfNeeded(coinId: String, in realm: Realm) {
        guard realm.objects(RMCoinNoteEntry.self).where({ $0.coinId == coinId }).isEmpty else { return }
        guard let legacy = realm.object(ofType: RMCoinNote.self, forPrimaryKey: coinId) else { return }
        do {
            try realm.write {
                let entry = RMCoinNoteEntry()
                entry.noteId = UUID().uuidString
                entry.coinId = legacy.coinId
                entry.coinName = legacy.coinId
                entry.coinSymbol = legacy.coinId.uppercased()
                entry.text = legacy.text
                entry.createdAt = legacy.updatedAt
                entry.updatedAt = legacy.updatedAt
                realm.add(entry, update: .modified)
                realm.delete(legacy)
            }
        } catch {
            AppLogger.realm.error("Failed to migrate legacy note: \(error.localizedDescription)")
        }
    }

    private func migrateAllLegacyIfNeeded(in realm: Realm) {
        let legacyItems = realm.objects(RMCoinNote.self)
        guard !legacyItems.isEmpty else { return }
        do {
            try realm.write {
                for legacy in legacyItems {
                    let exists = realm.objects(RMCoinNoteEntry.self).where { $0.coinId == legacy.coinId }.count > 0
                    if exists { continue }
                    let entry = RMCoinNoteEntry()
                    entry.noteId = UUID().uuidString
                    entry.coinId = legacy.coinId
                    entry.coinName = legacy.coinId
                    entry.coinSymbol = legacy.coinId.uppercased()
                    entry.text = legacy.text
                    entry.createdAt = legacy.updatedAt
                    entry.updatedAt = legacy.updatedAt
                    realm.add(entry, update: .modified)
                }
                realm.delete(legacyItems)
            }
        } catch {
            AppLogger.realm.error("Failed to migrate all legacy notes: \(error.localizedDescription)")
        }
    }
}
