// RelativeDateFormatter.swift — formate une date en français façon
// "il y a 2h", "il y a 3 j", "à l'instant".
import Foundation

enum RelativeDateFormatter {
    private static let formatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.unitsStyle = .short
        return f
    }()

    static func string(from date: Date?, reference: Date = Date()) -> String {
        guard let date else { return "" }
        return formatter.localizedString(for: date, relativeTo: reference)
    }
}
