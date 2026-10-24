import SwiftUI

/// Full-page empty shelf. The action sits on the bottom edge.
struct BlankBoardView: View {
    var scan: () -> Void

    var body: some View {
        EmptyPlate(
            imageName: "cms_EmptyHome",
            word: "EMPTY",
            detail: "The pantry is empty. Scan the first tin.",
            actionTitle: "Scan a tin",
            action: scan
        )
    }
}
