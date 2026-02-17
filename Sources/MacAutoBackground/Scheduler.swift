import AppKit
import Combine

final class Engine: ObservableObject {
    @Published private(set) var lastChange: Date?
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var lastError: String?
    
    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: AnyCancellable?
    
    private var settings: AppSettings?
    private let changer = WallpaperChanger()
    private let history = HistoryStore()
    
    func configure(with settings: AppSettings) {
        self.settings = settings
        settings.$intervalMinutes
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.restartTimer()
            }
            .store(in: &cancellables)
    }
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        restartTimer()
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(self, selector: #selector(handleWake), name: NSWorkspace.didWakeNotification, object: nil)
        nc.addObserver(self, selector: #selector(handleScreenWake), name: NSWorkspace.screensDidWakeNotification, object: nil)
    }
    
    func stop() {
        isRunning = false
        timerCancellable?.cancel()
        timerCancellable = nil
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
    
    private func restartTimer() {
        timerCancellable?.cancel()
        guard let settings else { return }
        let interval = max(1, settings.intervalMinutes)
        timerCancellable = Timer.publish(every: TimeInterval(interval * 60), on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.changeNow() }
            }
    }
    
    @objc private func handleWake() {
        guard settings?.changeOnWake == true else { return }
        Task { await changeNow() }
    }
    
    @objc private func handleScreenWake() {
        guard settings?.changeOnWake == true else { return }
        Task { await changeNow() }
    }
    
    @MainActor
    func changeNow() async {
        do {
            let screens = NSScreen.screens
            guard let settings else { return }
            let provider: ImageProvider = providerFor(settings.provider)
            let existing = Set(history.load(maxCount: settings.maxHistory))
            let (tw, th) = targetPixelSize(from: screens)
            let item = try await provider.fetchImage(targetWidth: tw, targetHeight: th, avoiding: existing, maxAttempts: 8)
            if settings.avoidDuplicates {
                history.append(item.hash, maxCount: settings.maxHistory)
            }
            try changer.setWallpaper(url: item.fileURL, on: screens)
            lastError = nil
            lastChange = Date()
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    @MainActor
    private func targetPixelSize(from screens: [NSScreen]) -> (Int, Int) {
        var w: CGFloat = 1920
        var h: CGFloat = 1080
        for s in screens {
            let frame = s.frame
            let scale = s.backingScaleFactor
            w = max(w, frame.width * scale)
            h = max(h, frame.height * scale)
        }
        return (max(1, Int(w.rounded())), max(1, Int(h.rounded())))
    }
    
    private func providerFor(_ type: ProviderType) -> ImageProvider {
        switch type {
        case .picsum:
            return PicsumProvider()
        }
    }
}
