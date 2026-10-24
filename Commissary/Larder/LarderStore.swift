import Foundation

/// Seam between the fold and storage. Views talk to this type, never to the file or UserDefaults.
/// The record in memory is the source of truth. The file and `cms.larder.v1` are a debounced projection.
@MainActor
@Observable
final class LarderStore {
    private(set) var record: LarderRecord
    private(set) var board: CookDayBoard
    private(set) var loadWarning: String?
    /// Increments only when Assign or Finish commits, so the UI can fire one haptic.
    private(set) var commitTick: Int
    /// Last fold refusal, so the screen can say what failed and offer a way forward.
    private(set) var lastRefusal: FoldRefusal?
    /// True after the first load attempt finishes, including a recovered empty shelf.
    private(set) var isReady = false

    private let defaults: UserDefaults
    private let disk: LarderDisk
    private let fileURL: URL
    private let now: @Sendable () -> Date
    private let calendar: Calendar
    private let debounce: Duration
    private let seedsDemo: Bool
    private var saveTask: Task<Void, Never>?
    private var didLoad = false

    init(
        seedsDemo: Bool = false,
        defaults: UserDefaults = .standard,
        directory: URL? = nil,
        now: @escaping @Sendable () -> Date = { Date() },
        calendar: Calendar = .current,
        debounce: Duration = .milliseconds(250)
    ) {
        self.seedsDemo = seedsDemo
        self.defaults = defaults
        self.disk = LarderDisk()
        self.now = now
        self.calendar = calendar
        self.debounce = debounce
        let folder = directory ?? Self.supportDirectory()
        self.fileURL = folder.appendingPathComponent("larder.json")
        self.record = .empty
        self.board = LarderFold.board(.empty, today: CookDay.daykey(for: now(), calendar: calendar), calendar: calendar)
        self.commitTick = 0
        self.lastRefusal = nil
    }

    func load() async {
        guard !didLoad else { return }
        didLoad = true
        let loaded = await readProjection()
        record = loaded.record
        loadWarning = loaded.warning
        await installDemoIfNeeded()
        reproject()
        isReady = true
    }

    /// Cook-day window the assign picker offers. The fold still owns phase.
    func setCookHorizon(_ days: Int) {
        let clamped = min(14, max(1, days))
        guard record.cookHorizonDays != clamped else { return }
        record.cookHorizonDays = clamped
        scheduleSave()
    }

    func clearRefusal() {
        lastRefusal = nil
    }

    /// Re-read the shelf after a failed load. Does not clear a live refusal by itself.
    func retryLoad() async {
        didLoad = false
        await load()
    }

    func scan(title: String, barcode: String, packageDaykey: Int, id: UUID = UUID()) {
        apply(.scan(title: title, barcode: barcode, packageDaykey: packageDaykey, id: id, at: now()))
    }

    func assign(tinID: UUID, cookDaykey: Int) {
        apply(.assign(tinID: tinID, cookDaykey: cookDaykey, at: now()))
    }

    func finish(tinID: UUID) {
        apply(.finish(tinID: tinID, at: now()))
    }

    func waste(tinID: UUID) {
        apply(.waste(tinID: tinID, at: now()))
    }

    func undo() {
        apply(.undo)
    }

    func cullLapsed() async {
        apply(.cullLapsed, immediate: true)
        await flush()
    }

    func adjustPackage(tinID: UUID, packageDaykey: Int) {
        apply(.adjustPackage(tinID: tinID, packageDaykey: packageDaykey))
    }

    func completeOnboarding() {
        record.onboardingComplete = true
        scheduleSave()
    }

    func noteClock() {
        reproject()
    }

    func resetAllData() async {
        saveTask?.cancel()
        saveTask = nil
        record = .empty
        defaults.removeObject(forKey: LarderKeys.record)
        defaults.set(false, forKey: LarderKeys.demo)
        do {
            try await disk.remove(at: fileURL)
        } catch {
            loadWarning = "Reset could not delete the saved larder."
        }
        await installDemoIfNeeded()
        reproject()
        if record.tins.isEmpty {
            await flush()
        }
    }

    func flush() async {
        saveTask?.cancel()
        saveTask = nil
        await writeProjection()
    }

    var todayKey: Int {
        CookDay.daykey(for: now(), calendar: calendar)
    }

    private func apply(_ command: LarderCommand, immediate: Bool = false) {
        let effect = LarderFold.reduce(record, command, today: todayKey, calendar: calendar)
        record = effect.record
        lastRefusal = effect.refusal
        if effect.committed == .assign || effect.committed == .finish {
            commitTick += 1
        }
        reproject()
        if immediate || effect.committed == .cull {
            saveTask?.cancel()
            saveTask = Task { await self.flush() }
        } else if effect.committed != nil {
            scheduleSave()
        }
    }

    private func reproject() {
        board = LarderFold.board(record, today: todayKey, calendar: calendar)
    }

    private func scheduleSave() {
        saveTask?.cancel()
        let delay = debounce
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled, let self else { return }
            await self.flush()
        }
    }

    private func installDemoIfNeeded() async {
        guard seedsDemo else { return }
        guard defaults.bool(forKey: LarderKeys.demo) == false else { return }
        record = LarderSeed.demo(today: todayKey, calendar: calendar, now: now())
        defaults.set(true, forKey: LarderKeys.demo)
        await flush()
    }

    private func readProjection() async -> (record: LarderRecord, warning: String?) {
        if let data = await disk.read(from: fileURL) {
            switch LarderRecord.decode(data) {
            case let .success(record):
                return (record, nil)
            case .failure:
                do {
                    try await disk.archiveCorrupt(at: fileURL)
                } catch {
                    return (.empty, "Could not archive the damaged larder. Starting fresh.")
                }
                let backup = fileURL.appendingPathExtension("backup")
                if let saved = await disk.read(from: backup) {
                    switch LarderRecord.decode(saved) {
                    case let .success(record):
                        return (record, "Recovered the previous larder.")
                    case .failure:
                        return (.empty, "The saved larder could not be read. Starting fresh.")
                    }
                }
                return (.empty, "The saved larder could not be read. Starting fresh.")
            }
        }
        if let blob = defaults.data(forKey: LarderKeys.record) {
            switch LarderRecord.decode(blob) {
            case let .success(record):
                return (record, nil)
            case .failure:
                return (.empty, "The saved larder could not be read. Starting fresh.")
            }
        }
        return (.empty, nil)
    }

    private func writeProjection() async {
        let snapshot = record
        do {
            let data = try snapshot.encoded()
            try await disk.persist(data, to: fileURL)
            defaults.set(data, forKey: LarderKeys.record)
        } catch {
            loadWarning = "The larder could not be saved. Your latest marks are still on screen."
        }
    }

    private static func supportDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let root = base ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return root.appendingPathComponent("Chickomissar", isDirectory: true)
    }
}
