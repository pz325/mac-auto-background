import AppKit
import Combine

final class Engine: ObservableObject {
    @Published private(set) var lastChange: Date?
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var lastError: String?
    @Published private(set) var currentImageURL: URL?
    private var prefetched: (fileURL: URL, hash: String)?
    
    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: AnyCancellable?
    
    private var settings: AppSettings?
    private let changer = WallpaperChanger()
    private let history = HistoryStore()
  private let recents = RecentFavoritesStore()
    
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
        Task.detached { [weak self] in
            await self?.prefetchNext()
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
            var item: (fileURL: URL, hash: String)
            if let p = prefetched {
                item = p
            } else {
                let provider: ImageProvider = providerFor(settings.provider)
                let existing = Set(history.load(maxCount: settings.maxHistory))
                let (tw, th) = targetPixelSize(from: screens)
                item = try await provider.fetchImage(targetWidth: tw, targetHeight: th, avoiding: existing, maxAttempts: 8)
            }
            if settings.avoidDuplicates {
                history.append(item.hash, maxCount: settings.maxHistory)
            }
            try changer.setWallpaper(url: item.fileURL, on: screens)
            currentImageURL = item.fileURL
            lastError = nil
            lastChange = Date()
            recents.addRecent(item.fileURL, max: 20)
            let maxBytes = Int64((settings.cacheMaxMB as Int) * 1024 * 1024)
            CacheManager.cleanupImagesIfNeeded(maxBytes: maxBytes, excluding: currentImageURL)
            prefetched = nil
            Task.detached { [weak self] in
                await self?.prefetchNext()
            }
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
            if let s = settings, !s.unsplashAccessKey.isEmpty {
                return UnsplashAPIProvider(key: s.unsplashAccessKey, query: s.unsplashQuery)
            } else {
                return UnsplashProvider()
            }
        }
    }
    
    private func prefetchNext() async {
        guard let settings else { return }
        let provider: ImageProvider = providerFor(settings.provider)
        let existing = Set(history.load(maxCount: settings.maxHistory))
        let (tw, th) = await MainActor.run { targetPixelSize(from: NSScreen.screens) }
        do {
            let item = try await provider.fetchImage(targetWidth: tw, targetHeight: th, avoiding: existing, maxAttempts: 6)
            prefetched = item
        } catch {
            prefetched = nil
        }
    }
    
    @MainActor
    func setImage(url: URL) async {
        do {
            let screens = NSScreen.screens
            try changer.setWallpaper(url: url, on: screens)
            currentImageURL = url
            lastError = nil
            lastChange = Date()
            recents.addRecent(url, max: 20)
        } catch {
            lastError = error.localizedDescription
        }
    }
}
