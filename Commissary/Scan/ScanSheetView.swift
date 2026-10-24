import AVFoundation
import SwiftUI

/// Scan sheet. Simulator uses sample codes and a manual field. Device uses the camera after Continue.
struct ScanSheetView: View {
    var settle: Bool
    @Environment(LarderStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var focus: ScanField?
    @State private var capture = BarcodeCapture()
    @State private var client: OpenFoodFactsClient?
    @State private var cameraStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var terms = ""
    @State private var barcode = ""
    @State private var title = ""
    @State private var packageDate = Date()
    @State private var results: [ShelfIdentity] = []
    @State private var searchError: String?
    @State private var formError: String?
    @State private var searching = false
    @State private var showSpin = false
    @State private var lookingUp = false
    @State private var busy = false
    @State private var lastPayload = ""
    @State private var lastHit = Date.distantPast
    @State private var searchTask: Task<Void, Never>?

    private var cameraAvailable: Bool {
        AVCaptureDevice.default(for: .video) != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s4) {
                    HeroWord(text: "SCAN")
                    Text("Read a barcode, or type one. Save adds the tin to the shelf.")
                        .font(TypeFace.body)
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if let formError {
                        NoticeBanner(message: formError, actionTitle: "Try again") {
                            self.formError = nil
                            if !lastPayload.isEmpty {
                                Task { await lookup(lastPayload) }
                            }
                        }
                    }
                    cameraBlock
                    #if targetEnvironment(simulator)
                    SimulatorSampleShelf { identity in
                        apply(identity)
                    }
                    #endif
                    searchBlock
                    formBlock
                    GlassButton(title: "Save tin", system: "checkmark", tone: .live, enabled: canSave && !busy) {
                        save()
                    }
                }
                .padding(Spacing.s5)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(DesignTokens.bg.ignoresSafeArea())
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .frame(minHeight: Chrome.hit)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Button("Next") { advanceFocus() }
                        .frame(minHeight: Chrome.hit)
                    Spacer()
                    Button("Done") { focus = nil }
                        .frame(minHeight: Chrome.hit)
                }
            }
            .sheetEntry(settle: settle)
            .onAppear { prepareCamera() }
            .onDisappear { capture.stop() }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active {
                    capture.stop()
                } else if cameraStatus == .authorized && cameraAvailable {
                    capture.start()
                }
            }
            .onChange(of: terms) { _, newValue in
                scheduleSearch(newValue)
            }
            .onChange(of: barcode) { _, newValue in
                let digits = String(newValue.filter(\.isNumber).prefix(14))
                if digits != newValue { barcode = digits }
            }
            .task {
                let made = lookupClient()
                await made.loadCache()
            }
        }
    }

    @ViewBuilder
    private var cameraBlock: some View {
        if cameraAvailable {
            switch cameraStatus {
            case .authorized:
                AVCaptureMetadataOutputHost(session: capture.session)
            case .notDetermined:
                VStack(alignment: .leading, spacing: Spacing.s3) {
                    Text("The camera reads the barcode on the tin.")
                        .font(TypeFace.body)
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    GlassButton(title: "Continue", system: "arrow.right", tone: .live) {
                        AVCaptureDevice.requestAccess(for: .video) { granted in
                            Task { @MainActor in
                                cameraStatus = granted ? .authorized : .denied
                                if granted { capture.start() }
                            }
                        }
                    }
                }
                .padding(Spacing.s4)
                .paperPlate()
            case .denied, .restricted:
                VStack(alignment: .leading, spacing: Spacing.s3) {
                    Text("Camera is off. Open Settings to use it, or type a code below.")
                        .font(TypeFace.body)
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(TypeFace.callout)
                    .foregroundStyle(DesignTokens.ink)
                    .frame(maxWidth: .infinity, minHeight: Chrome.hit)
                    .paperPlate()
                }
            @unknown default:
                Text("Camera is unavailable. Type a code below.")
                    .font(TypeFace.body)
                    .foregroundStyle(DesignTokens.ink)
            }
        }
    }

    private var searchBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Eyebrow(text: "FIND A PRODUCT")
            TextField("Name", text: $terms)
                .font(TypeFace.body)
                .focused($focus, equals: .terms)
                .textInputAutocapitalization(.words)
                .submitLabel(.next)
                .onSubmit { focus = .barcode }
                .padding(Spacing.s3)
                .frame(minHeight: Chrome.hit)
                .paperPlate(chip: true)
            if showSpin {
                ProgressView("Searching")
                    .font(TypeFace.caption)
                    .frame(maxWidth: .infinity, minHeight: Chrome.hit, alignment: .leading)
            }
            if let searchError {
                NoticeBanner(message: searchError, actionTitle: "Try again") {
                    scheduleSearch(terms)
                }
            }
            if searching && results.isEmpty && !showSpin {
                Text("Oat tin")
                    .font(TypeFace.body)
                    .redacted(reason: .placeholder)
                    .frame(maxWidth: .infinity, minHeight: Chrome.hit, alignment: .leading)
                    .paperPlate(chip: true)
            }
            ForEach(results) { item in
                Button {
                    apply(item)
                } label: {
                    HStack {
                        Text(item.title)
                            .font(TypeFace.body)
                            .foregroundStyle(DesignTokens.ink)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer(minLength: Spacing.s2)
                        Text(item.brand)
                            .font(TypeFace.caption)
                            .foregroundStyle(DesignTokens.muted)
                            .lineLimit(1)
                            .layoutPriority(1)
                    }
                    .padding(.horizontal, Spacing.s4)
                    .frame(maxWidth: .infinity, minHeight: Chrome.hit)
                    .paperPlate(chip: true)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var formBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Eyebrow(text: "TIN")
            TextField("Barcode", text: $barcode)
                .font(TypeFace.body)
                .focused($focus, equals: .barcode)
                .keyboardType(.numberPad)
                .submitLabel(.next)
                .onSubmit { focus = .title }
                .padding(Spacing.s3)
                .frame(minHeight: Chrome.hit)
                .paperPlate(chip: true)
            TextField("Title", text: $title)
                .font(TypeFace.body)
                .focused($focus, equals: .title)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .onSubmit { focus = nil }
                .padding(Spacing.s3)
                .frame(minHeight: Chrome.hit)
                .paperPlate(chip: true)
            DatePicker("Best before", selection: $packageDate, displayedComponents: .date)
                .font(TypeFace.body)
                .datePickerStyle(.compact)
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !BarcodePayload.candidates(in: barcode).isEmpty
            && !lookingUp
    }

    private func prepareCamera() {
        cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        capture.setHandlers(payload: { raw in
            Task { @MainActor in
                await self.accept(raw)
            }
        }, failure: { message in
            Task { @MainActor in
                self.formError = message
            }
        })
        if cameraAvailable && cameraStatus == .authorized {
            capture.start()
        }
    }

    private func accept(_ raw: String) async {
        let now = Date()
        if now.timeIntervalSince(lastHit) < 1.8 { return }
        if lookingUp && raw == lastPayload { return }
        lastHit = now
        lastPayload = raw
        await lookup(raw)
    }

    private func lookup(_ raw: String) async {
        let candidates = BarcodePayload.candidates(in: raw)
        guard let code = candidates.first else {
            formError = "Scan failed. Try again."
            return
        }
        lookingUp = true
        let spin = Task {
            try? await Task.sleep(for: .milliseconds(150))
            if lookingUp { showSpin = true }
        }
        defer {
            spin.cancel()
            lookingUp = false
            showSpin = false
        }
        if let local = LocalShelfCatalog.match(barcode: code) {
            apply(local)
            return
        }
        do {
            let identity = try await lookupClient().product(barcode: code)
            apply(identity)
            formError = nil
        } catch is CancellationError {
            return
        } catch {
            formError = "Scan failed. Try again."
        }
    }

    private func apply(_ identity: ShelfIdentity) {
        title = identity.title
        barcode = identity.barcode
        formError = nil
        focus = nil
    }

    private func scheduleSearch(_ raw: String) {
        searchTask?.cancel()
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            results = []
            searchError = nil
            searching = false
            showSpin = false
            return
        }
        results = LocalShelfCatalog.search(terms: trimmed)
        searching = true
        searchError = nil
        searchTask = Task {
            let spin = Task {
                try? await Task.sleep(for: .milliseconds(150))
                if searching && results.isEmpty { showSpin = true }
            }
            do {
                let found = try await lookupClient().search(terms: trimmed)
                if Task.isCancelled { return }
                results = found
                searchError = nil
            } catch is CancellationError {
                return
            } catch {
                if Task.isCancelled { return }
                let local = LocalShelfCatalog.search(terms: trimmed)
                results = local
                if local.isEmpty {
                    searchError = "Search failed. Try again."
                }
            }
            spin.cancel()
            searching = false
            showSpin = false
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let code = BarcodePayload.candidates(in: barcode).first else {
            formError = "Scan failed. Try again."
            return
        }
        guard !busy else { return }
        busy = true
        let day = CookDay.daykey(for: Calendar.current.startOfDay(for: packageDate), calendar: .current)
        guard day > 0 else {
            formError = "Scan failed. Try again."
            busy = false
            return
        }
        store.scan(title: trimmed, barcode: code, packageDaykey: day)
        if store.lastRefusal != nil {
            formError = RefusalCopy.line(store.lastRefusal ?? .invalidScan)
            busy = false
            return
        }
        busy = false
        dismiss()
    }

    private func advanceFocus() {
        switch focus {
        case .terms: focus = .barcode
        case .barcode: focus = .title
        case .title, nil: focus = nil
        }
    }

    private func lookupClient() -> OpenFoodFactsClient {
        if let client { return client }
        let root = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let folder = root.appendingPathComponent("shelf-cache", isDirectory: true)
        let made = OpenFoodFactsClient(cacheDirectory: folder, debounce: .milliseconds(500))
        client = made
        return made
    }
}

enum ScanField: Hashable {
    case terms
    case barcode
    case title
}
