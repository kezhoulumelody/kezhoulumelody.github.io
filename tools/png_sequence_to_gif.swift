import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let inputDir = root.appendingPathComponent("research/figures/land-climate-extremes/mix-length-composite/mixing-length-composites")
let outputURL = root.appendingPathComponent("research/figures/land-climate-extremes/mix-length-composite.gif")
let frameDelay = 0.18

let files = try FileManager.default.contentsOfDirectory(at: inputDir, includingPropertiesForKeys: nil)
    .filter { $0.pathExtension.lowercased() == "png" && $0.lastPathComponent.hasPrefix("composite-mix-length-") }
    .sorted {
        frameNumber($0.lastPathComponent) < frameNumber($1.lastPathComponent)
    }

func frameNumber(_ filename: String) -> Int {
    let stem = filename.replacingOccurrences(of: ".png", with: "")
    return Int(stem.components(separatedBy: "-").last ?? "") ?? Int.max
}

guard !files.isEmpty else {
    fatalError("No composite PNG frames found in \(inputDir.path)")
}

guard
    let destination = CGImageDestinationCreateWithURL(
        outputURL as CFURL,
        UTType.gif.identifier as CFString,
        files.count,
        nil
    )
else {
    fatalError("Could not create GIF destination at \(outputURL.path)")
}

let gifProperties: [CFString: Any] = [
    kCGImagePropertyGIFDictionary: [
        kCGImagePropertyGIFLoopCount: 0
    ]
]

let frameProperties: [CFString: Any] = [
    kCGImagePropertyGIFDictionary: [
        kCGImagePropertyGIFDelayTime: frameDelay
    ]
]

CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)

for file in files {
    guard let image = NSImage(contentsOf: file) else {
        fatalError("Could not open image \(file.path)")
    }

    var rect = NSRect(origin: .zero, size: image.size)
    guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
        fatalError("Could not create CGImage for \(file.path)")
    }

    CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)
}

guard CGImageDestinationFinalize(destination) else {
    fatalError("Could not finalize GIF at \(outputURL.path)")
}

print("Wrote \(files.count) frames to \(outputURL.path)")
