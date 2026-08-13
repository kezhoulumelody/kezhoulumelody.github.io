import AppKit
import ImageIO
import UniformTypeIdentifiers

let sourceDir = "/Users/lukezhou/Library/CloudStorage/Box-Box/Kezhou_Lu_2026_UCLA/apply_faculty/FSU/onsite_interview/figures"
let outputDir = "research/figures/land-climate-extremes/mix-length-composite"
let gifPath = "research/figures/land-climate-extremes/mix-length-composite.gif"

try FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

let leftWidth: CGFloat = 760
let rightWidth: CGFloat = 420
let canvasWidth = leftWidth + rightWidth
let frameDelay = 0.18

func attributes(size: CGFloat, color: NSColor, weight: NSFont.Weight = .regular) -> [NSAttributedString.Key: Any] {
    [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color
    ]
}

func drawText(_ text: String, x: CGFloat, y: CGFloat, size: CGFloat, color: NSColor, weight: NSFont.Weight = .regular) {
    text.draw(at: NSPoint(x: x, y: y), withAttributes: attributes(size: size, color: color, weight: weight))
}

func cgImage(from image: NSImage) -> CGImage {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let cg = bitmap.cgImage else {
        fatalError("Could not convert NSImage to CGImage")
    }
    return cg
}

func savePNG(_ image: NSImage, path: String) {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Could not create PNG data")
    }
    try? png.write(to: URL(fileURLWithPath: path))
}

func drawStaticPanel(x panelX: CGFloat, height: CGFloat) {
    NSColor.black.setFill()
    NSBezierPath(rect: NSRect(x: panelX, y: 0, width: rightWidth, height: height)).fill()

    drawText("-alpha T_s'", x: panelX + 68, y: height - 64, size: 28, color: .white, weight: .semibold)
    drawText("(idealized diabatic process)", x: panelX + 36, y: height - 92, size: 17, color: .white)

    drawText("downward eddy-diffusive closure", x: panelX + 94, y: height - 155, size: 16, color: .white)
    drawText("L'", x: panelX + 180, y: height - 245, size: 36, color: .red, weight: .bold)

    let box = NSRect(x: panelX + 25, y: 28, width: rightWidth - 50, height: 86)
    NSColor(calibratedWhite: 1, alpha: 0.95).setFill()
    NSBezierPath(roundedRect: box, xRadius: 8, yRadius: 8).fill()
    NSColor(calibratedRed: 0.08, green: 0.38, blue: 0.65, alpha: 1).setStroke()
    let border = NSBezierPath(roundedRect: box, xRadius: 8, yRadius: 8)
    border.lineWidth = 2
    border.stroke()

    drawText("Physical interpretation of L'", x: panelX + 82, y: 86, size: 17, color: .black, weight: .medium)
    drawText("Stochastic velocity", x: panelX + 42, y: 58, size: 15, color: .red, weight: .medium)
    drawText("amplitude D", x: panelX + 62, y: 38, size: 15, color: .red, weight: .medium)
    drawText("Damping-rate", x: panelX + 272, y: 58, size: 15, color: NSColor(calibratedRed: 0.09, green: 0.42, blue: 0.72, alpha: 1), weight: .medium)
    drawText("amplitude alpha", x: panelX + 250, y: 38, size: 15, color: NSColor(calibratedRed: 0.09, green: 0.42, blue: 0.72, alpha: 1), weight: .medium)

    NSColor.black.setStroke()
    let line = NSBezierPath()
    line.move(to: NSPoint(x: panelX + 190, y: 52))
    line.line(to: NSPoint(x: panelX + 245, y: 52))
    line.lineWidth = 2
    line.stroke()
}

var outputFrames: [NSImage] = []

for index in 0...20 {
    let inputPath = "\(sourceDir)/mix-length-\(index).png"
    guard let source = NSImage(contentsOfFile: inputPath) else {
        fatalError("Missing frame: \(inputPath)")
    }

    let scale = leftWidth / source.size.width
    let leftHeight = source.size.height * scale
    let canvasSize = NSSize(width: canvasWidth, height: leftHeight)
    let image = NSImage(size: canvasSize)

    image.lockFocus()
    NSColor.black.setFill()
    NSBezierPath(rect: NSRect(origin: .zero, size: canvasSize)).fill()
    source.draw(in: NSRect(x: 0, y: 0, width: leftWidth, height: leftHeight),
                from: NSRect(origin: .zero, size: source.size),
                operation: .copy,
                fraction: 1)
    drawStaticPanel(x: leftWidth, height: leftHeight)
    image.unlockFocus()

    let outputPath = String(format: "%@/mix-length-composite-%02d.png", outputDir, index)
    savePNG(image, path: outputPath)
    outputFrames.append(image)
}

let gifURL = URL(fileURLWithPath: gifPath)
guard let destination = CGImageDestinationCreateWithURL(gifURL as CFURL, UTType.gif.identifier as CFString, outputFrames.count, nil) else {
    fatalError("Could not create GIF destination")
}

let gifProperties: [CFString: Any] = [
    kCGImagePropertyGIFDictionary: [
        kCGImagePropertyGIFLoopCount: 0
    ]
]
CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)

let frameProperties: [CFString: Any] = [
    kCGImagePropertyGIFDictionary: [
        kCGImagePropertyGIFDelayTime: frameDelay
    ]
]

for frame in outputFrames {
    CGImageDestinationAddImage(destination, cgImage(from: frame), frameProperties as CFDictionary)
}

if !CGImageDestinationFinalize(destination) {
    fatalError("Could not finalize GIF")
}

print("Wrote \(outputFrames.count) PNG frames to \(outputDir)")
print("Wrote GIF to \(gifPath)")
