// LaunchAtLogin.swift — wrapper SMAppService (macOS 13+).
// SMAppService.mainApp permet d'enregistrer l'app courante comme login item
// sans avoir à écrire un helper séparé.
import Foundation
import ServiceManagement

enum LaunchAtLogin {
    /// Indique si l'app est actuellement enregistrée pour démarrer à l'ouverture
    /// de session.
    static var isEnabled: Bool {
        get {
            SMAppService.mainApp.status == .enabled
        }
        set {
            do {
                if newValue {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                NSLog("LaunchAtLogin: échec mise à jour : \(error.localizedDescription)")
            }
        }
    }
}
