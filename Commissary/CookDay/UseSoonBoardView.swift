import SwiftUI

/// Home. The cook-day board stays on screen. Pantry and scan arrive as sheets.
/// The paper-grain shader is the one custom surface, and it wraps only this hero card.
struct UseSoonBoardView: View {
    var settle: Bool
    @Environment(LarderStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduce
    @State private var userDesk: Desk?
    @State private var busy = false
    @State private var wasteID: UUID?
    @State private var confirmWaste = false
    @GestureState private var lift: ShelfLift?

    private var board: CookDayBoard { store.board }
    private var lead: LadderRung? { board.ladder.first }
    private var rest: [LadderRung] { Array(board.ladder.dropFirst()) }
    private var laterTickets: [CookDayTicket] {
        board.tickets.filter { $0.daykey != store.todayKey && !$0.tins.isEmpty }
    }
    private var todayTins: [FoldedTin] {
        board.tickets.first { $0.daykey == store.todayKey }?.tins ?? []
    }

    var body: some View {
        NavigationStack {
            Group {
                if board.isBlank {
                    BlankBoardView { userDesk = .scan }
                } else {
                    loaded
                }
            }
            .background(DesignTokens.bg.ignoresSafeArea())
            .navigationTitle("Use soon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .sheet(item: $userDesk) { desk in
                DeskRouter(desk: desk, settle: false)
            }
            .confirmationDialog(
                wasteTitle,
                isPresented: $confirmWaste,
                titleVisibility: .visible
            ) {
                Button("Waste tin", role: .destructive) {
                    if let wasteID { commit { store.waste(tinID: wasteID) } }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var loaded: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s4) {
                HeroWord(text: "SOON")
                Text(leadPrompt)
                    .font(TypeFace.body)
                    .foregroundStyle(DesignTokens.ink)
                    .lineSpacing(Spacing.s1)
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
                if let lead {
                    featured(lead)
                    WasteActionView(enabled: !busy) {
                        wasteID = lead.id
                        confirmWaste = true
                    }
                } else if let tin = todayTins.first {
                    finishHero(tin)
                }
                if !todayTins.isEmpty, lead != nil {
                    seatedList(todayTins, eyebrow: "ON TODAY")
                } else if todayTins.count > 1, lead == nil {
                    seatedList(Array(todayTins.dropFirst()), eyebrow: "ALSO TODAY")
                }
                if !laterTickets.isEmpty {
                    seatedBlock
                }
                shelfBlock
                tallyStrip
            }
            .padding(.horizontal, Spacing.s5)
            .padding(.top, Spacing.s4)
            .padding(.bottom, Spacing.s8)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var leadPrompt: String {
        if let lead {
            return "Assign \(lead.title) to today. It expires soon."
        }
        return "Finish the tin seated on today."
    }

    private func featured(_ rung: LadderRung) -> some View {
        PaperBoardPlate {
            Button {
                commit { store.assign(tinID: rung.id, cookDaykey: store.todayKey) }
            } label: {
                VStack(alignment: .leading, spacing: Spacing.s3) {
                    HStack(alignment: .top, spacing: Spacing.s3) {
                        VStack(alignment: .leading, spacing: Spacing.s2) {
                            Eyebrow(text: "TODAY IS OPEN")
                            Text(rung.title)
                                .font(TypeFace.title)
                                .foregroundStyle(DesignTokens.ink)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            DayNameLabel(daykey: rung.packageDaykey)
                                .font(TypeFace.caption)
                                .foregroundStyle(DesignTokens.muted)
                        }
                        Spacer(minLength: Spacing.s2)
                        VStack(alignment: .trailing, spacing: Spacing.s1) {
                            CountLabel(value: rung.daysLeft)
                                .font(TypeFace.title)
                                .foregroundStyle(DesignTokens.ink)
                                .animation(Motion.spring, value: rung.daysLeft)
                            Text("days left")
                                .font(TypeFace.micro)
                                .foregroundStyle(DesignTokens.muted)
                        }
                        .layoutPriority(1)
                        Image("cms_TicketStampEmblem")
                            .resizable()
                            .scaledToFit()
                            .frame(width: Spacing.s12, height: Spacing.s12)
                            .rotationEffect(.degrees(reduce ? 0 : -8))
                            .accessibilityHidden(true)
                    }
                    Text(lift == nil ? "Assign to today" : "Release to seat")
                        .font(TypeFace.callout)
                        .foregroundStyle(DesignTokens.ink)
                        .frame(maxWidth: .infinity, minHeight: Chrome.hit)
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
                .padding(Spacing.s4)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(CardPressStyle())
            .disabled(busy)
            .opacity(busy ? 0.42 : 1)
            .overlay {
                RoundedRectangle(cornerRadius: Chrome.card, style: .continuous)
                    .strokeBorder(DesignTokens.accent.opacity(lifting ? 1 : 0.28))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Assign \(rung.title) to today")
        .accessibilityHint("Drag a shelf row upward, or press this card")
    }

    private var lifting: Bool {
        guard let lift else { return false }
        return lift.dy < -Spacing.s3
    }

    private func finishHero(_ tin: FoldedTin) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Eyebrow(text: "READY TO FINISH")
            Text(tin.tin.title)
                .font(TypeFace.title)
                .foregroundStyle(DesignTokens.ink)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            CountLabel(value: tin.daysLeft)
                .font(TypeFace.title)
                .foregroundStyle(DesignTokens.ink)
            GlassButton(title: "Finish \(tin.tin.title)", system: "checkmark", tone: .live, enabled: !busy) {
                commit { store.finish(tinID: tin.id) }
            }
        }
        .padding(Spacing.s4)
        .paperPlate()
    }

    private func seatedList(_ tins: [FoldedTin], eyebrow: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Eyebrow(text: eyebrow)
            ForEach(tins) { tin in
                seatedRow(tin, daykey: tin.cookDaykey ?? store.todayKey)
            }
        }
    }

    private var seatedBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Eyebrow(text: "SEATED")
            ForEach(laterTickets) { ticket in
                ForEach(ticket.tins) { tin in
                    seatedRow(tin, daykey: ticket.daykey)
                }
            }
        }
    }

    private func seatedRow(_ tin: FoldedTin, daykey: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s2) {
                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Text(tin.tin.title)
                        .font(TypeFace.body)
                        .foregroundStyle(DesignTokens.ink)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    DayNameLabel(daykey: daykey)
                        .font(TypeFace.caption)
                        .foregroundStyle(DesignTokens.muted)
                }
                Spacer(minLength: Spacing.s2)
                CountLabel(value: tin.daysLeft)
                    .font(TypeFace.callout)
                    .foregroundStyle(DesignTokens.ink)
                    .layoutPriority(1)
            }
            FinishActionView(title: tin.tin.title, enabled: !busy) {
                commit { store.finish(tinID: tin.id) }
            }
            WasteActionView(enabled: !busy) {
                wasteID = tin.id
                confirmWaste = true
            }
        }
        .padding(Spacing.s3)
        .paperPlate()
    }

    private var shelfBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Eyebrow(text: "ON SHELF")
            if rest.isEmpty {
                Text("No other tins waiting.")
                    .font(TypeFace.body)
                    .foregroundStyle(DesignTokens.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.s4)
                    .paperPlate()
            } else {
                ForEach(rest) { rung in
                    shelfRow(rung)
                }
            }
        }
    }

    private func shelfRow(_ rung: LadderRung) -> some View {
        let active = lift?.id == rung.id
        return Button {
            commit { store.assign(tinID: rung.id, cookDaykey: store.todayKey) }
        } label: {
            HStack(alignment: .center, spacing: Spacing.s3) {
                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Text(rung.title)
                        .font(TypeFace.body)
                        .foregroundStyle(DesignTokens.ink)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text("Assign")
                        .font(TypeFace.caption)
                        .foregroundStyle(DesignTokens.muted)
                }
                Spacer(minLength: Spacing.s2)
                VStack(alignment: .trailing, spacing: Spacing.s1) {
                    CountLabel(value: rung.daysLeft)
                        .font(TypeFace.callout)
                        .foregroundStyle(DesignTokens.ink)
                    Text("days")
                        .font(TypeFace.micro)
                        .foregroundStyle(DesignTokens.muted)
                }
                .layoutPriority(1)
            }
            .padding(.horizontal, Spacing.s4)
            .padding(.vertical, Spacing.s2)
            .frame(minHeight: Chrome.hit)
            .paperPlate()
            .offset(y: rowOffset(active: active))
            .opacity(reduce && active ? 0.72 : 1)
        }
        .buttonStyle(.plain)
        .disabled(busy)
        .simultaneousGesture(drag(for: rung.id))
        .accessibilityLabel("Assign \(rung.title)")
        .accessibilityHint("Drag up to seat on today")
    }

    private func rowOffset(active: Bool) -> CGFloat {
        guard active, let lift, !reduce else { return 0 }
        return lift.dy
    }

    private func drag(for id: UUID) -> some Gesture {
        DragGesture(minimumDistance: Spacing.s2)
            .updating($lift) { value, state, _ in
                state = ShelfLift(id: id, dy: value.translation.height, dx: value.translation.width)
            }
            .onEnded { value in
                let upward = value.translation.height < -Spacing.s10
                let mostlyUp = abs(value.translation.height) > abs(value.translation.width)
                if upward && mostlyUp {
                    commit { store.assign(tinID: id, cookDaykey: store.todayKey) }
                }
            }
    }

    private var tallyStrip: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s4) {
            VStack(alignment: .leading, spacing: Spacing.s1) {
                Eyebrow(text: "SEATED TODAY")
                CountLabel(value: board.assignedTally)
                    .font(TypeFace.title)
                    .foregroundStyle(DesignTokens.ink)
                    .animation(Motion.spring, value: board.assignedTally)
            }
            Spacer(minLength: Spacing.s4)
            VStack(alignment: .trailing, spacing: Spacing.s1) {
                Eyebrow(text: "SOONEST")
                if let days = board.featuredDaysLeft {
                    CountLabel(value: days)
                        .font(TypeFace.title)
                        .foregroundStyle(DesignTokens.ink)
                        .animation(Motion.spring, value: days)
                } else {
                    Text("unknown")
                        .font(TypeFace.title)
                        .foregroundStyle(DesignTokens.ink)
                }
            }
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paperPlate()
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            UndoPeelView(enabled: canUndo && !busy) {
                commit { store.undo() }
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: Spacing.s2) {
                iconButton("barcode.viewfinder", label: "Scan a tin") { userDesk = .scan }
                iconButton("cabinet", label: "Pantry") { userDesk = .pantry }
                iconButton("gearshape", label: "Settings") { userDesk = .settings }
            }
        }
    }

    private func iconButton(_ system: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(TypeFace.callout)
                .foregroundStyle(DesignTokens.ink)
                .frame(width: Chrome.hit, height: Chrome.hit)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
    }

    private var canUndo: Bool {
        !store.record.assignMarks.isEmpty || !store.record.finishMarks.isEmpty || !store.record.wasteMarks.isEmpty
    }

    private var wasteTitle: String {
        guard let wasteID, let tin = store.record.tin(id: wasteID) else {
            return "Waste this tin? It leaves the shelf without a cook day."
        }
        return "Waste \(tin.title)? It leaves the shelf without a cook day."
    }

    private func commit(_ work: () -> Void) {
        guard !busy else { return }
        busy = true
        work()
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            busy = false
        }
    }
}

struct ShelfLift: Equatable {
    var id: UUID
    var dy: CGFloat
    var dx: CGFloat
}

/// Grain sits on the featured card only. Every other surface is stock SwiftUI.
struct PaperBoardPlate<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduce
    @ViewBuilder var content: () -> Content

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 12.0, paused: reduce)) { timeline in
            content()
                .background(DesignTokens.surface)
                .paperPlate()
                .colorEffect(
                    ShaderLibrary.paperGrain(
                        .float(reduce ? 0 : Float(timeline.date.timeIntervalSinceReferenceDate))
                    )
                )
        }
    }
}
