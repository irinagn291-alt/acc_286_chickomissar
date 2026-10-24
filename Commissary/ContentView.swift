import SwiftUI
import UIKit

/// Root frame. Reads `ReviewLaunch.screen` once, after onboarding is done.
struct ContentView: View {
    @Environment(LarderStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var booted = false
    @State private var showSpin = false
    @State private var showOnboarding = false
    @State private var reviewDesk: Desk?
    @State private var didRouteReview = false

    var body: some View {
        ZStack {
            UseSoonBoardView(settle: reviewDesk != nil)
                .opacity(booted ? 1 : 0)
            if !booted {
                HomeSkeleton()
                    .redacted(reason: .placeholder)
                    .allowsHitTesting(false)
            }
            if showSpin {
                ProgressView("Loading shelf")
                    .font(TypeFace.body)
                    .padding(Spacing.s4)
                    .paperPlate()
            }
        }
        .background(DesignTokens.bg.ignoresSafeArea())
        .fullScreenCover(item: $reviewDesk) { desk in
            DeskRouter(desk: desk, settle: true)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(settle: true) {
                showOnboarding = false
                routeReviewIfNeeded()
            }
        }
        .task { await boot() }
        .onChange(of: store.commitTick) { _, tick in
            guard tick > 0 else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.noteClock()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            store.noteClock()
        }
    }

    private func boot() async {
        let spin = Task {
            try? await Task.sleep(for: .milliseconds(150))
            if !booted { showSpin = true }
        }
        await store.load()
        spin.cancel()
        showSpin = false
        booted = true
        if store.record.onboardingComplete {
            routeReviewIfNeeded()
        } else {
            showOnboarding = true
        }
    }

    private func routeReviewIfNeeded() {
        guard !didRouteReview else { return }
        didRouteReview = true
        reviewDesk = Desk.cover(for: ReviewLaunch.screen)
    }
}

enum Desk: String, Identifiable {
    case pantry
    case scan
    case settings
    case cookday
    case stock
    case assign
    case finish
    case waste

    var id: String { rawValue }

    static func cover(for key: String?) -> Desk? {
        switch key {
        case "log", "pantry":
            return .pantry
        case "goals", "settings":
            return .settings
        case "scan":
            return .scan
        case "cookday":
            return .cookday
        case "stock":
            return .stock
        case "assign":
            return .assign
        case "finish":
            return .finish
        case "waste":
            return .waste
        case "today", "usesoon", "tabview", nil:
            return nil
        default:
            return nil
        }
    }
}

/// Named for the spec's rejected chrome. This app does not present a tab bar.
struct TabViewNotice: View {
    var body: some View {
        Text("The shelf stays on screen.")
            .font(TypeFace.body)
            .foregroundStyle(DesignTokens.ink)
    }
}

struct DeskRouter: View {
    var desk: Desk
    var settle: Bool

    var body: some View {
        switch desk {
        case .pantry:
            PantrySheetView(settle: settle)
        case .scan:
            ScanSheetView(settle: settle)
        case .settings:
            SettingsSheetView(settle: settle)
        case .cookday:
            CookDayFeatureView(settle: settle)
        case .stock:
            StockLadderView(settle: settle)
        case .assign:
            AssignDayView(settle: settle)
        case .finish:
            FinishCoverView(settle: settle)
        case .waste:
            WasteCoverView(settle: settle)
        }
    }
}

/// Reserved home frame so the seeded board does not jump in from a blank page.
struct HomeSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            HeroWord(text: "SOON")
            Text("Assign the next tin to today.")
                .font(TypeFace.body)
            RoundedRectangle(cornerRadius: Chrome.card, style: .continuous)
                .fill(DesignTokens.surface)
                .frame(maxWidth: .infinity)
                .frame(height: Spacing.s12 * 4)
            RoundedRectangle(cornerRadius: Chrome.card, style: .continuous)
                .fill(DesignTokens.surface)
                .frame(height: Chrome.hit)
            RoundedRectangle(cornerRadius: Chrome.card, style: .continuous)
                .fill(DesignTokens.surface)
                .frame(height: Chrome.hit)
            RoundedRectangle(cornerRadius: Chrome.card, style: .continuous)
                .fill(DesignTokens.surface)
                .frame(height: Chrome.hit)
            Spacer(minLength: Spacing.s4)
        }
        .padding(Spacing.s5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignTokens.bg)
    }
}
