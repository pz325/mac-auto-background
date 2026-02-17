import Foundation
import ServiceManagement

enum LaunchAtLogin {
    static func setEnabled(_ enabled: Bool) async throws {
        if #available(macOS 13.0, *) {
            if enabled {
                try await SMAppService.mainApp.register()
            } else {
                try await SMAppService.mainApp.unregister()
            }
        } else {
            throw NSError(domain: "LaunchAtLogin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Requires macOS 13+"])
        }
    }
}
