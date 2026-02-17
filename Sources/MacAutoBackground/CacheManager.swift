import Foundation

enum CacheManager {
    static func cleanupImagesIfNeeded(maxBytes: Int64, excluding keepURL: URL?) {
        guard let dir = try? ImagesDirectory.url() else { return }
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .creationDateKey], options: [.skipsHiddenFiles]) else {
            return
        }
        var fileInfos: [(url: URL, size: Int64, date: Date)] = []
        var total: Int64 = 0
        for url in items {
            if url == keepURL { continue }
            do {
                let rsrc = try url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey, .creationDateKey])
                let size = Int64(rsrc.fileSize ?? 0)
                let date = rsrc.contentModificationDate ?? rsrc.creationDate ?? Date.distantPast
                fileInfos.append((url, size, date))
                total += size
            } catch {
                continue
            }
        }
        if total <= maxBytes { return }
        fileInfos.sort { $0.date < $1.date } // oldest first
        let target = Int64(Double(maxBytes) * 0.9) // clean down to 90% to avoid thrashing
        for info in fileInfos {
            if total <= target { break }
            do {
                try fm.removeItem(at: info.url)
                total -= info.size
            } catch {
                continue
            }
        }
    }
}

