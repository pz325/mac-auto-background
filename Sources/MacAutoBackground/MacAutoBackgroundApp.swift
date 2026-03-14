import SwiftUI
import AppKit

class WindowDelegate: NSObject, NSWindowDelegate {
    private let targetSize: NSSize
    
    init(targetSize: NSSize) {
        self.targetSize = targetSize
        super.init()
    }
    
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        return targetSize
    }
    
    func windowDidResize(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            window.setContentSize(targetSize)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowDelegate: WindowDelegate?
    private var hasConfiguredWindow = false
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Show existing window instead of creating new one
        if let window = sender.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
        sender.activate(ignoringOtherApps: true)
        return false
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let win = NSApplication.shared.windows.first {
                self.configureWindow(win)
            }
        }
    }
    
    func application(_ application: NSApplication, didCreateWindow window: NSWindow) {
        // Only configure the first window, close any subsequent ones
        if hasConfiguredWindow {
            window.close()
            // Bring the first window to front
            if let firstWindow = application.windows.first, firstWindow != window {
                firstWindow.makeKeyAndOrderFront(nil)
            }
            return
        }
        hasConfiguredWindow = true
        configureWindow(window)
    }
    
    private func configureWindow(_ window: NSWindow) {
        let size = NSSize(width: 760, height: 620)
        window.setContentSize(size)
        window.center()
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.styleMask.remove(.resizable)
        window.minSize = size
        window.maxSize = size
        window.collectionBehavior = .fullScreenNone
        window.isMovableByWindowBackground = true
        
        let delegate = WindowDelegate(targetSize: size)
        window.delegate = delegate
        windowDelegate = delegate
        
        if let button = window.standardWindowButton(.zoomButton) {
            button.isEnabled = false
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
                .frame(width: 760, height: 620)
                .fixedSize()
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
