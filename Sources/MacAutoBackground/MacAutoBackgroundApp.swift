import SwiftUI
import AppKit

@main
struct MacAutoBackgroundApp: App {
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
