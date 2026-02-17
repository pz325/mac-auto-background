import Foundation
import Combine

final class AppSettings: ObservableObject {
    @Published var intervalMinutes: Int {
        didSet { UserDefaults.standard.set(intervalMinutes, forKey: "intervalMinutes") }
    }
    @Published var changeOnWake: Bool {
        didSet { UserDefaults.standard.set(changeOnWake, forKey: "changeOnWake") }
    }
    @Published var provider: ProviderType {
        didSet { UserDefaults.standard.set(provider.rawValue, forKey: "provider") }
    }
    @Published var avoidDuplicates: Bool {
        didSet { UserDefaults.standard.set(avoidDuplicates, forKey: "avoidDuplicates") }
    }
    @Published var maxHistory: Int {
        didSet { UserDefaults.standard.set(maxHistory, forKey: "maxHistory") }
    }
    @Published var launchAtLogin: Bool {
        didSet { UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin") }
    }
    @Published var showMenuBarIcon: Bool {
        didSet { UserDefaults.standard.set(showMenuBarIcon, forKey: "showMenuBarIcon") }
    }
    @Published var cacheMaxMB: Int {
        didSet { UserDefaults.standard.set(cacheMaxMB, forKey: "cacheMaxMB") }
    }
    
    init() {
        let d = UserDefaults.standard
        let defaultInterval = 60
        intervalMinutes = d.object(forKey: "intervalMinutes") as? Int ?? defaultInterval
        changeOnWake = d.object(forKey: "changeOnWake") as? Bool ?? true
        let p = d.string(forKey: "provider").flatMap { ProviderType(rawValue: $0) } ?? .auto
        provider = p
        avoidDuplicates = d.object(forKey: "avoidDuplicates") as? Bool ?? true
        maxHistory = d.object(forKey: "maxHistory") as? Int ?? 300
        launchAtLogin = d.object(forKey: "launchAtLogin") as? Bool ?? false
        showMenuBarIcon = d.object(forKey: "showMenuBarIcon") as? Bool ?? true
        cacheMaxMB = d.object(forKey: "cacheMaxMB") as? Int ?? 512
    }
}

enum ProviderType: String, CaseIterable, Identifiable {
    case auto
    case bing
    case picsum
    case unsplash
    
    var id: String { rawValue }
}
