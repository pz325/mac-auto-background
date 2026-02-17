import AppKit

enum IconGenerator {
    static func makeIcon(size: CGFloat = 1024) -> NSImage {
        let img = NSImage(size: NSSize(width: size, height: size))
        img.lockFocus()
        let rect = NSRect(x: 0, y: 0, width: size, height: size)
        
        let gradientTop = NSColor(calibratedRed: 0.22, green: 0.63, blue: 0.98, alpha: 1)
        let gradientBottom = NSColor(calibratedRed: 0.09, green: 0.43, blue: 0.84, alpha: 1)
        let gradient = NSGradient(starting: gradientTop, ending: gradientBottom)
        NSBezierPath(roundedRect: rect, xRadius: size * 0.22, yRadius: size * 0.22).addClip()
        gradient?.draw(in: rect, angle: -90)
        
        let inset = rect.insetBy(dx: size * 0.12, dy: size * 0.18)
        
        let sunCenter = NSPoint(x: inset.midX + size * 0.16, y: inset.midY + size * 0.18)
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
    
    static func makeStatusIcon(size: CGFloat = 18) -> NSImage {
        let img = NSImage(size: NSSize(width: size, height: size))
        img.lockFocus()
        let rect = NSRect(x: 0, y: 0, width: size, height: size)
        NSColor.clear.setFill()
        NSBezierPath(rect: rect).fill()
        NSColor.black.setFill()
        let baseY = size * 0.25
        let path = NSBezierPath()
        path.move(to: NSPoint(x: size * 0.1, y: baseY))
        path.line(to: NSPoint(x: size * 0.4, y: baseY + size * 0.35))
        path.line(to: NSPoint(x: size * 0.55, y: baseY + size * 0.2))
        path.line(to: NSPoint(x: size * 0.8, y: baseY))
        path.line(to: NSPoint(x: size * 0.9, y: baseY))
        path.line(to: NSPoint(x: size * 0.9, y: size * 0.1))
        path.line(to: NSPoint(x: size * 0.1, y: size * 0.1))
        path.close()
        path.fill()
        let sunR = size * 0.12
        let sun = NSRect(x: size * 0.6, y: size * 0.6, width: sunR, height: sunR)
        NSBezierPath(ovalIn: sun).fill()
        img.unlockFocus()
        img.isTemplate = true
        return img
    }
}
