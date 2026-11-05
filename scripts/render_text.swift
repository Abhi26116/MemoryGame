// Renders one line of text to a transparent PNG with Core Text, which shapes
// complex scripts (Devanagari conjuncts and matras) that Pillow's basic layout
// gets wrong. Used by build_store_assets_v13.py for Hindi.
//
// Usage: render_text <text> <postscript-font-name> <size> <r> <g> <b> <out.png>

import AppKit

let args = CommandLine.arguments
guard args.count == 8,
      let size = Double(args[3]),
      let r = Double(args[4]), let g = Double(args[5]), let b = Double(args[6]),
      let font = NSFont(name: args[2], size: CGFloat(size)) else {
    FileHandle.standardError.write("usage: render_text text font size r g b out.png\n".data(using: .utf8)!)
    exit(1)
}

let color = NSColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: 1)
let text = NSAttributedString(string: args[1], attributes: [.font: font, .foregroundColor: color])
let bounds = text.size()
let pad = 2
let width = Int(ceil(bounds.width)) + pad * 2
let height = Int(ceil(bounds.height)) + pad * 2

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
) else { exit(1) }
rep.size = NSSize(width: width, height: height)

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
text.draw(at: NSPoint(x: pad, y: pad))
NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else { exit(1) }
try png.write(to: URL(fileURLWithPath: args[7]))
