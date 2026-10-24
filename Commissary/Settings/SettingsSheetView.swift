import SwiftUI

/// Horizon, export, reset, source link, and contact. Goals cover lands here.
struct SettingsSheetView: View {
    var settle: Bool
    @Environment(LarderStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false
    @State private var showOnboarding = false
    @State private var busy = false

    private var markCount: Int {
        store.record.assignMarks.count
            + store.record.finishMarks.count
            + store.record.wasteMarks.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s4) {
                    HeroWord(text: "PLAN")
                    Text("Set how many cook days you plan ahead. Export or reset stays on this device.")
                        .font(TypeFace.body)
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if let warning = store.loadWarning {
                        NoticeBanner(message: warning, actionTitle: "Try again") {
                            Task { await store.retryLoad() }
                        }
                    }
                    horizon
                    tally
                    exportBlock
                    links
                    GlassButton(title: "Show introduction", system: "book", tone: .quiet) {
                        showOnboarding = true
                    }
                    GlassButton(title: "Reset all data", system: "trash", tone: .destructive, enabled: !busy) {
                        confirmReset = true
                    }
                }
                .padding(Spacing.s5)
            }
            .background(DesignTokens.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .frame(minHeight: Chrome.hit)
                }
            }
            .confirmationDialog(
                "Reset all data? Every tin and mark on this device is removed.",
                isPresented: $confirmReset,
                titleVisibility: .visible
            ) {
                Button("Reset all data", role: .destructive) {
                    busy = true
                    Task {
                        await store.resetAllData()
                        busy = false
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView(settle: false) {
                    showOnboarding = false
                }
            }
            .sheetEntry(settle: settle)
        }
    }

    private var horizon: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Eyebrow(text: "COOK DAYS AHEAD")
            HStack(spacing: Spacing.s3) {
                ForEach([3, 5, 7, 14], id: \.self) { days in
                    Button {
                        store.setCookHorizon(days)
                    } label: {
                        CountLabel(value: days)
                            .font(TypeFace.callout)
                            .foregroundStyle(DesignTokens.ink)
                            .frame(maxWidth: .infinity, minHeight: Chrome.hit)
                            .background {
                                RoundedRectangle(cornerRadius: Chrome.chip, style: .continuous)
                                    .fill(.thinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Chrome.chip, style: .continuous)
                                            .fill(store.record.cookHorizonDays == days ? DesignTokens.accent.opacity(0.22) : Color.clear)
                                    )
                            }
                            .clipShape(RoundedRectangle(cornerRadius: Chrome.chip, style: .continuous))
                    }
                    .buttonStyle(CardPressStyle())
                    .accessibilityLabel("Plan \(days) days")
                }
            }
        }
        .padding(Spacing.s4)
        .paperPlate()
    }

    private var tally: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.s1) {
                Eyebrow(text: "MARKS ON FILE")
                CountLabel(value: markCount)
                    .font(TypeFace.title)
                    .foregroundStyle(DesignTokens.ink)
                    .animation(Motion.spring, value: markCount)
            }
            Spacer(minLength: Spacing.s4)
            Image("cms_TicketStampEmblem")
                .resizable()
                .scaledToFit()
                .frame(width: Spacing.s12, height: Spacing.s12)
                .accessibilityHidden(true)
        }
        .padding(Spacing.s4)
        .paperPlate()
    }

    private var exportBlock: some View {
        ShareLink(
            item: CSVExporter.history(store.record),
            preview: SharePreview("Pantry history")
        ) {
            Label("Export history", systemImage: "square.and.arrow.up")
                .font(TypeFace.callout)
                .foregroundStyle(DesignTokens.ink)
                .frame(maxWidth: .infinity, minHeight: Chrome.hit)
                .padding(.horizontal, Spacing.s4)
                .background {
                    RoundedRectangle(cornerRadius: Chrome.card, style: .continuous)
                        .fill(.regularMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: Chrome.card, style: .continuous)
                                .fill(DesignTokens.accent.opacity(0.22))
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: Chrome.card, style: .continuous))
        }
        .buttonStyle(CardPressStyle())
    }

    private var links: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            if let facts = URL(string: SupportLinks.openFoodFactsURL) {
                Link(destination: facts) {
                    linkRow("Open Food Facts", system: "arrow.up.right")
                }
            }
            if let contact = URL(string: SupportLinks.contactURL) {
                Link(destination: contact) {
                    linkRow("Contact", system: "envelope")
                }
            }
        }
    }

    private func linkRow(_ title: String, system: String) -> some View {
        Label(title, systemImage: system)
            .font(TypeFace.callout)
            .foregroundStyle(DesignTokens.ink)
            .frame(maxWidth: .infinity, minHeight: Chrome.hit, alignment: .leading)
            .padding(.horizontal, Spacing.s4)
            .paperPlate()
    }
}
