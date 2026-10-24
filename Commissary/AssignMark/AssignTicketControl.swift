import SwiftUI

/// Day picker for the soonest shelf tin. Assign commits on release of a day button.
struct AssignDayView: View {
    var settle: Bool
    @Environment(LarderStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var busy = false

    private var days: [Int] {
        let span = min(14, max(1, store.record.cookHorizonDays))
        return (0..<span).compactMap { offset in
            CookDay.adding(days: offset, to: store.todayKey, calendar: .current)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s4) {
                    HeroWord(text: "DAY")
                    if let lead = store.board.ladder.first {
                        Text(lead.title)
                            .font(TypeFace.title)
                            .foregroundStyle(DesignTokens.ink)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Pick the cook day. Today stays the open row until you assign.")
                            .font(TypeFace.body)
                            .foregroundStyle(DesignTokens.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        ForEach(days, id: \.self) { day in
                            Button {
                                guard !busy else { return }
                                busy = true
                                store.assign(tinID: lead.id, cookDaykey: day)
                                Task {
                                    try? await Task.sleep(for: .milliseconds(400))
                                    busy = false
                                }
                            } label: {
                                HStack {
                                    DayNameLabel(daykey: day)
                                        .font(TypeFace.callout)
                                        .foregroundStyle(DesignTokens.ink)
                                    Spacer(minLength: Spacing.s2)
                                    DayKeyLabel(daykey: day)
                                        .font(TypeFace.caption)
                                        .foregroundStyle(DesignTokens.muted)
                                        .layoutPriority(1)
                                }
                                .padding(.horizontal, Spacing.s4)
                                .frame(maxWidth: .infinity, minHeight: Chrome.hit)
                                .background {
                                    RoundedRectangle(cornerRadius: Chrome.card, style: .continuous)
                                        .fill(.regularMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: Chrome.card, style: .continuous)
                                                .fill(day == store.todayKey ? DesignTokens.accent.opacity(0.22) : DesignTokens.accent.opacity(0))
                                        )
                                }
                                .clipShape(RoundedRectangle(cornerRadius: Chrome.card, style: .continuous))
                            }
                            .buttonStyle(CardPressStyle())
                            .disabled(busy)
                            .opacity(busy ? 0.42 : 1)
                        }
                    } else {
                        Text("No tin is waiting. Scan one, then assign it.")
                            .font(TypeFace.body)
                            .foregroundStyle(DesignTokens.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let refusal = store.lastRefusal {
                        NoticeBanner(message: RefusalCopy.line(refusal), actionTitle: "Try again") {
                            store.clearRefusal()
                        }
                    }
                }
                .padding(Spacing.s5)
            }
            .background(DesignTokens.bg.ignoresSafeArea())
            .navigationTitle("Assign day")
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
