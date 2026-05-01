// RecentsView.swift — onglet Récents.
// Affiche les N derniers fichiers ouverts (limite définie dans les Préférences).
// Date relative à droite ; clic ouvre le fichier ; Cmd+clic révèle dans Finder.
import SwiftUI
import AppKit

struct RecentsView: View {
    let onRequestClose: () -> Void

    @EnvironmentObject private var store: RecentsStore

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Récents")
                    .font(.headline)
                Spacer()
                Button {
                    store.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Rafraîchir")
            }

            if store.entries.isEmpty {
                VStack {
                    Spacer()
                    Text("Aucun fichier récent.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(store.entries) { entry in
                            FileRowView(
                                entry: entry,
                                trailingText: RelativeDateFormatter.string(
                                    from: entry.modificationDate
                                )
                            )
                            .onTapGesture {
                                if NSEvent.modifierFlags.contains(.command) {
                                    NSWorkspace.shared.activateFileViewerSelecting([entry.url])
                                } else {
                                    NSWorkspace.shared.open(entry.url)
                                }
                                onRequestClose()
                            }
                        }
                    }
                }
            }
        }
        .onAppear { store.refresh() }
    }
}
