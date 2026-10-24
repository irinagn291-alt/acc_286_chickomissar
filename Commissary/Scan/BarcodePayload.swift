import Foundation

/// Digit runs pulled from a camera payload, a typed code, or a QR URL.
/// Keeps runs of 8 to 14 digits. A 12-digit UPC-A is also offered with a leading 0.
enum BarcodePayload {
    static func candidates(in raw: String) -> [String] {
        var seen: Set<String> = []
        var ordered: [String] = []
        func append(_ code: String) {
            guard seen.insert(code).inserted else { return }
            ordered.append(code)
        }
        var run = ""
        func flush() {
            if (8...14).contains(run.count) {
                append(run)
                if run.count == 12 {
                    append("0" + run)
                }
            }
            run = ""
        }
        for character in raw {
            if character.isNumber {
                run.append(character)
            } else {
                flush()
            }
        }
        flush()
        return ordered
    }
}
