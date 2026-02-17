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

final class BingProvider: ImageProvider {
    struct Resp: Decodable { let images: [Img] }
    struct Img: Decodable { let url: String }
    func fetchImage(targetWidth: Int, targetHeight: Int, avoiding hashes: Set<String>, maxAttempts: Int) async throws -> (fileURL: URL, hash: String) {
        for _ in 0..<maxAttempts {
            let api = URL(string: "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=zh-CN")!
            let (jdata, _) = try await URLSession.shared.data(from: api)
            let resp = try JSONDecoder().decode(Resp.self, from: jdata)
            guard let rel = resp.images.first?.url else { continue }
            let full = URL(string: "https://www.bing.com\(rel)")!
            let (data, _) = try await URLSession.shared.data(from: full)
            let hs = HistoryStore()
            let hash = hs.sha256(of: data)
            if hashes.contains(hash) { continue }
            let fileURL = try saveImage(data: data, suffix: "jpg")
            return (fileURL, hash)
        }
        throw NSError(domain: "ImageProvider", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch from Bing"])
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

final class UnsplashProvider: ImageProvider {
    func fetchImage(targetWidth: Int, targetHeight: Int, avoiding hashes: Set<String>, maxAttempts: Int) async throws -> (fileURL: URL, hash: String) {
        for _ in 0..<maxAttempts {
            let url = URL(string: "https://source.unsplash.com/random/\(targetWidth)x\(targetHeight)")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let hs = HistoryStore()
            let hash = hs.sha256(of: data)
            if hashes.contains(hash) { continue }
            let fileURL = try saveImage(data: data, suffix: "jpg")
            return (fileURL, hash)
        }
        throw NSError(domain: "ImageProvider", code: -3, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch from Unsplash"])
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

final class AutoProvider: ImageProvider {
    private let providers: [ImageProvider] = [BingProvider(), PicsumProvider(), UnsplashProvider()]
    func fetchImage(targetWidth: Int, targetHeight: Int, avoiding hashes: Set<String>, maxAttempts: Int) async throws -> (fileURL: URL, hash: String) {
        for p in providers {
            do {
                return try await p.fetchImage(targetWidth: targetWidth, targetHeight: targetHeight, avoiding: hashes, maxAttempts: maxAttempts)
            } catch {
                continue
            }
        }
        throw NSError(domain: "ImageProvider", code: -4, userInfo: [NSLocalizedDescriptionKey: "All providers failed"])
    }
}
