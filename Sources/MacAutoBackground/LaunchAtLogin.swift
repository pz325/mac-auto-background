import Foundation
import ServiceManagement

enum LaunchAtLogin {
    static func setEnabled(_ enabled: Bool) async throws {
        if #available(macOS 13.0, *) {
            if enabled {
                try await Task { try SMAppService.mainApp.register() }.value
            } else {
                try await Task { try SMAppService.mainApp.unregister() }.value
            }
        } else {
            throw NSError(domain: "LaunchAtLogin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Requires macOS 13+"])
        }
    }
}
