import SwiftUI
import AppKit

enum AppWindowMetrics {
    static let minContentWidth: CGFloat = 920
    static let minContentHeight: CGFloat = 780
    static let defaultContentWidth: CGFloat = 960
    static let defaultContentHeight: CGFloat = 820
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        sender.activate(ignoringOtherApps: true)
        return true
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let win = NSApplication.shared.windows.first {
                self.configureWindow(win)
            }
        }
    }
    
    func application(_ application: NSApplication, didCreateWindow window: NSWindow) {
        configureWindow(window)
    }
    
    private func configureWindow(_ window: NSWindow) {
        let minSize = NSSize(width: AppWindowMetrics.minContentWidth, height: AppWindowMetrics.minContentHeight)
        let defaultSize = NSSize(width: AppWindowMetrics.defaultContentWidth, height: AppWindowMetrics.defaultContentHeight)
        window.contentMinSize = minSize
        if window.contentLayoutRect.width < minSize.width || window.contentLayoutRect.height < minSize.height {
            window.setContentSize(defaultSize)
        }
        window.center()
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isMovableByWindowBackground = true
        
        if let button = window.standardWindowButton(.zoomButton) {
            button.isEnabled = true
        }
    }
}

@main
struct MacAutoBackgroundApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settings = AppSettings()
    @StateObject private var engine = Engine()
    @StateObject private var statusItem = StatusItemManager()
    
    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(engine)
                .frame(
                    minWidth: AppWindowMetrics.minContentWidth,
                    idealWidth: AppWindowMetrics.defaultContentWidth,
                    minHeight: AppWindowMetrics.minContentHeight,
                    idealHeight: AppWindowMetrics.defaultContentHeight
                )
                .onAppear {
                    engine.configure(with: settings)
                    engine.start()
                    Task { @MainActor in
                        engine.refreshCurrentWallpaper()
                        statusItem.configure(settings: settings, engine: engine)
                        statusItem.updateVisibility()
                    }
                }
                .onChange(of: settings.showMenuBarIcon) { _ in
                    statusItem.updateVisibility()
                }
                .onChange(of: settings.launchAtLogin) { newValue in
                    Task {
                        do {
                            try await LaunchAtLogin.setEnabled(newValue)
                        } catch {
                            await MainActor.run { settings.launchAtLogin = false }
                        }
                    }
                }
        }
    }
}
