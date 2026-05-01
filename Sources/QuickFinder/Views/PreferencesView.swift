// PreferencesView.swift — fenêtre Préférences (séparée du popover).
// Contient :
// - Recorder de raccourci global (KeyboardShortcuts)
// - Toggle "Lancer au démarrage" (SMAppService)
// - Picker pour la limite de récents (10/20/50)
// - Bouton "Quitter QuickFinder"
import SwiftUI
import KeyboardShortcuts

struct PreferencesView: View {
    let onQuit: () -> Void

    @ObservedObject private var prefs = Preferences.shared
    @State private var launchAtLogin: Bool = LaunchAtLogin.isEnabled

    var body: some View {
        Form {
            Section("Raccourci global") {
                KeyboardShortcuts.Recorder("Ouvrir QuickFinder",
                                           name: .toggleQuickFinder)
            }

            Section("Démarrage") {
                Toggle("Lancer au démarrage de la session", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        LaunchAtLogin.isEnabled = newValue
                    }
            }

            Section("Récents") {
                Picker("Nombre de fichiers récents", selection: $prefs.recentsLimit) {
                    Text("10").tag(10)
                    Text("20").tag(20)
                    Text("50").tag(50)
                }
                .pickerStyle(.segmented)
            }

            Section {
                HStack {
                    Spacer()
                    Button("Quitter QuickFinder", role: .destructive) {
                        onQuit()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 320)
    }
}
