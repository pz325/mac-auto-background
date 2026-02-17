import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for win in sender.windows {
                win.makeKeyAndOrderFront(nil)
            }
        }
        sender.activate(ignoringOtherApps: true)
        return true
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
                .onAppear {
                    engine.configure(with: settings)
                    engine.start()
                    Task { @MainActor in
                        if let win = NSApp.windows.first {
                            win.setContentSize(NSSize(width: 760, height: 620))
                            win.center()
                        }
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
