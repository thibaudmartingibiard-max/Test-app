# QuickFinder

App **macOS 13+** de barre de menu écrite en Swift natif (SwiftUI + AppKit).
QuickFinder vit dans la barre de menu (icône `folder.fill`), ouvre un popover
au clic et expose trois onglets : **Favoris**, **Récents**, **Recherche**.

> ⚠️ **Note importante sur cette livraison**
>
> Le code a été écrit dans un environnement Linux où ni Swift, ni les frameworks
> Apple (AppKit/SwiftUI/Carbon/SMAppService), ni `screencapture` ne sont
> disponibles. La compilation **n'a donc pas été vérifiée** ; le projet est
> conçu pour compiler tel quel sur un Mac (Xcode 15+ / Swift 5.9+, macOS 13+),
> mais des ajustements mineurs peuvent être nécessaires au premier `swift build`.
> Il n'y a pas de capture d'écran fournie pour la même raison.

## Pré-requis

- macOS 13 Ventura ou plus récent
- Xcode 15 (ou les Command Line Tools) → fournit Swift 5.9+
- Réseau pour résoudre la dépendance `KeyboardShortcuts`

## Build & lancement

```sh
make build    # swift build -c release
make run      # build + lance le binaire ; l'icône apparaît dans la barre de menu
make clean    # nettoie .build
make install  # crée /Applications/QuickFinder.app à partir du binaire release
make uninstall
```

Lien symbolique : `~/Developer/QuickFinder` pointe vers la racine de ce dépôt
(créé par `ln -sfn`), conformément à la consigne.

### Première installation propre

`make run` est pratique pour itérer mais le binaire vit alors dans `.build/`.
Pour avoir un vrai *login item* fonctionnel via SMAppService et un raccourci
système qui survit au reboot, faites :

```sh
make install
open /Applications/QuickFinder.app
```

## Raccourcis

| Raccourci         | Action                                |
|-------------------|---------------------------------------|
| ⌘⇧Espace          | Ouvre / ferme le popover (modifiable) |
| ⌘,                | Ouvre la fenêtre Préférences          |
| ⌘Q                | Quitte QuickFinder                    |
| ⌘+clic            | Ouvre l'élément dans Finder           |
| ↑ / ↓ / ⏎         | Navigue/ouvre dans l'onglet Recherche |

Clic-droit sur un favori → menu contextuel (Renommer / Retirer / Ouvrir dans Finder).
Clic-droit sur l'icône de la barre de menu → Préférences / Quitter.

## Architecture

MVVM léger, un store par domaine :

```
Sources/QuickFinder/
├── main.swift                  Point d'entrée NSApplication
├── AppDelegate.swift           Câblage des stores + raccourci global
├── MenuBarController.swift     NSStatusItem + NSPopover + monitor clics extérieurs
├── Models/
│   ├── FavoriteItem.swift      Bookmark sécurisé persistant
│   └── FileEntry.swift         URL + métadonnées + icône
├── Stores/
│   ├── FavoritesStore.swift    UserDefaults + security-scoped bookmarks
│   ├── RecentsStore.swift      NSDocumentController.recentDocumentURLs (+fallback)
│   ├── SearchService.swift     NSMetadataQuery + debounce 200 ms
│   └── Preferences.swift       Petites prefs persistantes
├── Utilities/
│   ├── RelativeDateFormatter.swift   "il y a 2h", locale fr_FR
│   └── LaunchAtLogin.swift           Wrapper SMAppService.mainApp
└── Views/
    ├── PopoverRootView.swift   TabView 380×500, footer Préférences/Quitter
    ├── FavoritesView.swift     Drill-in 1 niveau + breadcrumb + menu contextuel
    ├── RecentsView.swift       Liste récents
    ├── SearchView.swift        Champ + résultats + ↑↓⏎
    ├── FileRowView.swift       Ligne 32pt réutilisable
    └── PreferencesView.swift   Recorder shortcut + login item + limite récents
```

## Notes de dev

- **Sandbox** : désactivé (v1) pour avoir l'accès libre au filesystem. Les
  bookmarks restent créés avec `.withSecurityScope` au cas où l'app serait
  un jour sandboxée.
- **LSUIElement = true** dans `Info.plist` → pas d'icône dock.
- **NSApplication.shared.setActivationPolicy(.accessory)** appelé dans
  `main.swift` → cohérent avec LSUIElement.
- **Spotlight scope** : par défaut `NSMetadataQueryUserHomeScope`. Le toggle
  "Limiter aux favoris" remplace le scope par les URLs des favoris résolus.
- **macOS 13** : on n'utilise PAS `.onKeyPress` (macOS 14+) ; les flèches/Enter
  sont interceptées via `NSEvent.addLocalMonitorForEvents`.
- **SMAppService** : ne fonctionne que pour un binaire vivant dans /Applications
  et signé. En `swift run`, le toggle "Lancer au démarrage" loguera une erreur,
  ce qui est attendu — utilisez `make install` puis activez le toggle.
- **LSSharedFileList** est déprécié et de moins en moins utilisable hors
  bundle système : le fallback de `RecentsStore` lit `NSRecentDocuments` via
  `CFPreferencesCopyAppValue` (best-effort) si `NSDocumentController` est vide.

## Limitations connues

- Première compilation susceptible de réclamer `Package.resolved` (`swift package resolve`).
- Le toggle "Lancer au démarrage" requiert l'app installée + signée.
- Les hover/animations utilisent `withAnimation(.smooth)` — ok macOS 13+.
