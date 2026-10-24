import SwiftUI

/// Peels the latest assign, finish, or waste. No haptic of its own.
struct UndoPeelView: View {
    var enabled: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.uturn.backward")
                .font(TypeFace.callout)
                .foregroundStyle(DesignTokens.ink)
                .frame(width: Chrome.hit, height: Chrome.hit)
                .contentShape(Rectangle())
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.42)
        .accessibilityLabel("Undo")
    }
}
