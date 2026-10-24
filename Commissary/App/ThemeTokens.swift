import SwiftUI

/// Spacing, type, radius, and motion. Colours stay on `DesignTokens`.
/// Layout gaps are multiples of 4 from the allowed set. Radius is the 18 / 8 kit.

enum Spacing {
    static let s1: CGFloat = 4
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12
    static let s4: CGFloat = 16
    static let s5: CGFloat = 20
    static let s6: CGFloat = 24
    static let s8: CGFloat = 32
    static let s10: CGFloat = 40
    static let s12: CGFloat = 48
}

enum Chrome {
    static let card: CGFloat = 18
    static let chip: CGFloat = 8
    static let hit: CGFloat = 44
}

enum Motion {
    static let pressScale: CGFloat = 0.97
    static let sheetScale: CGFloat = 0.96
    static let press = Animation.easeOut(duration: 0.16)
    static let sheet = Animation.easeOut(duration: 0.17)
    static let spring = Animation.spring(duration: 0.35, bounce: 0.18)
}

/// Six Verdana steps. Body is 17pt. Display is the oversized single word.
enum TypeFace {
    static let display = Font.custom(DesignTokens.fontFamily, size: 64, relativeTo: .largeTitle).weight(.bold)
    static let title = Font.custom(DesignTokens.fontFamily, size: 28, relativeTo: .title).weight(.bold)
    static let body = Font.custom(DesignTokens.fontFamily, size: 17, relativeTo: .body)
    static let callout = Font.custom(DesignTokens.fontFamily, size: 15, relativeTo: .callout).weight(.bold)
    static let caption = Font.custom(DesignTokens.fontFamily, size: 13, relativeTo: .subheadline)
    static let micro = Font.custom(DesignTokens.fontFamily, size: 11, relativeTo: .caption2)
}

struct CountLabel: View {
    var value: Int

    var body: some View {
        Text(Double(value), format: .number.precision(.fractionLength(0)))
            .contentTransition(.numericText(value: Double(value)))
    }
}

struct DayKeyLabel: View {
    var daykey: Int

    var body: some View {
        Text(Double(daykey), format: .number.grouping(.never).precision(.fractionLength(0)))
    }
}

struct DayNameLabel: View {
    var daykey: Int
    var calendar: Calendar = .current

    var body: some View {
        if daykey == CookDay.daykey(for: Date(), calendar: calendar) {
            Text("Today")
        } else if let tomorrow = CookDay.adding(days: 1, to: CookDay.daykey(for: Date(), calendar: calendar), calendar: calendar),
                  daykey == tomorrow {
            Text("Tomorrow")
        } else if let date = CookDay.date(for: daykey, calendar: calendar) {
            Text(date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
        } else {
            Text("unknown")
        }
    }
}

struct HeroWord: View {
    var text: String
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(text)
                .font(typeSize.isAccessibilitySize ? TypeFace.title : TypeFace.display)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: true, vertical: true)
                .accessibilityAddTraits(.isHeader)
        }
    }
}

struct Eyebrow: View {
    var text: String

    var body: some View {
        Text(text)
            .font(TypeFace.micro)
            .tracking(1.4)
            .foregroundStyle(DesignTokens.muted)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct GlassButton: View {
    enum Tone { case live, quiet, destructive }

    var title: String
    var system: String
    var tone: Tone = .live
    var enabled: Bool = true
    var action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduce

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: system)
                .font(TypeFace.callout)
                .foregroundStyle(DesignTokens.ink)
                .frame(maxWidth: .infinity, minHeight: Chrome.hit)
                .padding(.horizontal, Spacing.s4)
                .padding(.vertical, Spacing.s2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .buttonStyle(GlassPressStyle(tone: tone, reduce: reduce))
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.42)
        .accessibilityHint(enabled ? "" : "Unavailable")
    }
}

struct GlassPressStyle: ButtonStyle {
    var tone: GlassButton.Tone
    var reduce: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background { plate }
            .clipShape(RoundedRectangle(cornerRadius: Chrome.card, style: .continuous))
            .scaleEffect(reduce ? 1 : (configuration.isPressed ? Motion.pressScale : 1))
            .opacity(reduce && configuration.isPressed ? 0.72 : 1)
            .animation(reduce ? .linear(duration: 0.16) : Motion.press, value: configuration.isPressed)
            .contentShape(RoundedRectangle(cornerRadius: Chrome.card, style: .continuous))
    }

    @ViewBuilder
    private var plate: some View {
        let shape = RoundedRectangle(cornerRadius: Chrome.card, style: .continuous)
        switch tone {
        case .live:
            shape.fill(.regularMaterial)
                .overlay(shape.fill(DesignTokens.accent.opacity(0.22)))
        case .quiet:
            shape.fill(.thinMaterial)
        case .destructive:
            shape.fill(.regularMaterial)
                .overlay(shape.strokeBorder(DesignTokens.ink.opacity(0.35)))
        }
    }
}

struct CardPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduce

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduce ? 1 : (configuration.isPressed ? Motion.pressScale : 1))
            .opacity(reduce && configuration.isPressed ? 0.72 : 1)
            .animation(reduce ? .linear(duration: 0.16) : Motion.press, value: configuration.isPressed)
            .contentShape(RoundedRectangle(cornerRadius: Chrome.card, style: .continuous))
    }
}

struct PaperPlate: ViewModifier {
    var chip: Bool = false

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: chip ? Chrome.chip : Chrome.card, style: .continuous)
                    .fill(.regularMaterial)
            }
            .clipShape(RoundedRectangle(cornerRadius: chip ? Chrome.chip : Chrome.card, style: .continuous))
    }
}

extension View {
    func paperPlate(chip: Bool = false) -> some View {
        modifier(PaperPlate(chip: chip))
    }

    func sheetEntry(settle: Bool) -> some View {
        modifier(SheetEntry(settle: settle))
    }
}

struct SheetEntry: ViewModifier {
    var settle: Bool
    @Environment(\.accessibilityReduceMotion) private var reduce
    @State private var shown: Bool

    init(settle: Bool) {
        self.settle = settle
        _shown = State(initialValue: settle)
    }

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .scaleEffect(reduce || settle ? 1 : (shown ? 1 : Motion.sheetScale))
            .onAppear {
                if reduce || settle {
                    shown = true
                } else {
                    withAnimation(Motion.sheet) { shown = true }
                }
            }
    }
}

struct EmptyPlate: View {
    var imageName: String
    var word: String
    var detail: String
    var actionTitle: String
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, Spacing.s8)
                .accessibilityLabel(word)
            HeroWord(text: word)
            Text(detail)
                .font(TypeFace.body)
                .foregroundStyle(DesignTokens.ink)
                .lineSpacing(Spacing.s1)
                .fixedSize(horizontal: false, vertical: true)
            GlassButton(title: actionTitle, system: "barcode.viewfinder", tone: .live, action: action)
        }
        .padding(Spacing.s5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(DesignTokens.bg)
    }
}

enum RefusalCopy {
    static func line(_ refusal: FoldRefusal) -> String {
        switch refusal {
        case .blankBoard:
            return "Shelf is empty. Scan a tin first."
        case .missingTin:
            return "That tin is missing. Try again."
        case .invalidScan:
            return "Scan failed. Try again."
        case .earlyFinish:
            return "Finish refused. Assign a cook day first."
        case .duplicateAssign:
            return "Assign refused. This tin already has a cook day."
        case .notLive:
            return "That tin is not live. Pick another."
        case .nothingToUndo:
            return "Undo refused. Nothing to peel."
        case .nothingToCull:
            return "Clear refused. No past-date tins."
        }
    }
}

struct NoticeBanner: View {
    var message: String
    var actionTitle: String
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Label(message, systemImage: "exclamationmark.circle")
                .font(TypeFace.caption)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Button(actionTitle, action: action)
                .font(TypeFace.callout)
                .foregroundStyle(DesignTokens.ink)
                .frame(minHeight: Chrome.hit)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .padding(Spacing.s4)
        .paperPlate()
        .accessibilityElement(children: .contain)
    }
}
