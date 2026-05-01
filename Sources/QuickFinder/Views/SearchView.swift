// SearchView.swift — onglet Recherche.
// Champ texte avec focus automatique à l'apparition. Spotlight via SearchService.
// Flèches haut/bas naviguent dans les résultats, Enter ouvre la sélection.
import SwiftUI
import AppKit

struct SearchView: View {
    let onRequestClose: () -> Void

    @EnvironmentObject private var favoritesStore: FavoritesStore
    @StateObject private var service: SearchService
    @FocusState private var fieldFocused: Bool
    @State private var selectedIndex: Int = 0
    @State private var keyMonitor: Any?

    init(onRequestClose: @escaping () -> Void) {
        self.onRequestClose = onRequestClose
        // Le service est créé sans favorites store ici ; on le rebrancera via
        // .onAppear (workaround : SearchService prend le store en init mais
        // on n'a pas encore l'EnvironmentObject à ce stade).
        _service = StateObject(wrappedValue: SearchService())
    }

    var body: some View {
        VStack(spacing: 8) {
            searchField
            scopeToggle

            if service.results.isEmpty {
                VStack {
                    Spacer()
                    Text(service.query.isEmpty
                         ? "Tapez pour rechercher dans Spotlight…"
                         : "Aucun résultat.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(Array(service.results.enumerated()), id: \.element.id) { idx, entry in
                                FileRowView(entry: entry, showsParentPath: true)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(idx == selectedIndex
                                                  ? Color(nsColor: .controlAccentColor).opacity(0.20)
                                                  : Color.clear)
                                    )
                                    .id(idx)
                                    .onTapGesture {
                                        selectedIndex = idx
                                        open(entry: entry)
                                    }
                            }
                        }
                    }
                    .onChange(of: selectedIndex) { newValue in
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
        .onAppear {
            service.favoritesStore = favoritesStore
            fieldFocused = true
            installKeyMonitor()
        }
        .onDisappear {
            removeKeyMonitor()
        }
        .onChange(of: service.results) { _ in
            selectedIndex = 0
        }
    }

    /// Monitor local pour intercepter ↑/↓/Enter pendant que le popover est visible.
    /// Compatible macOS 13 (contrairement à `.onKeyPress`, dispo seulement en 14+).
    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            switch event.keyCode {
            case 126: // arrow up
                moveSelection(by: -1)
                return nil
            case 125: // arrow down
                moveSelection(by: +1)
                return nil
            case 36, 76: // Return / KP-Enter
                openSelected()
                return nil
            default:
                return event
            }
        }
    }

    private func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Rechercher", text: $service.query)
                .textFieldStyle(.plain)
                .focused($fieldFocused)
                .onSubmit { openSelected() }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: .textBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }

    private var scopeToggle: some View {
        Toggle(isOn: $service.scopeToFavorites) {
            Text("Limiter aux favoris")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .toggleStyle(.checkbox)
    }

    private func moveSelection(by delta: Int) {
        guard !service.results.isEmpty else { return }
        let next = max(0, min(service.results.count - 1, selectedIndex + delta))
        selectedIndex = next
    }

    private func openSelected() {
        guard service.results.indices.contains(selectedIndex) else { return }
        open(entry: service.results[selectedIndex])
    }

    private func open(entry: FileEntry) {
        if entry.isDirectory && NSEvent.modifierFlags.contains(.command) {
            NSWorkspace.shared.activateFileViewerSelecting([entry.url])
        } else {
            NSWorkspace.shared.open(entry.url)
        }
        onRequestClose()
    }
}
