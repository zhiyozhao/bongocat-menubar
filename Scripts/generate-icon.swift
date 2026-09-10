#!/usr/bin/env swift
//
// generate-icon.swift
//
// Renders Resources/AppIcon.icns from the cat artwork (Resources/Icons/idle.svg).
//
// Design follows Apple's macOS icon best practices:
//   - 1024x1024 canvas with the squircle drawn by us (macOS does NOT mask app
//     icons): 824x824 centered, corner radius 185.4/824 of the squircle side.
//   - Bold, smooth strokes: the SVG is a traced path with jagged edges, so the
//     cat is rendered at 4x, Gaussian-blurred and re-thresholded, which rounds
//     and evens out the stroke geometry.
//   - Pure black & white, primary content centered.
//
// Usage (from repo root):  swift scripts/generate-icon.swift [light|dark]
//   light = black cat on white squircle (default, classic BongoCat)
//   dark  = white cat on black squircle
//
// Both variants are also exported to .build/icon/preview-{light,dark}.png
// for visual inspection.

import AppKit
import CoreImage

let fm = FileManager.default
let root = fm.currentDirectoryPath
let svgPath = "\(root)/Resources/Icons/typing_both.svg"
let workDir = "\(root)/.build/icon"
let iconsetPath = "\(workDir)/AppIcon.iconset"
let outputPath = "\(root)/Resources/AppIcon.icns"

let style = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "light"
guard style == "light" || style == "dark" else {
    fputs("usage: generate-icon.swift [light|dark]\n", stderr)
    exit(1)
}

guard let cat = NSImage(contentsOfFile: svgPath) else {
    fputs("error: cannot load \(svgPath)\n", stderr)
    exit(1)
}

// MARK: - Master artwork (rendered once at 4x, smoothed)

let MASTER = 4096
// Squircle geometry per Apple's macOS icon grid: 824pt inside 1024pt.
let squircleInset = Double(MASTER) * (1024.0 - 824.0) / 2.0 / 1024.0
let squircleSize = Double(MASTER) - squircleInset * 2

func masterArtwork() -> CGImage {
    // Render the cat large, then crop to its actual content bounds — the SVG
    // viewBox has dead space at the bottom (~27% of height), which otherwise
    // makes the cat appear small and shifted up.
    let probeW = 2400
    let probeH = probeW * Int(cat.size.height) / Int(cat.size.width)
    let probe = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: probeW, pixelsHigh: probeH,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: probe)
    cat.draw(in: NSRect(x: 0, y: 0, width: probeW, height: probeH), from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()

    var minX = probeW, maxX = 0, minY = probeH, maxY = 0 // y=0 is the top row
    for y in 0..<probeH { for x in 0..<probeW {
        if probe.colorAt(x: x, y: y)!.alphaComponent > 0.1 {
            minX = min(minX, x); maxX = max(maxX, x)
            minY = min(minY, y); maxY = max(maxY, y)
        }
    }}
    let contentW = maxX - minX + 1, contentH = maxY - minY + 1
    guard let cropped = probe.cgImage!.cropping(to: CGRect(x: minX, y: minY, width: contentW, height: contentH)) else {
        fputs("error: failed to crop cat artwork\n", stderr)
        exit(1)
    }
    let catImage = NSImage(cgImage: cropped, size: NSSize(width: contentW, height: contentH))
    let catAspect = Double(contentW) / Double(contentH)

    // Cat size/placement: ~86% of the squircle width, centered.
    let catWidth = squircleSize * 0.86
    let catRect = NSRect(
        x: Double(MASTER) / 2 - catWidth / 2,
        y: Double(MASTER) / 2 - catWidth / catAspect / 2,
        width: catWidth, height: catWidth / catAspect
    )

    // Flatten: black cat on solid white.
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: MASTER, pixelsHigh: MASTER,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSColor.white.setFill()
    NSRect(x: 0, y: 0, width: MASTER, height: MASTER).fill()
    catImage.draw(in: catRect, from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()

    // Smooth: blur then re-threshold. The threshold is slightly above 0.5 to
    // keep strokes bold (HIG: avoid thin lines).
    var ci = CIImage(bitmapImageRep: rep)!
    ci = ci.applyingGaussianBlur(sigma: Double(MASTER) * 0.0055)
    ci = CIFilter(name: "CIColorThreshold", parameters: [
        kCIInputImageKey: ci, "inputThreshold": 0.55,
    ])!.outputImage!
    if style == "dark" {
        ci = CIFilter(name: "CIColorInvert", parameters: [
            kCIInputImageKey: ci,
        ])!.outputImage!
    }

    let context = CIContext()
    return context.createCGImage(ci, from: ci.extent)!
}

// MARK: - Icon rendering

func renderIcon(artwork: CGImage, pixels: Int) -> NSBitmapImageRep {
    let s = CGFloat(pixels)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: s, height: s)

    NSGraphicsContext.saveGraphicsState()
    let g = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = g
    g.imageInterpolation = .high

    let inset = s * (1024.0 - 824.0) / 2.0 / 1024.0
    let bgRect = NSRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let cornerRadius = bgRect.width * (185.4 / 824.0)
    NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius).addClip()

    NSImage(cgImage: artwork, size: NSSize(width: s, height: s))
        .draw(in: NSRect(x: 0, y: 0, width: s, height: s), from: .zero, operation: .sourceOver, fraction: 1)

    // Hairline around the squircle so a white icon stays defined on light
    // backgrounds at small sizes (barely visible at large sizes).
    if style == "light" {
        let hairline = NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius)
        hairline.lineWidth = max(1, s * 0.004)
        NSColor.black.withAlphaComponent(pixels <= 64 ? 0.35 : 0.12).setStroke()
        hairline.stroke()
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

// MARK: - Output

let variants: [(pixels: Int, name: String)] = [
    (16, "icon_16x16"), (32, "icon_16x16@2x"),
    (32, "icon_32x32"), (64, "icon_32x32@2x"),
    (128, "icon_128x128"), (256, "icon_128x128@2x"),
    (256, "icon_256x256"), (512, "icon_256x256@2x"),
    (512, "icon_512x512"), (1024, "icon_512x512@2x"),
]

try fm.createDirectory(atPath: workDir, withIntermediateDirectories: true)

let artwork = masterArtwork()

let preview = renderIcon(artwork: artwork, pixels: 1024)
try preview.representation(using: .png, properties: [:])!
    .write(to: URL(fileURLWithPath: "\(workDir)/preview-\(style).png"))

try? fm.removeItem(atPath: iconsetPath)
try fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)
for (pixels, name) in variants {
    let rep = renderIcon(artwork: artwork, pixels: pixels)
    guard let png = rep.representation(using: .png, properties: [:]) else {
        fputs("error: failed to encode \(name)\n", stderr)
        exit(1)
    }
    try png.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(name).png"))
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconsetPath, "-o", outputPath]
try iconutil.run()
iconutil.waitUntilExit()
guard iconutil.terminationStatus == 0 else {
    fputs("error: iconutil failed (\(iconutil.terminationStatus))\n", stderr)
    exit(1)
}

try? fm.removeItem(atPath: iconsetPath)
print("Generated \(outputPath) (style: \(style), preview: .build/icon/preview-\(style).png)")
