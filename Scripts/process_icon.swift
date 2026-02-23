import AppKit
import Foundation

func processIcon(size: CGFloat = 1024, cornerRadius: CGFloat = 0.22, scale: CGFloat = 0.8) -> NSImage {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    
    NSColor.clear.setFill()
    NSBezierPath(rect: rect).fill()
    
    let scaledSize = size * scale
    let scaledRect = NSRect(
        x: (size - scaledSize) / 2,
        y: (size - scaledSize) / 2,
        width: scaledSize,
        height: scaledSize
    )
    
    let cornerRadiusValue = scaledSize * cornerRadius
    let roundedPath = NSBezierPath(roundedRect: scaledRect, xRadius: cornerRadiusValue, yRadius: cornerRadiusValue)
    roundedPath.addClip()
    
    if let sourceImage = NSImage(contentsOfFile: "Scripts/source_icon.png") {
        sourceImage.draw(in: scaledRect)
    }
    
    img.unlockFocus()
    img.isTemplate = false
    return img
}

func writePNG(_ image: NSImage, to url: URL, size: CGFloat) throws {
    let pixels = Int(size)
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "IconGen", code: -2, userInfo: [NSLocalizedDescriptionKey: "Create bitmap rep failed"])
    }
    rep.size = NSSize(width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    if let ctx = NSGraphicsContext(bitmapImageRep: rep) {
        NSGraphicsContext.current = ctx
        NSColor.clear.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()
        image.draw(in: NSRect(x: 0, y: 0, width: size, height: size), from: .zero, operation: .copy, fraction: 1)
        ctx.flushGraphics()
    }
    NSGraphicsContext.restoreGraphicsState()
    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconGen", code: -3, userInfo: [NSLocalizedDescriptionKey: "PNG encode failed"])
    }
    try data.write(to: url)
}

let fm = FileManager.default
let base = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let appiconPath = base.appendingPathComponent("Sources/MacAutoBackground/Resources/Assets.xcassets/AppIcon.appiconset")
let iconsetPath = base.appendingPathComponent("Sources/MacAutoBackground/Resources/AppIcon.iconset")
try? fm.createDirectory(at: appiconPath, withIntermediateDirectories: true)
try? fm.createDirectory(at: iconsetPath, withIntermediateDirectories: true)

let image = processIcon(size: 1024, cornerRadius: 0.22, scale: 0.8)

let entries: [(String, CGFloat)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024)
]

for (name, s) in entries {
    let dst1 = appiconPath.appendingPathComponent(name)
    let dst2 = iconsetPath.appendingPathComponent(name)
    try writePNG(image, to: dst1, size: s)
    try writePNG(image, to: dst2, size: s)
}

let proc = Process()
proc.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
proc.arguments = ["-c", "icns", iconsetPath.path, "-o", base.appendingPathComponent("Sources/MacAutoBackground/Resources/AppIcon.icns").path]
try proc.run()
proc.waitUntilExit()
guard proc.terminationStatus == 0 else {
    throw NSError(domain: "IconGen", code: Int(proc.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "iconutil failed"])
}

print("AppIcon.appiconset and AppIcon.icns generated with rounded corners and scaled")
