import SwiftUI

/// Three pages. Skip and the last continue both mark onboarding complete.
struct OnboardingView: View {
    var settle: Bool
    var done: () -> Void
    @Environment(LarderStore.self) private var store
    @State private var page = 0

    private let pages: [(String, String, String)] = [
        ("cms_Onboarding1", "SHELF", "Scan a tin and keep the best-before date."),
        ("cms_Onboarding2", "ASSIGN", "Seat it on a cook day, then finish it that day."),
        ("cms_Onboarding3", "KEEP", "Past dates wait in the pantry until you clear them.")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            HStack {
                Text("Page")
                    .font(TypeFace.caption)
                    .foregroundStyle(DesignTokens.muted)
                CountLabel(value: page + 1)
                    .font(TypeFace.caption)
                    .foregroundStyle(DesignTokens.muted)
                Text("of")
                    .font(TypeFace.caption)
                    .foregroundStyle(DesignTokens.muted)
                CountLabel(value: pages.count)
                    .font(TypeFace.caption)
                    .foregroundStyle(DesignTokens.muted)
                Spacer(minLength: Spacing.s2)
                Button("Skip") { finish() }
                    .font(TypeFace.callout)
                    .foregroundStyle(DesignTokens.ink)
                    .frame(minHeight: Chrome.hit)
            }
            Image(pages[page].0)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel(pages[page].1)
            HeroWord(text: pages[page].1)
            Text(pages[page].2)
                .font(TypeFace.body)
                .foregroundStyle(DesignTokens.ink)
                .lineSpacing(Spacing.s1)
                .fixedSize(horizontal: false, vertical: true)
            GlassButton(
                title: page == pages.count - 1 ? "Start" : "Next",
                system: "arrow.right",
                tone: .live,
                action: advance
            )
        }
        .padding(Spacing.s5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(DesignTokens.bg.ignoresSafeArea())
        .sheetEntry(settle: settle)
    }

    private func advance() {
        if page == pages.count - 1 {
            finish()
        } else {
            page += 1
        }
    }

    private func finish() {
        store.completeOnboarding()
        done()
    }
}
