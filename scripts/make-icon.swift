// Original Clipline icon: a white clipboard on a teal rounded square.
import AppKit

let out = CommandLine.arguments[1]
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024,
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                           isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let body = NSBezierPath(roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824), xRadius: 180, yRadius: 180)
NSColor(srgbRed: 0.10, green: 0.57, blue: 0.49, alpha: 1).setFill()
body.fill()
let paper = NSBezierPath(roundedRect: NSRect(x: 292, y: 248, width: 440, height: 526), xRadius: 44, yRadius: 44)
NSColor.white.setFill()
paper.fill()
NSColor(srgbRed: 0.72, green: 0.92, blue: 0.85, alpha: 1).setFill()
NSBezierPath(roundedRect: NSRect(x: 412, y: 728, width: 200, height: 88), xRadius: 24, yRadius: 24).fill()
NSColor(srgbRed: 0.10, green: 0.57, blue: 0.49, alpha: 1).setStroke()
let line = NSBezierPath()
line.move(to: NSPoint(x: 354, y: 628))
line.curve(to: NSPoint(x: 670, y: 628), controlPoint1: NSPoint(x: 440, y: 572), controlPoint2: NSPoint(x: 584, y: 572))
line.lineWidth = 12
line.stroke()
NSColor(srgbRed: 0.98, green: 0.76, blue: 0.26, alpha: 1).setFill()
NSBezierPath(roundedRect: NSRect(x: 438, y: 392, width: 152, height: 176), xRadius: 12, yRadius: 12).fill()
NSColor(srgbRed: 0.10, green: 0.57, blue: 0.49, alpha: 1).setFill()
NSBezierPath(roundedRect: NSRect(x: 496, y: 548, width: 36, height: 70), xRadius: 8, yRadius: 8).fill()
NSGraphicsContext.restoreGraphicsState()
try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
