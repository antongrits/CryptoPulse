import SwiftUI

struct NotesLibraryView: View {
    @StateObject var viewModel: NotesLibraryViewModel
    let coinRepository: CoinRepositoryProtocol
    let favoritesRepository: FavoritesRepositoryProtocol
    let portfolioRepository: PortfolioRepositoryProtocol
    let alertsRepository: AlertsRepositoryProtocol
    let notesRepository: NotesRepositoryProtocol
    @State private var showClearConfirmation = false

    var body: some View {
        AppNavigationContainer {
            Group {
                if viewModel.groupedNotes.isEmpty {
                    ScrollView {
                        VStack {
                            Spacer(minLength: 80)
                            EmptyStateView(
                                title: NSLocalizedString("No notes yet", comment: ""),
                                message: NSLocalizedString("Add a note…", comment: ""),
                                assetName: "EmptySearch",
                                systemImageFallback: "note.text"
                            )
                            .frame(maxWidth: .infinity, alignment: .center)
                            Spacer(minLength: 120)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, AppSpacing.md)
                    }
                } else {
                    List {
                        ForEach(viewModel.groupedNotes, id: \.date) { section in
                            Section(header: Text(DateFormatter.notesSection.string(from: section.date))) {
                                ForEach(section.notes) { note in
                                    NavigationLink {
                                        CoinDetailsView(viewModel: CoinDetailsViewModel(
                                            coinId: note.coinId,
                                            coinRepository: coinRepository,
                                            favoritesRepository: favoritesRepository,
                                            portfolioRepository: portfolioRepository,
                                            alertsRepository: alertsRepository,
                                            notesRepository: notesRepository
                                        ))
                                    } label: {
                                        noteRow(note)
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            viewModel.deleteNote(id: note.id)
                                        } label: {
                                            Label(NSLocalizedString("Delete", comment: ""), systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: NSLocalizedString("Search", comment: ""))
            .navigationTitle(NSLocalizedString("Notes", comment: ""))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.notes.isEmpty {
                        Button(role: .destructive) {
                            showClearConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .confirmationDialog(
                NSLocalizedString("Clear all notes?", comment: ""),
                isPresented: $showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button(NSLocalizedString("Clear", comment: ""), role: .destructive) {
                    viewModel.clearAllNotes()
                }
                Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) {}
            }
            .onAppear {
                viewModel.load()
            }
        }
    }

    private func noteRow(_ note: CoinNote) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(note.coinName)
                    .font(AppTypography.headline)
                    .lineLimit(2)
                Spacer()
                Text(note.coinSymbol.uppercased())
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            Text(note.text)
                .font(AppTypography.body)
                .lineLimit(3)
                .foregroundColor(AppColors.textPrimary)
            Text(DateFormatter.shortDateTime.string(from: note.updatedAt))
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.vertical, 4)
    }
}

private extension DateFormatter {
    static let notesSection: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

#Preview {
    NotesLibraryView(
        viewModel: NotesLibraryViewModel(notesRepository: NotesRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview"))),
        coinRepository: CoinRepository(service: MockCoinGeckoService(), realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        favoritesRepository: FavoritesRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        portfolioRepository: PortfolioRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        alertsRepository: AlertsRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview")),
        notesRepository: NotesRepository(realmProvider: RealmProvider(inMemory: true, identifier: "preview"))
    )
}
