// FileRowView.swift — ligne 32pt réutilisable : icône native + nom + détail.
// Hover state via NSColor.controlAccentColor avec opacité 0.15.
import SwiftUI
import AppKit

struct FileRowView: View {
    let entry: FileEntry
    var trailingText: String? = nil
    var showsParentPath: Bool = false

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Image(nsImage: entry.loadIcon())
                .resizable()
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(entry.name)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .truncationMode(.middle)

                if showsParentPath {
                    Text(entry.parentPath)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer(minLength: 4)

            if let trailing = trailingText {
                Text(trailing)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 32)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: .controlAccentColor).opacity(isHovering ? 0.15 : 0))
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) { isHovering = hovering }
        }
        .contentShape(Rectangle())
    }
}
