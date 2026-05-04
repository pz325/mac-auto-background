import Foundation

final class RecentStore {
    private let recentKey = "recentImages"
    
    func addRecent(_ url: URL, max: Int) {
        var arr = recent()
        arr.removeAll { $0 == url }
        arr.insert(url, at: 0)
        if arr.count > max { arr = Array(arr.prefix(max)) }
        save(arr, forKey: recentKey)
    }
    
    func recent() -> [URL] {
        let arr = UserDefaults.standard.stringArray(forKey: recentKey) ?? []
        return arr.compactMap { URL(fileURLWithPath: $0) }
    }
    
    private func save(_ urls: [URL], forKey key: String) {
        let arr = urls.map { $0.path }
        UserDefaults.standard.set(arr, forKey: key)
    }
}
