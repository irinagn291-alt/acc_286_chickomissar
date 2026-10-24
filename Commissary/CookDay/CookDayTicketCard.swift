import SwiftUI

/// Twist screen. Assign, then finish, told as its own page. Stock controls only.
struct CookDayFeatureView: View {
    var settle: Bool
    @Environment(LarderStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var busy = false

    private var lead: LadderRung? { store.board.ladder.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s4) {
                    HeroWord(text: "SEAT")
                    Image("cms_TwistHero")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .padding(.horizontal, Spacing.s6)
                        .accessibilityLabel("Folded tin and a day stamp")
                    Text("Assign a tin to a cook day. Finish it on that day.")
                        .font(TypeFace.body)
                        .foregroundStyle(DesignTokens.ink)
                        .lineSpacing(Spacing.s1)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Finish waits until the tin is seated. A second assign is refused.")
                        .font(TypeFace.caption)
                        .foregroundStyle(DesignTokens.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    if let lead {
                        VStack(alignment: .leading, spacing: Spacing.s2) {
                            Text(lead.title)
                                .font(TypeFace.title)
                                .foregroundStyle(DesignTokens.ink)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            HStack {
                                Text("days left")
                                    .font(TypeFace.caption)
                                    .foregroundStyle(DesignTokens.muted)
                                Spacer(minLength: Spacing.s2)
                                CountLabel(value: lead.daysLeft)
                                    .font(TypeFace.title)
                                    .foregroundStyle(DesignTokens.ink)
                                    .layoutPriority(1)
                            }
                        }
                        .padding(Spacing.s4)
                        .paperPlate()
                        GlassButton(title: "Assign to today", system: "calendar", tone: .live, enabled: !busy) {
                            guard !busy else { return }
                            busy = true
                            store.assign(tinID: lead.id, cookDaykey: store.todayKey)
                            Task {
                                try? await Task.sleep(for: .milliseconds(400))
                                busy = false
                            }
                        }
                    } else {
                        Text("No tin is waiting on the shelf.")
                            .font(TypeFace.body)
                            .foregroundStyle(DesignTokens.ink)
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
            .navigationTitle("Cook day")
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
