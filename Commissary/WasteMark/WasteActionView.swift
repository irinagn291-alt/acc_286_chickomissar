import SwiftUI

/// Clears a tin without seating it on a cook day. Ink, not accent.
struct WasteActionView: View {
    var enabled: Bool
    var action: () -> Void

    var body: some View {
        GlassButton(title: "Waste", system: "trash", tone: .destructive, enabled: enabled, action: action)
    }
}

/// Live tins with a destructive clear. No accent on the verb.
struct WasteCoverView: View {
    var settle: Bool
    @Environment(LarderStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var busy = false
    @State private var confirm = false
    @State private var target: UUID?

    private var live: [FoldedTin] {
        store.board.pantry.stock + store.board.pantry.assigned
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s4) {
                    HeroWord(text: "CLEAR")
                    Text("Waste removes a tin without seating it on a cook day.")
                        .font(TypeFace.body)
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if live.isEmpty {
                        Text("No live tin to clear.")
                            .font(TypeFace.body)
                            .foregroundStyle(DesignTokens.ink)
                    } else {
                        ForEach(live) { tin in
                            HStack(spacing: Spacing.s3) {
                                Text(tin.tin.title)
                                    .font(TypeFace.body)
                                    .foregroundStyle(DesignTokens.ink)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Spacer(minLength: Spacing.s2)
                                Button("Waste") {
                                    target = tin.id
                                    confirm = true
                                }
                                .font(TypeFace.callout)
                                .foregroundStyle(DesignTokens.ink)
                                .frame(minWidth: Chrome.hit, minHeight: Chrome.hit)
                                .padding(.horizontal, Spacing.s3)
                                .background {
                                    RoundedRectangle(cornerRadius: Chrome.chip, style: .continuous)
                                        .fill(.regularMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: Chrome.chip, style: .continuous)
                                                .strokeBorder(DesignTokens.ink.opacity(0.35))
                                        )
                                }
                            }
                            .padding(.horizontal, Spacing.s3)
                            .paperPlate()
                        }
                    }
                }
                .padding(Spacing.s5)
            }
            .background(DesignTokens.bg.ignoresSafeArea())
            .navigationTitle("Waste")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .frame(minHeight: Chrome.hit)
                }
            }
            .confirmationDialog(
                "Waste this tin? It leaves the shelf without a cook day.",
                isPresented: $confirm,
                titleVisibility: .visible
            ) {
                Button("Waste tin", role: .destructive) {
                    if let target, !busy {
                        busy = true
                        store.waste(tinID: target)
                        busy = false
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheetEntry(settle: settle)
        }
    }
}
