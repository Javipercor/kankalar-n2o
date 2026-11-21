import AppKit

// Native vector drawing, rasterized at every macOS icon resolution.
let output = CommandLine.arguments[1]
try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)

func render(_ pixels: Int) -> Data {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                  bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                  isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let context = NSGraphicsContext.current!.cgContext
    context.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)
    let tile = NSBezierPath(roundedRect: NSRect(x: 52, y: 52, width: 920, height: 920), xRadius: 210, yRadius: 210)
    NSGradient(starting: NSColor(srgbRed: 0.08, green: 0.19, blue: 0.25, alpha: 1),
               ending: NSColor(srgbRed: 0.025, green: 0.05, blue: 0.09, alpha: 1))!.draw(in: tile, angle: -65)
    tile.lineWidth = 3
    NSColor.white.withAlphaComponent(0.16).setStroke()
    tile.stroke()

    // Nitrous bottle silhouette, echoing the app's turquoise accent.
    let bottle = NSBezierPath(roundedRect: NSRect(x: 317, y: 188, width: 390, height: 570), xRadius: 105, yRadius: 105)
    NSGradient(starting: NSColor(srgbRed: 0.22, green: 0.91, blue: 0.75, alpha: 1),
               ending: NSColor(srgbRed: 0.06, green: 0.44, blue: 0.50, alpha: 1))!.draw(in: bottle, angle: 0)
    NSColor(srgbRed: 0.55, green: 0.71, blue: 0.75, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 458, y: 750, width: 108, height: 66), xRadius: 14, yRadius: 14).fill()
    NSColor(srgbRed: 0.36, green: 0.89, blue: 0.76, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 410, y: 808, width: 204, height: 38), xRadius: 16, yRadius: 16).fill()
    NSColor.white.withAlphaComponent(0.22).setFill()
    NSBezierPath(roundedRect: NSRect(x: 345, y: 298, width: 15, height: 343), xRadius: 7, yRadius: 7).fill()
    NSColor(srgbRed: 0.025, green: 0.10, blue: 0.15, alpha: 0.92).setFill()
    NSBezierPath(roundedRect: NSRect(x: 317, y: 360, width: 390, height: 208), xRadius: 0, yRadius: 0).fill()
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    ("N₂O" as NSString).draw(in: NSRect(x: 317, y: 387, width: 390, height: 140), withAttributes: [
        .font: NSFont.systemFont(ofSize: 116, weight: .heavy),
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraph
    ])
    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])!
}

for size in [16, 32, 128, 256, 512] {
    try render(size).write(to: URL(fileURLWithPath: "\(output)/icon_\(size)x\(size).png"))
    try render(size * 2).write(to: URL(fileURLWithPath: "\(output)/icon_\(size)x\(size)@2x.png"))
}
