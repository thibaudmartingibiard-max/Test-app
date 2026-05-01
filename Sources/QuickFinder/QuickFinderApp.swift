// QuickFinderApp.swift — point d'entrée @main de l'app.
// On configure NSApplication en mode "accessory" : pas d'icône Dock, l'app
// vit uniquement dans la barre de menu (couplé à LSUIElement=true).
import AppKit

@main
@MainActor
enum QuickFinderApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
