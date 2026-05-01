// FavoritesView.swift — onglet Favoris.
// Deux niveaux d'affichage :
// - racine : liste des favoris + bouton "+", menu contextuel (Renommer / Retirer / Ouvrir).
// - drill-in : breadcrumb + listing du dossier courant (limité à 50 items).
//   Cmd+clic sur un dossier l'ouvre dans Finder ; clic simple descend dedans.
import SwiftUI
import AppKit

struct FavoritesView: View {
    let onRequestClose: () -> Void

    @EnvironmentObject private var store: FavoritesStore

    /// Pile d'URLs visitées pour le drill-in. Vide => on est à la racine.
    @State private var navigationStack: [URL] = []
    @State private var renameTarget: FavoriteItem?
    @State private var renameDraft: String = ""

    var body: some View {
        VStack(spacing: 8) {
            header
            if navigationStack.isEmpty {
                rootList
            } else {
                drillList
            }
        }
        .sheet(item: $renameTarget) { item in
            renameSheet(for: item)
        }
    }

    // MARK: - Header (titre + breadcrumb + bouton +)

    private var header: some View {
        HStack(spacing: 6) {
            if !navigationStack.isEmpty {
                Button {
                    withAnimation(.smooth) { _ = navigationStack.popLast() }
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.borderless)
            }

            Text(headerTitle)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            if navigationStack.isEmpty {
                Button {
                    addFavorite()
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help("Ajouter un dossier favori")
            }
        }
    }

    private var headerTitle: String {
        if let current = navigationStack.last {
            return current.lastPathComponent
        }
        return "Favoris"
    }

    // MARK: - Liste racine

    @ViewBuilder
    private var rootList: some View {
        if store.items.isEmpty {
            placeholder("Aucun favori. Cliquez sur + pour en ajouter un.")
        } else {
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(store.items) { item in
                        favoriteRow(item)
                    }
                }
            }
        }
    }

    private func favoriteRow(_ item: FavoriteItem) -> some View {
        let url = store.url(for: item)
        let entry = url.flatMap { FileEntry.make(from: $0) }
            ?? FileEntry(id: URL(fileURLWithPath: "/" + item.id.uuidString),
                         url: URL(fileURLWithPath: "/"),
                         name: item.displayName,
                         isDirectory: true,
                         modificationDate: nil)

        return FileRowView(entry: entry)
            .onTapGesture {
                guard let url else { return }
                if NSEvent.modifierFlags.contains(.command) {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                    onRequestClose()
                } else {
                    withAnimation(.smooth) { navigationStack.append(url) }
                }
            }
            .contextMenu {
                Button("Renommer") {
                    renameDraft = item.displayName
                    renameTarget = item
                }
                Button("Retirer des favoris", role: .destructive) {
                    store.remove(item)
                }
                if let url {
                    Divider()
                    Button("Ouvrir dans Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                        onRequestClose()
                    }
                }
            }
    }

    // MARK: - Liste drill-in

    @ViewBuilder
    private var drillList: some View {
        let current = navigationStack.last!
        let children = store.listChildren(of: current)

        if children.isEmpty {
            placeholder("Dossier vide.")
        } else {
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(children) { entry in
                        FileRowView(
                            entry: entry,
                            trailingText: entry.isDirectory ? nil : RelativeDateFormatter.string(
                                from: entry.modificationDate
                            )
                        )
                        .onTapGesture { handleTap(on: entry) }
                    }
                }
            }
        }
    }

    private func handleTap(on entry: FileEntry) {
        if entry.isDirectory {
            if NSEvent.modifierFlags.contains(.command) {
                NSWorkspace.shared.activateFileViewerSelecting([entry.url])
                onRequestClose()
            } else {
                withAnimation(.smooth) { navigationStack.append(entry.url) }
            }
        } else {
            NSWorkspace.shared.open(entry.url)
            onRequestClose()
        }
    }

    // MARK: - Helpers

    private func addFavorite() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Ajouter aux favoris"
        if panel.runModal() == .OK, let url = panel.url {
            store.add(url: url)
        }
    }

    private func placeholder(_ text: String) -> some View {
        VStack {
            Spacer()
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func renameSheet(for item: FavoriteItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Renommer le favori")
                .font(.headline)
            TextField("Nom", text: $renameDraft)
                .textFieldStyle(.roundedBorder)
            HStack {
                Spacer()
                Button("Annuler") { renameTarget = nil }
                Button("Enregistrer") {
                    let trimmed = renameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        store.rename(item, to: trimmed)
                    }
                    renameTarget = nil
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(width: 320)
    }
}
