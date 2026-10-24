import SwiftUI

/// Quiet shelf row. Numbers keep their width. Names truncate.
struct TinLadderRowView: View {
    var title: String
    var daysLeft: Int
    var caption: String

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.s3) {
            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(title)
                    .font(TypeFace.body)
                    .foregroundStyle(DesignTokens.ink)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(caption)
                    .font(TypeFace.caption)
                    .foregroundStyle(DesignTokens.muted)
                    .lineLimit(1)
            }
            Spacer(minLength: Spacing.s2)
            CountLabel(value: daysLeft)
                .font(TypeFace.callout)
                .foregroundStyle(DesignTokens.ink)
                .layoutPriority(1)
        }
        .padding(.horizontal, Spacing.s4)
        .frame(minHeight: Chrome.hit)
    }
}

/// Shelf-first page. The number column is the dominant element.
struct StockLadderView: View {
    var settle: Bool
    @Environment(LarderStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var busy = false

    var body: some View {
        NavigationStack {
            Group {
                if store.board.ladder.isEmpty {
                    BlankBoardView { dismiss() }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.s3) {
                            HeroWord(text: "LEFT")
                            Text("Soonest best-before sits at the top. Tap a row to seat it today.")
                                .font(TypeFace.body)
                                .foregroundStyle(DesignTokens.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            ForEach(store.board.ladder) { rung in
                                Button {
                                    guard !busy else { return }
                                    busy = true
                                    store.assign(tinID: rung.id, cookDaykey: store.todayKey)
                                    Task {
                                        try? await Task.sleep(for: .milliseconds(400))
                                        busy = false
                                    }
                                } label: {
                                    HStack(alignment: .center, spacing: Spacing.s4) {
                                        CountLabel(value: rung.daysLeft)
                                            .font(TypeFace.display)
                                            .foregroundStyle(DesignTokens.ink)
                                            .frame(minWidth: Chrome.hit, alignment: .leading)
                                            .layoutPriority(1)
                                        VStack(alignment: .leading, spacing: Spacing.s1) {
                                            Text(rung.title)
                                                .font(TypeFace.body)
                                                .foregroundStyle(DesignTokens.ink)
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                            DayKeyLabel(daykey: rung.packageDaykey)
                                                .font(TypeFace.caption)
                                                .foregroundStyle(DesignTokens.muted)
                                        }
                                    }
                                    .padding(Spacing.s3)
                                    .frame(maxWidth: .infinity, minHeight: Chrome.hit, alignment: .leading)
                                    .paperPlate()
                                }
                                .buttonStyle(CardPressStyle())
                                .disabled(busy)
                            }
                        }
                        .padding(Spacing.s5)
                    }
                }
            }
            .background(DesignTokens.bg.ignoresSafeArea())
            .navigationTitle("On shelf")
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
