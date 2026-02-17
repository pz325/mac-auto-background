import AppKit

protocol ImageProvider {
    func fetchImage(targetWidth: Int, targetHeight: Int, avoiding hashes: Set<String>, maxAttempts: Int) async throws -> (fileURL: URL, hash: String)
}

final class PicsumProvider: ImageProvider {
    func fetchImage(targetWidth: Int, targetHeight: Int, avoiding hashes: Set<String>, maxAttempts: Int) async throws -> (fileURL: URL, hash: String) {
        for _ in 0..<maxAttempts {
            let url = URL(string: "https://picsum.photos/\(targetWidth)/\(targetHeight).jpg")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let hs = HistoryStore()
            let hash = hs.sha256(of: data)
            if hashes.contains(hash) {
                continue
            }
            let fileURL = try saveImage(data: data, suffix: "jpg")
            return (fileURL, hash)
        }
        throw NSError(domain: "ImageProvider", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch unique image"])
    }
    
    private func saveImage(data: Data, suffix: String) throws -> URL {
        let dir = try ImagesDirectory.url()
        let ts = Int(Date().timeIntervalSince1970)
        let name = "img-\(ts)-\(UUID().uuidString).\(suffix)"
        let file = dir.appendingPathComponent(name)
        try data.write(to: file, options: .atomic)
        return file
    }
}
