import Foundation
import CryptoKit

struct HistoryStore {
    private let dir: URL
    private let file: URL
    private let queue = DispatchQueue(label: "history.store.queue", qos: .utility)
    
    init(appName: String = "MacAutoBackground") {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        dir = base.appendingPathComponent(appName, isDirectory: true)
        file = dir.appendingPathComponent("history.json")
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
    }
    
    func sha256(of data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func load(maxCount: Int) -> [String] {
        if let data = try? Data(contentsOf: file),
           let arr = try? JSONDecoder().decode([String].self, from: data) {
            return Array(arr.suffix(maxCount))
        }
        return []
    }
    
    func append(_ hash: String, maxCount: Int) {
        queue.async {
            var list = load(maxCount: maxCount)
            list.append(hash)
            if list.count > maxCount {
                list = Array(list.suffix(maxCount))
            }
            if let data = try? JSONEncoder().encode(list) {
                try? data.write(to: file, options: .atomic)
            }
        }
    }
}

