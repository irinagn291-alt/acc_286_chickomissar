import SwiftUI

/// SPEC section 7. The only place these hex values live — reach colours
/// and the font family through here. Keep this file and its values.
enum DesignTokens {
    /// #F7F1DE
    static let bg = Color(red: 0.968627, green: 0.945098, blue: 0.870588)
    static let bgHex = "#F7F1DE"
    /// #FAF7EC
    static let surface = Color(red: 0.980392, green: 0.968627, blue: 0.925490)
    static let surfaceHex = "#FAF7EC"
    /// #15140F
    static let ink = Color(red: 0.082353, green: 0.078431, blue: 0.058824)
    static let inkHex = "#15140F"
    /// #E94F37
    static let accent = Color(red: 0.913725, green: 0.309804, blue: 0.215686)
    static let accentHex = "#E94F37"
    /// #68655B
    static let muted = Color(red: 0.407843, green: 0.396078, blue: 0.356863)
    static let mutedHex = "#68655B"
    static let fontFamily = "Verdana"
}
