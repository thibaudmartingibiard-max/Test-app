// SearchService.swift — wrapper SwiftUI-friendly autour de NSMetadataQuery.
// On expose une @Published [FileEntry] et on gère un debounce de 200 ms sur
// le texte saisi pour éviter de relancer une query Spotlight à chaque frappe.
import Foundation
import AppKit
import Combine

@MainActor
final class SearchService: ObservableObject {
    @Published var query: String = ""
    @Published var scopeToFavorites: Bool = false
    @Published private(set) var results: [FileEntry] = []

    private let metadataQuery = NSMetadataQuery()
    private var cancellables = Set<AnyCancellable>()
    weak var favoritesStore: FavoritesStore?

    init(favoritesStore: FavoritesStore? = nil) {
        self.favoritesStore = favoritesStore
        setupBindings()
        setupNotifications()
    }

    deinit {
        // NotificationCenter.removeObserver est thread-safe ; on évite de
        // toucher metadataQuery ici car NSMetadataQuery.stop() exige le main
        // thread et la deinit n'est pas garantie d'y être exécutée.
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Bindings

    private func setupBindings() {
        // Debounce 200 ms sur la combinaison (texte + scope).
        Publishers.CombineLatest($query, $scopeToFavorites)
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] text, scoped in
                self?.runQuery(text: text, scopeToFavorites: scoped)
            }
            .store(in: &cancellables)
    }

    private func setupNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(queryDidUpdate(_:)),
                       name: .NSMetadataQueryDidFinishGathering,
                       object: metadataQuery)
        nc.addObserver(self,
                       selector: #selector(queryDidUpdate(_:)),
                       name: .NSMetadataQueryDidUpdate,
                       object: metadataQuery)
    }

    // MARK: - Query lifecycle

    private func runQuery(text: String, scopeToFavorites: Bool) {
        metadataQuery.stop()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            return
        }

        // Recherche sur le nom de fichier (kMDItemFSName), insensible à la casse.
        let predicate = NSPredicate(
            format: "kMDItemFSName LIKE[cd] %@",
            "*\(trimmed)*"
        )
        metadataQuery.predicate = predicate
        metadataQuery.sortDescriptors = [
            NSSortDescriptor(key: "kMDItemFSName", ascending: true,
                             selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))),
        ]
        metadataQuery.searchScopes = computeScopes(scopeToFavorites: scopeToFavorites)
        metadataQuery.start()
    }

    private func computeScopes(scopeToFavorites: Bool) -> [Any] {
        if scopeToFavorites, let store = favoritesStore {
            // On résout chaque favori en URL réelle.
            let urls: [URL] = store.items.compactMap { item in
                var copy = item
                return copy.resolveURL()
            }
            return urls.isEmpty ? [NSMetadataQueryUserHomeScope] : urls
        }
        return [NSMetadataQueryUserHomeScope]
    }

    @objc private func queryDidUpdate(_ note: Notification) {
        metadataQuery.disableUpdates()
        defer { metadataQuery.enableUpdates() }

        let count = min(metadataQuery.resultCount, 30)
        var collected: [FileEntry] = []
        for i in 0..<count {
            guard let item = metadataQuery.result(at: i) as? NSMetadataItem,
                  let path = item.value(forAttribute: NSMetadataItemPathKey) as? String
            else { continue }
            if let entry = FileEntry.make(from: URL(fileURLWithPath: path)) {
                collected.append(entry)
            }
        }
        results = collected
    }
}
