import AppKit
import Combine

@MainActor
final class StatusItemManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private weak var settings: AppSettings?
    private weak var engine: Engine?
    private let store = RecentStore()
    
    func configure(settings: AppSettings, engine: Engine) {
        self.settings = settings
        self.engine = engine
        
        // Listen for language changes
        settings.$language
            .sink { newLanguage in
                DispatchQueue.main.async {
                    self.rebuildMenu(with: newLanguage)
                }
            }
            .store(in: &cancellables)
        
        updateVisibility()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
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
    
    private func rebuildMenu(with language: Language? = nil) {
        guard let settings, let engine else { return }
        let currentLanguage = language ?? settings.language
        let menu = NSMenu()
        
        let openItem = NSMenuItem(title: LocalizedStrings.text(for: "openWindow", language: currentLanguage), action: #selector(openWindow), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)
        
        let changeItem = NSMenuItem(title: LocalizedStrings.text(for: "changeNow", language: currentLanguage), action: #selector(changeNow), keyEquivalent: "")
        changeItem.target = self
        menu.addItem(changeItem)
        
        let recentSub = NSMenu(title: LocalizedStrings.text(for: "recent", language: currentLanguage))
        for url in Array(store.recent().prefix(5)) {
            let it = NSMenuItem(title: url.lastPathComponent, action: #selector(setFromMenu(_:)), keyEquivalent: "")
            it.representedObject = url.path
            it.target = self
            recentSub.addItem(it)
        }
        let recentRoot = NSMenuItem(title: LocalizedStrings.text(for: "recent", language: currentLanguage), action: nil, keyEquivalent: "")
        menu.setSubmenu(recentSub, for: recentRoot)
        menu.addItem(recentRoot)
        
        menu.addItem(.separator())
        
        let loginTitle = settings.launchAtLogin ? LocalizedStrings.text(for: "launchAtLoginEnabled", language: currentLanguage) : LocalizedStrings.text(for: "launchAtLoginDisabled", language: currentLanguage)
        let loginItem = NSMenuItem(title: loginTitle, action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        loginItem.target = self
        menu.addItem(loginItem)
        
        let barTitle = settings.showMenuBarIcon ? LocalizedStrings.text(for: "showMenuBarIconEnabled", language: currentLanguage) : LocalizedStrings.text(for: "showMenuBarIconDisabled", language: currentLanguage)
        let barItem = NSMenuItem(title: barTitle, action: #selector(toggleMenuBar), keyEquivalent: "")
        barItem.target = self
        menu.addItem(barItem)
        
        menu.addItem(.separator())
        
        let quitItem = NSMenuItem(title: LocalizedStrings.text(for: "quit", language: currentLanguage), action: #selector(quitApp), keyEquivalent: "q")
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
