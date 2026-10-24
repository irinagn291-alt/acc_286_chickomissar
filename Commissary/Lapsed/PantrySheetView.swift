import SwiftUI

/// Full shelf ledger. Past-date tins can be cleared. Package dates can move.
struct PantrySheetView: View {
    var settle: Bool
    @Environment(LarderStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var editing: FoldedTin?
    @State private var confirmCull = false
    @State private var busy = false

    private var ledger: PantryLedger { store.board.pantry }
    private var isEmpty: Bool {
        ledger.assigned.isEmpty && ledger.stock.isEmpty && ledger.lapsed.isEmpty && ledger.cleared.isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if isEmpty {
                    EmptyPlate(
                        imageName: "cms_EmptyLarderCutout",
                        word: "EMPTY",
                        detail: "The pantry is empty. Scan the first tin.",
                        actionTitle: "Close",
                        action: { dismiss() }
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.s4) {
                            HeroWord(text: "SHELF")
                            Text("Stock, seated, past date, and cleared. Numbers stay put when a name is long.")
                                .font(TypeFace.body)
                                .foregroundStyle(DesignTokens.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            if let warning = store.loadWarning {
                                NoticeBanner(message: warning, actionTitle: "Try again") {
                                    Task { await store.retryLoad() }
                                }
                            }
                            if let refusal = store.lastRefusal {
                                NoticeBanner(message: RefusalCopy.line(refusal), actionTitle: "Try again") {
                                    store.clearRefusal()
                                }
                            }
                            AssignedLedgerView(tins: ledger.assigned) { editing = $0 }
                            stockBlock
                            LapsedCullView(tins: ledger.lapsed, enabled: !busy && !ledger.lapsed.isEmpty) {
                                confirmCull = true
                            } edit: { editing = $0 }
                            ClearedLedgerView(tins: ledger.cleared)
                        }
                        .padding(Spacing.s5)
                    }
                }
            }
            .background(DesignTokens.bg.ignoresSafeArea())
            .navigationTitle("Pantry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .frame(minHeight: Chrome.hit)
                }
            }
            .sheet(item: $editing) { tin in
                PackageDateEditor(tin: tin)
            }
            .confirmationDialog(
                "Clear past-date tins? They leave the shelf.",
                isPresented: $confirmCull,
                titleVisibility: .visible
            ) {
                Button("Clear past dates", role: .destructive) {
                    busy = true
                    Task {
                        await store.cullLapsed()
                        busy = false
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheetEntry(settle: settle)
        }
    }

    private var stockBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Eyebrow(text: "ON SHELF")
            if ledger.stock.isEmpty {
                Text("No tins waiting to be seated.")
                    .font(TypeFace.body)
                    .foregroundStyle(DesignTokens.ink)
                    .padding(Spacing.s4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .paperPlate()
            } else {
                ForEach(ledger.stock) { tin in
                    Button {
                        editing = tin
                    } label: {
                        TinLadderRowView(title: tin.tin.title, daysLeft: tin.daysLeft, caption: "Edit date")
                            .paperPlate()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct AssignedLedgerView: View {
    var tins: [FoldedTin]
    var edit: (FoldedTin) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Eyebrow(text: "SEATED")
            if tins.isEmpty {
                Text("No tin is seated on a cook day.")
                    .font(TypeFace.body)
                    .foregroundStyle(DesignTokens.ink)
                    .padding(Spacing.s4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .paperPlate()
            } else {
                ForEach(tins) { tin in
                    Button {
                        edit(tin)
                    } label: {
                        TinLadderRowView(
                            title: tin.tin.title,
                            daysLeft: tin.daysLeft,
                            caption: "Seated"
                        )
                        .paperPlate()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

/// Second seated ledger so the driver can name this screen apart from the assign day picker.
struct AssignedShelfView: View {
    var tins: [FoldedTin]
    var edit: (FoldedTin) -> Void

    var body: some View {
        AssignedLedgerView(tins: tins, edit: edit)
    }
}

struct LapsedCullView: View {
    var tins: [FoldedTin]
    var enabled: Bool
    var cull: () -> Void
    var edit: (FoldedTin) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Eyebrow(text: "PAST DATE")
            if tins.isEmpty {
                Text("No past-date tins.")
                    .font(TypeFace.body)
                    .foregroundStyle(DesignTokens.ink)
                    .padding(Spacing.s4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .paperPlate()
            } else {
                ForEach(tins) { tin in
                    Button {
                        edit(tin)
                    } label: {
                        TinLadderRowView(title: tin.tin.title, daysLeft: max(0, -tin.daysLeft), caption: "days past")
                            .paperPlate()
                    }
                    .buttonStyle(.plain)
                }
                GlassButton(title: "Clear past dates", system: "archivebox", tone: .destructive, enabled: enabled, action: cull)
            }
        }
    }
}

struct ClearedLedgerView: View {
    var tins: [FoldedTin]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Eyebrow(text: "CLEARED")
            if tins.isEmpty {
                Text("Nothing cleared yet.")
                    .font(TypeFace.body)
                    .foregroundStyle(DesignTokens.ink)
                    .padding(Spacing.s4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .paperPlate()
            } else {
                ForEach(tins) { tin in
                    TinLadderRowView(title: tin.tin.title, daysLeft: max(0, tin.daysLeft), caption: "Cleared")
                        .padding(.vertical, Spacing.s2)
                        .paperPlate()
                }
            }
        }
    }
}

struct PackageDateEditor: View {
    var tin: FoldedTin
    @Environment(LarderStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var date: Date

    init(tin: FoldedTin) {
        self.tin = tin
        let calendar = Calendar.current
        let initial = CookDay.date(for: tin.tin.packageDaykey, calendar: calendar) ?? Date()
        _date = State(initialValue: initial)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s4) {
                Text(tin.tin.title)
                    .font(TypeFace.title)
                    .foregroundStyle(DesignTokens.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                DatePicker("Best before", selection: $date, displayedComponents: .date)
                    .font(TypeFace.body)
                    .datePickerStyle(.graphical)
                GlassButton(title: "Save date", system: "checkmark", tone: .live) {
                    let day = CookDay.daykey(for: Calendar.current.startOfDay(for: date), calendar: .current)
                    guard day > 0 else { return }
                    store.adjustPackage(tinID: tin.id, packageDaykey: day)
                    dismiss()
                }
                Spacer(minLength: Spacing.s4)
            }
            .padding(Spacing.s5)
            }
            .background(DesignTokens.bg.ignoresSafeArea())
            .navigationTitle("Best before")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .frame(minHeight: Chrome.hit)
                }
            }
        }
    }
}
