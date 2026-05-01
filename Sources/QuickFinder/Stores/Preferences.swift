// Preferences.swift — petites préférences utilisateur persistées via UserDefaults.
// On expose un singleton observable pour que la fenêtre Préférences puisse
// binder directement.
import Foundation
import Combine

@MainActor
final class Preferences: ObservableObject {
    static let shared = Preferences()

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let recentsLimit = "recentsLimit"
    }

    @Published var recentsLimit: Int {
        didSet { defaults.set(recentsLimit, forKey: Keys.recentsLimit) }
    }

    private init() {
        let stored = UserDefaults.standard.integer(forKey: Keys.recentsLimit)
        self.recentsLimit = (stored == 0) ? 20 : stored
    }
}
