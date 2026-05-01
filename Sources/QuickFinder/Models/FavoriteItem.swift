// FavoriteItem.swift — un dossier favori, persistant via security-scoped bookmark.
// Le bookmark est stocké en Data dans UserDefaults ; à chaque résolution, on
// vérifie si le bookmark est devenu "stale" et on le régénère le cas échéant.
import Foundation

struct FavoriteItem: Identifiable, Hashable, Codable {
    let id: UUID
    var displayName: String
    var bookmarkData: Data

    init(id: UUID = UUID(), displayName: String, bookmarkData: Data) {
        self.id = id
        self.displayName = displayName
        self.bookmarkData = bookmarkData
    }

    /// Résout le bookmark vers une URL. Met à jour `bookmarkData` si stale.
    /// Retourne nil si le dossier est introuvable (déplacé/supprimé).
    mutating func resolveURL() -> URL? {
        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            if isStale, let refreshed = try? url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            ) {
                bookmarkData = refreshed
            }
            return url
        } catch {
            return nil
        }
    }
}
