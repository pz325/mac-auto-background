import Foundation

final class RecentFavoritesStore {
    private let recentKey = "recentImages"
    private let favKey = "favoriteImages"
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
    func toggleFavorite(_ url: URL) {
        var set = Set(favorites().map { $0.path })
        if set.contains(url.path) {
            set.remove(url.path)
        } else {
            set.insert(url.path)
        }
        let arr = Array(set).sorted()
        UserDefaults.standard.set(arr, forKey: favKey)
    }
    func isFavorite(_ url: URL?) -> Bool {
        guard let u = url else { return false }
        let set = Set(UserDefaults.standard.stringArray(forKey: favKey) ?? [])
        return set.contains(u.path)
    }
    func favorites() -> [URL] {
        let arr = UserDefaults.standard.stringArray(forKey: favKey) ?? []
        return arr.compactMap { URL(fileURLWithPath: $0) }
    }
    private func save(_ urls: [URL], forKey key: String) {
        let arr = urls.map { $0.path }
        UserDefaults.standard.set(arr, forKey: key)
    }
}
