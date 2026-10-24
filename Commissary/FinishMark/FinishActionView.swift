import SwiftUI

/// Finish control. Quiet glass, not the live accent, unless it is the only verb.
struct FinishActionView: View {
    var title: String
    var enabled: Bool
    var action: () -> Void

    var body: some View {
        GlassButton(title: "Finish \(title)", system: "checkmark", tone: .quiet, enabled: enabled, action: action)
    }
}

/// Seated tins only. Finish is the verb on this page.
struct FinishCoverView: View {
    var settle: Bool
    @Environment(LarderStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var busy = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s4) {
                    HeroWord(text: "USED")
                    Text("Finish a seated tin when it is actually cooked.")
                        .font(TypeFace.body)
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if store.board.pantry.assigned.isEmpty {
                        Text("No tin is seated yet. Assign one on the shelf first.")
                            .font(TypeFace.body)
                            .foregroundStyle(DesignTokens.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        ForEach(store.board.pantry.assigned) { tin in
                            VStack(alignment: .leading, spacing: Spacing.s2) {
                                Text(tin.tin.title)
                                    .font(TypeFace.title)
                                    .foregroundStyle(DesignTokens.ink)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                CountLabel(value: tin.daysLeft)
                                    .font(TypeFace.callout)
                                    .foregroundStyle(DesignTokens.muted)
                                GlassButton(title: "Finish \(tin.tin.title)", system: "checkmark", tone: .live, enabled: !busy) {
                                    guard !busy else { return }
                                    busy = true
                                    store.finish(tinID: tin.id)
                                    Task {
                                        try? await Task.sleep(for: .milliseconds(400))
                                        busy = false
                                    }
                                }
                            }
                            .padding(Spacing.s4)
                            .paperPlate()
                        }
                    }
                }
                .padding(Spacing.s5)
            }
            .background(DesignTokens.bg.ignoresSafeArea())
            .navigationTitle("Finish")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .frame(minHeight: Chrome.hit)
                }
            }
            .sheetEntry(settle: settle)
        }
    }
}
