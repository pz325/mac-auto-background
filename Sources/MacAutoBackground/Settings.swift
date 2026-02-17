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
    
    init() {
        let d = UserDefaults.standard
        let defaultInterval = 60
        intervalMinutes = d.object(forKey: "intervalMinutes") as? Int ?? defaultInterval
        changeOnWake = d.object(forKey: "changeOnWake") as? Bool ?? true
        let p = d.string(forKey: "provider").flatMap { ProviderType(rawValue: $0) } ?? .picsum
        provider = p
        avoidDuplicates = d.object(forKey: "avoidDuplicates") as? Bool ?? true
        maxHistory = d.object(forKey: "maxHistory") as? Int ?? 300
    }
}

enum ProviderType: String, CaseIterable, Identifiable {
    case picsum
    
    var id: String { rawValue }
}

