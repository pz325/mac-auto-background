import AppKit
import Foundation

func makeIcon(size: CGFloat = 1024) -> NSImage {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let outerInset = size * 0.08
    let bgRect = rect.insetBy(dx: outerInset, dy: outerInset)
    let gradientTop = NSColor(calibratedRed: 0.22, green: 0.63, blue: 0.98, alpha: 1)
    let gradientBottom = NSColor(calibratedRed: 0.09, green: 0.43, blue: 0.84, alpha: 1)
    let gradient = NSGradient(starting: gradientTop, ending: gradientBottom)
    NSBezierPath(roundedRect: bgRect, xRadius: size * 0.22, yRadius: size * 0.22).addClip()
    gradient?.draw(in: bgRect, angle: -90)
    let inset = bgRect.insetBy(dx: size * 0.12, dy: size * 0.18)
    let sunCenter = NSPoint(x: inset.midX + size * 0.18, y: inset.midY + size * 0.18)
    let sunRadius = size * 0.08
    NSColor(calibratedRed: 1, green: 0.89, blue: 0.45, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: sunCenter.x - sunRadius, y: sunCenter.y - sunRadius, width: sunRadius * 2, height: sunRadius * 2)).fill()
    let mountainPath = NSBezierPath()
    let baseY = inset.minY + size * 0.18
    mountainPath.move(to: NSPoint(x: inset.minX, y: baseY))
    mountainPath.line(to: NSPoint(x: inset.minX + size * 0.22, y: baseY + size * 0.18))
    mountainPath.line(to: NSPoint(x: inset.minX + size * 0.34, y: baseY + size * 0.1))
    mountainPath.line(to: NSPoint(x: inset.minX + size * 0.5, y: baseY + size * 0.28))
    mountainPath.line(to: NSPoint(x: inset.minX + size * 0.72, y: baseY))
    mountainPath.line(to: NSPoint(x: inset.maxX, y: baseY))
    mountainPath.line(to: NSPoint(x: inset.maxX, y: inset.minY))
    mountainPath.line(to: NSPoint(x: inset.minX, y: inset.minY))
    mountainPath.close()
    NSColor(calibratedRed: 0.16, green: 0.62, blue: 0.49, alpha: 1).setFill()
    mountainPath.fill()
    let monitorRect = NSRect(x: inset.minX + size * 0.08, y: inset.minY + size * 0.42, width: inset.width - size * 0.16, height: size * 0.28)
    NSColor(calibratedWhite: 1, alpha: 0.25).setStroke()
    let monitorPath = NSBezierPath(roundedRect: monitorRect, xRadius: size * 0.03, yRadius: size * 0.03)
    monitorPath.lineWidth = size * 0.018
    monitorPath.stroke()
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
    rep.size = NSSize(width: size, height: size) // point size for consistency
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

let image = makeIcon(size: 1024)

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

print("AppIcon.appiconset and AppIcon.icns generated")
