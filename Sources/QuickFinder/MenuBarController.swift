// MenuBarController.swift — gère NSStatusItem + NSPopover.
// L'icône de la barre de menu est un SF Symbol (folder.fill) ; un clic ouvre
// le popover, un nouveau clic le referme. Un event monitor global ferme aussi
// le popover quand l'utilisateur clique en dehors.
import AppKit
import SwiftUI

final class MenuBarController: NSObject, NSPopoverDelegate {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private var globalClickMonitor: Any?
    private let onOpenPreferences: () -> Void

    init(favoritesStore: FavoritesStore,
         recentsStore: RecentsStore,
         onOpenPreferences: @escaping () -> Void) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.popover = NSPopover()
        self.onOpenPreferences = onOpenPreferences
        super.init()

        configureStatusItem()
        configurePopover(favoritesStore: favoritesStore, recentsStore: recentsStore)
    }

    // MARK: - Setup

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        let image = NSImage(systemSymbolName: "folder.fill",
                            accessibilityDescription: "QuickFinder")
        image?.isTemplate = true // s'adapte light/dark mode automatiquement
        button.image = image
        button.target = self
        button.action = #selector(statusItemClicked(_:))
        // On veut récupérer aussi le clic droit pour le menu contextuel.
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func configurePopover(favoritesStore: FavoritesStore,
                                  recentsStore: RecentsStore) {
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentSize = NSSize(width: 380, height: 500)

        let root = PopoverRootView(
            onOpenPreferences: { [weak self] in
                self?.closePopover()
                self?.onOpenPreferences()
            },
            onRequestClose: { [weak self] in self?.closePopover() }
        )
        .environmentObject(favoritesStore)
        .environmentObject(recentsStore)

        popover.contentViewController = NSHostingController(rootView: root)
    }

    // MARK: - Actions

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showContextMenu(from: sender)
        } else {
            togglePopover()
        }
    }

    func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            openPopover()
        }
    }

    private func openPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        // Active l'app pour que le focus clavier fonctionne (champ de recherche).
        NSApp.activate(ignoringOtherApps: true)
        installGlobalClickMonitor()
    }

    private func closePopover() {
        popover.performClose(nil)
        removeGlobalClickMonitor()
    }

    // MARK: - Menu contextuel sur l'icône (clic droit)

    private func showContextMenu(from button: NSStatusBarButton) {
        let menu = NSMenu()
        menu.addItem(withTitle: "Préférences…", action: #selector(menuPreferences),
                     keyEquivalent: ",").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quitter QuickFinder", action: #selector(menuQuit),
                     keyEquivalent: "q").target = self
        statusItem.menu = menu
        button.performClick(nil)
        // On retire le menu après affichage pour ne pas court-circuiter le clic gauche.
        statusItem.menu = nil
    }

    @objc private func menuPreferences() { onOpenPreferences() }
    @objc private func menuQuit() { NSApp.terminate(nil) }

    // MARK: - Click outside

    private func installGlobalClickMonitor() {
        guard globalClickMonitor == nil else { return }
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            self?.closePopover()
        }
    }

    private func removeGlobalClickMonitor() {
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
            globalClickMonitor = nil
        }
    }

    // MARK: - NSPopoverDelegate

    func popoverDidClose(_ notification: Notification) {
        removeGlobalClickMonitor()
    }
}
