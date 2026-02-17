import AppKit

final class WallpaperChanger {
    func setWallpaper(url: URL, on screens: [NSScreen]) throws {
        for screen in screens {
            try NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: [:])
        }
    }
}

