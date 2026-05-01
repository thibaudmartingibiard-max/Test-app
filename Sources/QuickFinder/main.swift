// main.swift — point d'entrée de l'app QuickFinder.
// On configure NSApplication en mode "accessory" : pas d'icône dans le Dock,
// l'app vit uniquement dans la barre de menu (couplé à LSUIElement=true).
import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
