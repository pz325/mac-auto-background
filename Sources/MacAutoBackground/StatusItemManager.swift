import AppKit

@MainActor
final class StatusItemManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private weak var settings: AppSettings?
    private weak var engine: Engine?
    private let store = RecentFavoritesStore()
    
    func configure(settings: AppSettings, engine: Engine) {
        self.settings = settings
        self.engine = engine
        updateVisibility()
    }
    
    func updateVisibility() {
        guard let settings else { return }
        if settings.showMenuBarIcon {
            installIfNeeded()
            rebuildMenu()
        } else {
            removeIfNeeded()
        }
    }
    
    private func installIfNeeded() {
        guard statusItem == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = IconGenerator.makeStatusIcon(size: 18)
        item.button?.imagePosition = .imageOnly
        item.isVisible = true
        item.behavior = []
        statusItem = item
    }
    
    private func removeIfNeeded() {
        if let s = statusItem {
            NSStatusBar.system.removeStatusItem(s)
            statusItem = nil
        }
    }
    
    private func rebuildMenu() {
        guard let settings, let engine else { return }
        let menu = NSMenu()
        
        let openItem = NSMenuItem(title: "打开窗口", action: #selector(openWindow), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)
        
        let changeItem = NSMenuItem(title: "立即更换", action: #selector(changeNow), keyEquivalent: "")
        changeItem.target = self
        menu.addItem(changeItem)
        
        let favTitle = store.isFavorite(engine.currentImageURL) ? "取消收藏当前" : "收藏当前"
        let favItem = NSMenuItem(title: favTitle, action: #selector(toggleFavoriteCurrent), keyEquivalent: "")
        favItem.target = self
        menu.addItem(favItem)
        
        let recentSub = NSMenu(title: "最近")
        for url in Array(store.recent().prefix(5)) {
            let it = NSMenuItem(title: url.lastPathComponent, action: #selector(setFromMenu(_:)), keyEquivalent: "")
            it.representedObject = url.path
            it.target = self
            recentSub.addItem(it)
        }
        let recentRoot = NSMenuItem(title: "最近", action: nil, keyEquivalent: "")
        menu.setSubmenu(recentSub, for: recentRoot)
        menu.addItem(recentRoot)
        
        let favSub = NSMenu(title: "收藏")
        for url in store.favorites().prefix(10) {
            let it = NSMenuItem(title: url.lastPathComponent, action: #selector(setFromMenu(_:)), keyEquivalent: "")
            it.representedObject = url.path
            it.target = self
            favSub.addItem(it)
        }
        let favRoot = NSMenuItem(title: "收藏", action: nil, keyEquivalent: "")
        menu.setSubmenu(favSub, for: favRoot)
        menu.addItem(favRoot)
        
        menu.addItem(.separator())
        
        let loginTitle = settings.launchAtLogin ? "登录时自动启动 ✓" : "登录时自动启动"
        let loginItem = NSMenuItem(title: loginTitle, action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        loginItem.target = self
        menu.addItem(loginItem)
        
        let barTitle = settings.showMenuBarIcon ? "显示菜单栏图标 ✓" : "显示菜单栏图标"
        let barItem = NSMenuItem(title: barTitle, action: #selector(toggleMenuBar), keyEquivalent: "")
        barItem.target = self
        menu.addItem(barItem)
        
        menu.addItem(.separator())
        
        let quitItem = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func openWindow() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }
    
    @objc private func changeNow() {
        Task { [weak self] in
            await self?.engine?.changeNow()
        }
    }
    
    @objc private func toggleFavoriteCurrent() {
        guard let url = engine?.currentImageURL else { return }
        store.toggleFavorite(url)
        rebuildMenu()
    }
    
    @objc private func setFromMenu(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else { return }
        let url = URL(fileURLWithPath: path)
        Task { [weak self] in
            await self?.engine?.setImage(url: url)
        }
    }
    
    @objc private func toggleLaunchAtLogin() {
        guard let settings else { return }
        let enable = !settings.launchAtLogin
        Task { @MainActor in
            do {
                try await LaunchAtLogin.setEnabled(enable)
                settings.launchAtLogin = enable
            } catch {
                settings.launchAtLogin = false
            }
            self.rebuildMenu()
        }
    }
    
    @objc private func toggleMenuBar() {
        guard let settings else { return }
        settings.showMenuBarIcon.toggle()
        updateVisibility()
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
