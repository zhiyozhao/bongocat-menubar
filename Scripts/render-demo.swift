#!/usr/bin/env swift
//
// render-demo.swift
//
// Renders the README demo images from the real menu bar artwork in
// Resources/Icons/*.svg — no screen capture involved.
//
// Output (docs/assets/):
//   demo-light.png / demo-dark.png   static: the four frames on a mock menu bar
//   demo-light.gif / demo-dark.gif   animated: Follow Hands mode, keys F / J
//
// Usage (from repo root):  swift Scripts/render-demo.swift   (or: make demo)

import AppKit
import ImageIO
import UniformTypeIdentifiers

let root = FileManager.default.currentDirectoryPath
let iconsDir = "\(root)/Resources/Icons"
let outDir = "\(root)/docs/assets"
try FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

// MARK: - Theme

struct Theme {
    let name: String
    let bar: NSColor        // menu bar background
    let fg: NSColor         // menu bar glyphs (template tint)
    let page: NSColor       // area below the bar
    let keyFill: NSColor
    let keyStroke: NSColor
    let keyText: NSColor
}

let light = Theme(
    name: "light",
    bar: NSColor(srgbRed: 0.93, green: 0.93, blue: 0.94, alpha: 1),
    fg: NSColor(srgbRed: 0.11, green: 0.11, blue: 0.12, alpha: 1),
    page: NSColor(srgbRed: 0.98, green: 0.98, blue: 0.98, alpha: 1),
    keyFill: .white,
    keyStroke: NSColor(white: 0.78, alpha: 1),
    keyText: NSColor(white: 0.25, alpha: 1)
)

let dark = Theme(
    name: "dark",
    bar: NSColor(srgbRed: 0.16, green: 0.16, blue: 0.17, alpha: 1),
    fg: NSColor(srgbRed: 0.96, green: 0.96, blue: 0.97, alpha: 1),
    page: NSColor(srgbRed: 0.09, green: 0.09, blue: 0.10, alpha: 1),
    keyFill: NSColor(white: 0.17, alpha: 1),
    keyStroke: NSColor(white: 0.30, alpha: 1),
    keyText: NSColor(white: 0.80, alpha: 1)
)

// MARK: - Drawing helpers

func loadFrame(_ name: String) -> NSImage {
    guard let image = NSImage(contentsOfFile: "\(iconsDir)/\(name).svg") else {
        fputs("error: cannot load \(iconsDir)/\(name).svg\n", stderr)
        exit(1)
    }
    return image
}

let frames = Dictionary(uniqueKeysWithValues:
    ["idle", "typing_a", "typing_b", "typing_both"].map { ($0, loadFrame($0)) })

/// Draws a template image tinted with `color`, the way the menu bar renders it.
func drawTemplate(_ image: NSImage, in rect: NSRect, color: NSColor) {
    let tinted = NSImage(size: rect.size, flipped: false) { r in
        image.draw(in: r, from: .zero, operation: .sourceOver, fraction: 1)
        color.set()
        r.fill(using: .sourceAtop)
        return true
    }
    tinted.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
}

func drawSymbol(_ name: String, at origin: NSPoint, height: CGFloat, color: NSColor) -> CGFloat {
    let config = NSImage.SymbolConfiguration(pointSize: height, weight: .regular)
    guard let symbol = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
        .withSymbolConfiguration(config) else { return 0 }
    let size = symbol.size
    drawTemplate(symbol, in: NSRect(origin: NSPoint(x: origin.x, y: origin.y - size.height / 2), size: size), color: color)
    return size.width
}

func drawText(_ text: String, at point: NSPoint, size: CGFloat, color: NSColor, weight: NSFont.Weight = .medium, centered: Bool = false) {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
    ]
    let str = NSAttributedString(string: text, attributes: attrs)
    let s = str.size()
    let x = centered ? point.x - s.width / 2 : point.x
    str.draw(at: NSPoint(x: x, y: point.y - s.height / 2))
}

func render(width: Int, height: Int, scale: CGFloat, _ draw: () -> Void) -> CGImage {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(CGFloat(width) * scale), pixelsHigh: Int(CGFloat(height) * scale),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: width, height: height)
    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    ctx.imageInterpolation = .high
    NSGraphicsContext.current = ctx
    draw()
    NSGraphicsContext.restoreGraphicsState()
    return rep.cgImage!
}

// MARK: - Scene pieces

/// Magnification of the menu bar so the 16pt cat is readable in a README.
let zoom: CGFloat = 2.5
let barHeight: CGFloat = 24 * zoom
let catSize = NSSize(width: 16 * 89.0 / 51.0 * zoom, height: 16 * zoom)

/// A slice of the right side of the menu bar: [cat] [wifi] [battery] [clock].
/// Returns the cat rect so callers can align things under it.
@discardableResult
func drawMenuBar(width: CGFloat, top: CGFloat, frame: String, theme: Theme) -> NSRect {
    let y = top - barHeight
    theme.bar.setFill()
    NSRect(x: 0, y: y, width: width, height: barHeight).fill()

    let mid = y + barHeight / 2
    let glyph: CGFloat = 13 * zoom
    var x = width - 20 * zoom

    // Clock (right-aligned)
    let clock = NSAttributedString(string: "12:14", attributes: [.font: NSFont.systemFont(ofSize: glyph, weight: .medium)])
    x -= clock.size().width
    drawText("12:14", at: NSPoint(x: x, y: mid), size: glyph, color: theme.fg)
    x -= 14 * zoom

    let battery = NSImage(systemSymbolName: "battery.75percent", accessibilityDescription: nil)!
        .withSymbolConfiguration(.init(pointSize: glyph, weight: .regular))!
    x -= battery.size.width
    _ = drawSymbol("battery.75percent", at: NSPoint(x: x, y: mid), height: glyph, color: theme.fg)
    x -= 14 * zoom

    let wifi = NSImage(systemSymbolName: "wifi", accessibilityDescription: nil)!
        .withSymbolConfiguration(.init(pointSize: glyph, weight: .regular))!
    x -= wifi.size.width
    _ = drawSymbol("wifi", at: NSPoint(x: x, y: mid), height: glyph, color: theme.fg)
    x -= 14 * zoom

    x -= catSize.width
    let catRect = NSRect(x: x, y: mid - catSize.height / 2, width: catSize.width, height: catSize.height)
    drawTemplate(frames[frame]!, in: catRect, color: theme.fg)
    return catRect
}

/// Two small key groups (left hand / right hand); pressed keys are inverted.
func drawKeys(centerX: CGFloat, centerY: CGFloat, pressed: Set<String>, theme: Theme) {
    let left = ["A", "S", "D", "F"]
    let right = ["J", "K", "L", ";"]
    let key: CGFloat = 34, gap: CGFloat = 6, groupGap: CGFloat = 40
    let groupWidth = CGFloat(left.count) * key + CGFloat(left.count - 1) * gap
    let total = groupWidth * 2 + groupGap
    var x = centerX - total / 2

    func cap(_ label: String) {
        let r = NSRect(x: x, y: centerY - key / 2, width: key, height: key)
        let path = NSBezierPath(roundedRect: r, xRadius: 6, yRadius: 6)
        let down = pressed.contains(label)
        (down ? theme.fg : theme.keyFill).setFill()
        path.fill()
        path.lineWidth = 1
        (down ? theme.fg : theme.keyStroke).setStroke()
        path.stroke()
        drawText(label, at: NSPoint(x: r.midX, y: r.midY), size: 15, color: down ? theme.page : theme.keyText, centered: true)
        x += key + gap
    }
    left.forEach(cap)
    x += groupGap - gap
    right.forEach(cap)
}

// MARK: - Static image: four frames

func renderStatic(_ theme: Theme) -> CGImage {
    let width = 960, height = 270
    return render(width: width, height: height, scale: 2) {
        theme.page.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        drawMenuBar(width: CGFloat(width), top: CGFloat(height), frame: "typing_both", theme: theme)

        let cells: [(frame: String, caption: String)] = [
            ("idle", "—"), ("typing_a", "F"), ("typing_b", "J"), ("typing_both", "F + J"),
        ]
        let cellW = CGFloat(width) / CGFloat(cells.count)
        let big = NSSize(width: catSize.width * 1.4, height: catSize.height * 1.4)
        for (i, cell) in cells.enumerated() {
            let cx = cellW * (CGFloat(i) + 0.5)
            let rect = NSRect(x: cx - big.width / 2, y: 95, width: big.width, height: big.height)
            drawTemplate(frames[cell.frame]!, in: rect, color: theme.fg)
            // Key hint only, so one image serves both the Chinese and English README.
            drawText(cell.caption, at: NSPoint(x: cx, y: 62), size: 20, color: theme.keyText, weight: .semibold, centered: true)
        }
    }
}

// MARK: - Animated GIF: Follow Hands mode

/// (frame, pressed keys, duration in seconds)
let script: [(String, Set<String>, Double)] = [
    ("idle", [], 0.8),
    ("typing_a", ["F"], 0.16), ("idle", [], 0.10),
    ("typing_b", ["J"], 0.16), ("idle", [], 0.10),
    ("typing_a", ["D"], 0.14), ("idle", [], 0.08),
    ("typing_b", ["K"], 0.14), ("idle", [], 0.08),
    ("typing_a", ["S"], 0.12), ("typing_b", ["L"], 0.12),
    ("typing_a", ["A"], 0.12), ("typing_b", [";"], 0.12),
    ("idle", [], 0.30),
    ("typing_a", ["F"], 0.20), ("typing_both", ["F", "J"], 0.60),
    ("typing_b", ["J"], 0.20), ("idle", [], 1.0),
]

func renderGIFFrame(_ theme: Theme, frame: String, pressed: Set<String>) -> CGImage {
    let width = 640, height = 150
    return render(width: width, height: height, scale: 2) {
        theme.page.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        drawMenuBar(width: CGFloat(width), top: CGFloat(height), frame: frame, theme: theme)
        drawKeys(centerX: CGFloat(width) / 2, centerY: 45, pressed: pressed, theme: theme)
    }
}

func writePNG(_ image: CGImage, to path: String) throws {
    let rep = NSBitmapImageRep(cgImage: image)
    try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}

func writeGIF(_ images: [(CGImage, Double)], to path: String) {
    let url = URL(fileURLWithPath: path) as CFURL
    guard let dest = CGImageDestinationCreateWithURL(url, UTType.gif.identifier as CFString, images.count, nil) else {
        fputs("error: cannot create \(path)\n", stderr)
        exit(1)
    }
    CGImageDestinationSetProperties(dest, [
        kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0],
    ] as CFDictionary)
    for (image, delay) in images {
        CGImageDestinationAddImage(dest, image, [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFDelayTime: delay,
                kCGImagePropertyGIFUnclampedDelayTime: delay,
            ],
        ] as CFDictionary)
    }
    guard CGImageDestinationFinalize(dest) else {
        fputs("error: failed to write \(path)\n", stderr)
        exit(1)
    }
}

for theme in [light, dark] {
    let png = "\(outDir)/demo-\(theme.name).png"
    try writePNG(renderStatic(theme), to: png)
    let gif = "\(outDir)/demo-\(theme.name).gif"
    writeGIF(script.map { (renderGIFFrame(theme, frame: $0.0, pressed: $0.1), $0.2) }, to: gif)
    print("wrote \(png)\nwrote \(gif)")
}
