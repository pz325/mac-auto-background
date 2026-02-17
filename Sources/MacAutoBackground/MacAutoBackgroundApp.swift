import SwiftUI
import AppKit

@main
struct MacAutoBackgroundApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var engine = Engine()
    
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
                    NSApplication.shared.applicationIconImage = IconGenerator.makeIcon()
                    engine.configure(with: settings)
                    engine.start()
                    Task { @MainActor in
                        engine.refreshCurrentWallpaper()
                    }
                }
        }
    }
}
