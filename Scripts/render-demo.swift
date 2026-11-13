#!/usr/bin/env swift
//
// render-demo.swift
//
// Renders the README demo images from the real menu bar artwork in
// Resources/Icons/*.svg — no screen capture involved.
//
// Output (docs/assets/):
//   demo-light.png / demo-dark.png   static: the four frames on a mock menu bar
//   demo-light.gif / demo-dark.gif   animated: Follow Mode while typing "bongo cat"
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
let catSize = NSSize(width: 16 * 89.0 / 51.0 * zoom, height: 16 * zoom)

/// A slice of the right side of the menu bar: [cat] [wifi] [battery] [clock].
/// Returns the cat rect so callers can align things under it.
@discardableResult
func drawMenuBar(width: CGFloat, top: CGFloat, frame: String, theme: Theme, zoom: CGFloat = zoom) -> NSRect {
    let barHeight = 24 * zoom
    let catSize = NSSize(width: 16 * 89.0 / 51.0 * zoom, height: 16 * zoom)
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

// MARK: - Animated GIF: Follow Mode while typing

/// Keyboard rows; the first five keys of each row belong to the left hand
/// (same split as KeyMap). Space is a right-hand key in the app.
let rows: [[String]] = [
    ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
    ["A", "S", "D", "F", "G", "H", "J", "K", "L", ";"],
    ["Z", "X", "C", "V", "B", "N", "M", ",", ".", "/"],
]
let rightHandKeys: Set<String> = Set(rows.flatMap { $0.dropFirst(5) }).union([" "])

/// Draws a small keyboard; the two hands are split by a gap, pressed keys are inverted.
func drawKeyboard(centerX: CGFloat, top: CGFloat, pressed: Set<String>, theme: Theme) {
    let key: CGFloat = 30, gap: CGFloat = 5, split: CGFloat = 18
    let unit = key + gap
    let rowWidth = CGFloat(rows[0].count) * unit - gap + split
    let left = centerX - (rowWidth + 0.75 * unit) / 2
    let stagger: [CGFloat] = [0, 0.25 * unit, 0.75 * unit]

    func cap(_ r: NSRect, _ label: String, down: Bool) {
        let path = NSBezierPath(roundedRect: r, xRadius: 6, yRadius: 6)
        (down ? theme.fg : theme.keyFill).setFill()
        path.fill()
        path.lineWidth = 1
        (down ? theme.fg : theme.keyStroke).setStroke()
        path.stroke()
        if !label.isEmpty {
            drawText(label, at: NSPoint(x: r.midX, y: r.midY), size: 13, color: down ? theme.page : theme.keyText, centered: true)
        }
    }

    for (i, row) in rows.enumerated() {
        let y = top - CGFloat(i) * unit - key
        for (j, label) in row.enumerated() {
            let x = left + stagger[i] + CGFloat(j) * unit + (j >= 5 ? split : 0)
            cap(NSRect(x: x, y: y, width: key, height: key), label, down: pressed.contains(label))
        }
    }
    // Space bar under C ... M
    let y = top - 3 * unit - key
    let x0 = left + stagger[2] + 2 * unit
    let x1 = left + stagger[2] + 6 * unit + split + key
    cap(NSRect(x: x0, y: y, width: x1 - x0, height: key), "", down: pressed.contains(" "))
}

/// One keystroke: key label, time it goes down, time it comes up (seconds).
struct Stroke { let key: String; let down: Double; let up: Double }

/// Typing "bongo cat" at a natural pace. "g" and "o" overlap briefly, like real
/// rolling keystrokes, so both paws come down for a moment.
let strokes: [Stroke] = [
    .init(key: "B", down: 0.90, up: 1.00),
    .init(key: "O", down: 1.08, up: 1.17),
    .init(key: "N", down: 1.24, up: 1.33),
    .init(key: "G", down: 1.40, up: 1.52),
    .init(key: "O", down: 1.46, up: 1.58),
    .init(key: " ", down: 1.72, up: 1.81),
    .init(key: "C", down: 1.92, up: 2.02),
    .init(key: "A", down: 2.08, up: 2.17),
    .init(key: "T", down: 2.24, up: 2.36),
]
let loopLength = 4.0

struct Shot { let frame: String; let pressed: Set<String>; let typed: String; let duration: Double }

/// Turns the keystrokes into GIF frames with the app's Follow Mode rule:
/// a paw is down while any key on its side is held.
func timeline() -> [Shot] {
    var times = Set([0.0, loopLength])
    strokes.forEach { times.insert($0.down); times.insert($0.up) }
    let sorted = times.sorted()
    var shots: [Shot] = []
    for (t, next) in zip(sorted, sorted.dropFirst()) {
        let held = strokes.filter { $0.down <= t && t < $0.up }.map(\.key)
        let leftDown = held.contains { !rightHandKeys.contains($0) }
        let rightDown = held.contains { rightHandKeys.contains($0) }
        let frame: String
        switch (leftDown, rightDown) {
        case (true, true): frame = "typing_both"
        case (true, false): frame = "typing_a"
        case (false, true): frame = "typing_b"
        default: frame = "idle"
        }
        let typed = strokes.filter { $0.down <= t }.map { $0.key.lowercased() }.joined()
        shots.append(Shot(frame: frame, pressed: Set(held), typed: typed, duration: next - t))
    }
    return shots
}

func renderGIFFrame(_ theme: Theme, _ shot: Shot) -> CGImage {
    let width = 720, height = 330
    return render(width: width, height: height, scale: 2) {
        theme.page.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        drawMenuBar(width: CGFloat(width), top: CGFloat(height), frame: shot.frame, theme: theme, zoom: 3.5)

        // Text being typed, with a caret.
        let font = NSFont.systemFont(ofSize: 24, weight: .regular)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: theme.fg]
        let full = NSAttributedString(string: "bongo cat", attributes: attrs).size()
        let typed = NSAttributedString(string: shot.typed, attributes: attrs)
        let textX = CGFloat(width) / 2 - full.width / 2, textY: CGFloat = 196
        typed.draw(at: NSPoint(x: textX, y: textY - full.height / 2))
        theme.fg.setFill()
        NSRect(x: textX + typed.size().width + 1, y: textY - 13, width: 2, height: 26).fill()

        drawKeyboard(centerX: CGFloat(width) / 2, top: 160, pressed: shot.pressed, theme: theme)
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
    writeGIF(timeline().map { (renderGIFFrame(theme, $0), $0.duration) }, to: gif)
    print("wrote \(png)\nwrote \(gif)")
}
