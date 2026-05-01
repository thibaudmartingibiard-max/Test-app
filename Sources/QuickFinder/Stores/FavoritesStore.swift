// FavoritesStore.swift — gestion des dossiers favoris.
// Persistance UserDefaults sous la clé "favorites" : tableau encodé JSON
// de FavoriteItem (chacun contenant un security-scoped bookmark).
//
// Les opérations d'accès aux URLs des favoris doivent être encadrées par
// startAccessingSecurityScopedResource() / stop... pour respecter les règles
// d'accès, même hors sandbox (c'est un no-op hors sandbox mais c'est propre).
import Foundation
import AppKit
import Combine

/// Toutes les méthodes sont conçues pour être appelées depuis le main thread
/// (vues SwiftUI, AppDelegate). On évite l'annotation @MainActor pour
/// préserver la souplesse d'appel depuis les closures AppKit non isolées.
final class FavoritesStore: ObservableObject {
    @Published private(set) var items: [FavoriteItem] = []

    private let defaultsKey = "favorites"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    // MARK: - Persistance

    private func load() {
        guard let data = defaults.data(forKey: defaultsKey) else { return }
        if let decoded = try? JSONDecoder().decode([FavoriteItem].self, from: data) {
            items = decoded
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: defaultsKey)
        }
    }

    // MARK: - CRUD

    /// Ajoute un favori à partir d'une URL (ex: choisie via NSOpenPanel).
    func add(url: URL) {
        guard let bookmark = try? url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }
        let item = FavoriteItem(displayName: url.lastPathComponent,
                                bookmarkData: bookmark)
        items.append(item)
        save()
    }

    func remove(_ item: FavoriteItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func rename(_ item: FavoriteItem, to newName: String) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].displayName = newName
        save()
    }

    // MARK: - Résolution & accès filesystem

    /// Résout le favori vers son URL réelle. Si le bookmark est stale, on
    /// programme la mise à jour pour le prochain runloop afin de ne pas muter
    /// `@Published items` pendant un cycle de rendu SwiftUI.
    func url(for item: FavoriteItem) -> URL? {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return nil }
        var copy = items[idx]
        let url = copy.resolveURL()
        if copy.bookmarkData != items[idx].bookmarkData {
            let refreshed = copy
            DispatchQueue.main.async { [weak self] in
                guard let self,
                      let i = self.items.firstIndex(where: { $0.id == refreshed.id })
                else { return }
                self.items[i] = refreshed
                self.save()
            }
        }
        return url
    }

    /// Liste un dossier favori : sous-dossiers d'abord, puis fichiers,
    /// triés alphabétiquement et plafonnés à `limit` (50 par défaut).
    func listChildren(of url: URL, limit: Int = 50) -> [FileEntry] {
        let didStart = url.startAccessingSecurityScopedResource()
        defer { if didStart { url.stopAccessingSecurityScopedResource() } }

        let keys: [URLResourceKey] = [
            .isDirectoryKey, .nameKey, .contentModificationDateKey,
        ]
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else { return [] }

        let entries = urls.compactMap(FileEntry.make(from:))
        let sorted = entries.sorted { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory { return lhs.isDirectory }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
        return Array(sorted.prefix(limit))
    }
}
