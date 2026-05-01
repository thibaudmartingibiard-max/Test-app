// PopoverRootView.swift — la vue racine du popover.
// Un TabView SwiftUI avec 3 onglets (Favoris / Récents / Recherche), icônes
// SF Symbols. Padding global 12pt. Le scope est limité à 380×500 par le popover.
import SwiftUI

struct PopoverRootView: View {
    let onOpenPreferences: () -> Void
    let onRequestClose: () -> Void

    @State private var selectedTab: Tab = .favorites

    enum Tab: Hashable { case favorites, recents, search }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                FavoritesView(onRequestClose: onRequestClose)
                    .tabItem { Label("Favoris", systemImage: "star.fill") }
                    .tag(Tab.favorites)

                RecentsView(onRequestClose: onRequestClose)
                    .tabItem { Label("Récents", systemImage: "clock.fill") }
                    .tag(Tab.recents)

                SearchView(onRequestClose: onRequestClose)
                    .tabItem { Label("Recherche", systemImage: "magnifyingglass") }
                    .tag(Tab.search)
            }
            .padding(12)

            Divider()
            footer
        }
        .frame(width: 380, height: 500)
        .onAppear {
            // À l'ouverture, on bascule directement sur Recherche pour bénéficier
            // du focus auto sur le champ. (L'utilisateur peut toujours revenir
            // sur Favoris/Récents.)
            selectedTab = .search
        }
    }

    private var footer: some View {
        HStack {
            Button {
                onOpenPreferences()
            } label: {
                Label("Préférences", systemImage: "gearshape")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut(",", modifiers: [.command])

            Spacer()

            Button {
                NSApp.terminate(nil)
            } label: {
                Label("Quitter", systemImage: "power")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut("q", modifiers: [.command])
        }
        .font(.system(size: 11))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
