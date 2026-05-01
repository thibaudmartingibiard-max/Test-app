// RecentsStore.swift — récupère les fichiers récemment ouverts.
// Source primaire : NSDocumentController.shared.recentDocumentURLs.
// Fallback : on lit les valeurs persistées de NSGlobalDomain ("NSRecentDocuments")
// si la première source est vide. (LSSharedFileList est déprécié depuis macOS 10.11
// et supprimé pratiquement ; on garde donc un fallback léger via UserDefaults.)
import Foundation
import AppKit
import Combine

/// Appelé depuis le main thread (vues SwiftUI, AppDelegate). Pas de
/// @MainActor pour rester compatible avec les closures non isolées.
final class RecentsStore: ObservableObject {
    @Published private(set) var entries: [FileEntry] = []

    /// Recharge la liste des récents en respectant la limite des préférences.
    func refresh() {
        let limit = Preferences.shared.recentsLimit
        var urls = NSDocumentController.shared.recentDocumentURLs

        if urls.isEmpty {
            urls = readGlobalRecentDocuments()
        }

        // Filtre les URLs encore existantes et garde l'ordre.
        let entries: [FileEntry] = urls
            .prefix(limit)
            .compactMap { url in
                guard FileManager.default.fileExists(atPath: url.path) else { return nil }
                return FileEntry.make(from: url)
            }
        self.entries = entries
    }

    /// Fallback : lit la liste globale des documents récents agrégée par macOS.
    private func readGlobalRecentDocuments() -> [URL] {
        // CFPreferences renvoie souvent un tableau de chaînes/dicts ; on
        // n'inspecte que les chemins exploitables. Sans entitlement, l'accès
        // à d'autres bundles est limité — on retourne donc un best-effort.
        let bundleIDs = ["com.apple.finder", "NSGlobalDomain"]
        var urls: [URL] = []
        for bundleID in bundleIDs {
            if let raw = CFPreferencesCopyAppValue(
                "NSRecentDocuments" as CFString, bundleID as CFString
            ) as? [Any] {
                for entry in raw {
                    if let dict = entry as? [String: Any],
                       let path = dict["_NSLocator"] as? String {
                        urls.append(URL(fileURLWithPath: path))
                    } else if let path = entry as? String {
                        urls.append(URL(fileURLWithPath: path))
                    }
                }
            }
        }
        return urls
    }
}
