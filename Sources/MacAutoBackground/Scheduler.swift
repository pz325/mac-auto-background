import AppKit
import Combine

final class Engine: ObservableObject {
    @Published private(set) var lastChange: Date?
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var lastError: String?
    @Published private(set) var currentImageURL: URL?
    
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
        Task { @MainActor in
            refreshCurrentWallpaper()
        }
        Task.detached {
            let maxMB = UserDefaults.standard.object(forKey: "cacheMaxMB") as? Int ?? 512
            let maxBytes = Int64(maxMB * 1024 * 1024)
            CacheManager.cleanupImagesIfNeeded(maxBytes: maxBytes, excluding: nil)
        }
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
                guard let s = self else { return }
                Task { @MainActor in
                    await s.changeNow()
                }
            }
    }
    
    @objc private func handleWake() {
        guard settings?.changeOnWake == true else { return }
        let s = self
        Task { @MainActor in
            await s.changeNow()
        }
    }
    
    @objc private func handleScreenWake() {
        guard settings?.changeOnWake == true else { return }
        let s = self
        Task { @MainActor in
            await s.changeNow()
        }
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
            currentImageURL = item.fileURL
            lastError = nil
            lastChange = Date()
            let maxBytes = Int64((settings.cacheMaxMB as Int) * 1024 * 1024)
            CacheManager.cleanupImagesIfNeeded(maxBytes: maxBytes, excluding: currentImageURL)
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    @MainActor
    func refreshCurrentWallpaper() {
        let screen = NSScreen.main ?? NSScreen.screens.first
        if let sc = screen, let url = NSWorkspace.shared.desktopImageURL(for: sc) {
            currentImageURL = url
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
        case .auto:
            return AutoProvider()
        case .bing:
            return BingProvider()
        case .picsum:
            return PicsumProvider()
        case .unsplash:
            return UnsplashProvider()
        }
    }
}
