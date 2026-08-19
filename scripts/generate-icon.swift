#!/usr/bin/env swift
//
// generate-icon.swift
//
// Renders Resources/AppIcon.icns from the cat artwork (Resources/Icons/idle.svg):
// a warm gradient squircle with the typing cat centered on it, exported in all
// required iconset sizes and packed with iconutil.
//
// Run from the repository root:  swift scripts/generate-icon.swift
// (or simply `make icon`)

import AppKit

let fm = FileManager.default
let root = fm.currentDirectoryPath
let svgPath = "\(root)/Resources/Icons/idle.svg"
let iconsetPath = "\(root)/.build/icon/AppIcon.iconset"
let outputPath = "\(root)/Resources/AppIcon.icns"

guard let cat = NSImage(contentsOfFile: svgPath) else {
    fputs("error: cannot load \(svgPath)\n", stderr)
    exit(1)
}

func render(pixels: Int) -> NSBitmapImageRep {
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
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // Squircle-ish background (macOS icon grid: ~824pt art inside 1024pt canvas).
    let inset = s * 0.06
    let bgRect = NSRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: bgRect.width * 0.225, yRadius: bgRect.width * 0.225)

    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 1.00, green: 0.93, blue: 0.80, alpha: 1), // cream
        NSColor(calibratedRed: 1.00, green: 0.70, blue: 0.42, alpha: 1), // warm orange
    ])!
    bgPath.addClip()
    gradient.draw(in: bgRect, angle: -90)

    // Cat, centered, occupying ~68% of the background width, with a soft shadow.
    let catAspect = cat.size.width / cat.size.height
    let catWidth = bgRect.width * 0.68
    let catSize = NSSize(width: catWidth, height: catWidth / catAspect)
    let catRect = NSRect(
        x: bgRect.midX - catSize.width / 2,
        y: bgRect.midY - catSize.height / 2,
        width: catSize.width, height: catSize.height
    )
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
    shadow.shadowBlurRadius = s * 0.012
    shadow.shadowOffset = NSSize(width: 0, height: -s * 0.006)
    shadow.set()
    cat.draw(in: catRect, from: .zero, operation: .sourceOver, fraction: 1)

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let variants: [(pixels: Int, name: String)] = [
    (16, "icon_16x16"), (32, "icon_16x16@2x"),
    (32, "icon_32x32"), (64, "icon_32x32@2x"),
    (128, "icon_128x128"), (256, "icon_128x128@2x"),
    (256, "icon_256x256"), (512, "icon_256x256@2x"),
    (512, "icon_512x512"), (1024, "icon_512x512@2x"),
]

try? fm.removeItem(atPath: iconsetPath)
try fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

for (pixels, name) in variants {
    let rep = render(pixels: pixels)
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
print("Generated \(outputPath)")
