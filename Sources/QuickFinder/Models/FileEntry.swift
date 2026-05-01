// FileEntry.swift — représentation légère d'un fichier ou dossier affiché dans
// les listes (favoris dépliés, récents, résultats de recherche).
import Foundation
import AppKit

struct FileEntry: Identifiable, Hashable {
    let id: URL // l'URL est unique => fait un bon identifiant
    let url: URL
    let name: String
    let isDirectory: Bool
    let modificationDate: Date?

    var parentPath: String {
        url.deletingLastPathComponent().path
    }

    /// Charge l'icône native fournie par macOS pour ce chemin.
    /// (NSWorkspace.icon est appelé côté UI ; on évite de cacher ici pour
    /// rester thread-safe — la liste est de toute façon plafonnée à 50.)
    func loadIcon() -> NSImage {
        NSWorkspace.shared.icon(forFile: url.path)
    }

    /// Construit une FileEntry à partir d'une URL en lisant les attributs.
    static func make(from url: URL) -> FileEntry? {
        let keys: Set<URLResourceKey> = [
            .isDirectoryKey, .nameKey, .contentModificationDateKey,
        ]
        guard let values = try? url.resourceValues(forKeys: keys) else { return nil }
        return FileEntry(
            id: url,
            url: url,
            name: values.name ?? url.lastPathComponent,
            isDirectory: values.isDirectory ?? false,
            modificationDate: values.contentModificationDate
        )
    }
}
