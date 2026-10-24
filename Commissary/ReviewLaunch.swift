import Foundation
#if os(iOS)
import UIKit
#endif

/// Live screenshot driver: `-ReviewScreen today|log|goals` (plus extra cover keys).
/// Read `ReviewLaunch.screen` once, after onboarding is done, and open that
/// screen. Keep this file; the navigation it drives belongs to the app.
enum ReviewLaunch {
    static let argument = "-ReviewScreen"

    /// The key after `-ReviewScreen`, or nil on a normal launch.
    static var screen: String? {
        screen(in: ProcessInfo.processInfo.arguments)
    }

    /// Parses the launch argument list. The app reads `screen` once, after onboarding.
    static func screen(in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: argument), index + 1 < arguments.count else {
            return nil
        }
        return arguments[index + 1]
    }

    /// Cover launches pass `-ReviewScreen`. Freeze UIKit transitions so the
    /// screenshot is the destination, not a mid-animation. No-op on watchOS.
    @MainActor
    static func disableAnimationsIfNeeded() {
        #if os(iOS)
        if ProcessInfo.processInfo.arguments.contains(argument) {
            UIView.setAnimationsEnabled(false)
        }
        #endif
    }
}
