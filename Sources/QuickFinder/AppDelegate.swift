// AppDelegate.swift — orchestre les stores partagés et la fenêtre Préférences.
// Volontairement léger : la barre de menu est gérée par MenuBarController,
// et chaque domaine (favoris, récents, recherche) a son propre store en MVVM.
import AppKit
import SwiftUI
import KeyboardShortcuts

final class AppDelegate: NSObject, NSApplicationDelegate {
    // Stores partagés à l'échelle de l'app (injectés dans les vues SwiftUI).
    let favoritesStore = FavoritesStore()
    let recentsStore = RecentsStore()
    let preferences = Preferences.shared

    private var menuBarController: MenuBarController?
    private var preferencesWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1) Construit la status bar et le popover.
        menuBarController = MenuBarController(
            favoritesStore: favoritesStore,
            recentsStore: recentsStore,
            onOpenPreferences: { [weak self] in self?.openPreferences() }
        )

        // 2) Branche le raccourci global Cmd+Shift+Space sur l'ouverture du popover.
        KeyboardShortcuts.onKeyDown(for: .toggleQuickFinder) { [weak self] in
            self?.menuBarController?.togglePopover()
        }

        // 3) Première lecture des récents.
        recentsStore.refresh()
    }

    // Ouvre (ou ramène au premier plan) la fenêtre Préférences.
    func openPreferences() {
        if let window = preferencesWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let view = PreferencesView(
            onQuit: { NSApp.terminate(nil) }
        )
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = "Préférences QuickFinder"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 420, height: 320))
        window.center()
        window.isReleasedWhenClosed = false
        preferencesWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// Déclaration du raccourci global utilisé par KeyboardShortcuts.
// La valeur par défaut peut être surchargée depuis la fenêtre Préférences.
extension KeyboardShortcuts.Name {
    static let toggleQuickFinder = Self(
        "toggleQuickFinder",
        default: .init(.space, modifiers: [.command, .shift])
    )
}
