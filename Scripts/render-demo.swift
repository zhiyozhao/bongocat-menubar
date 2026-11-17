#!/usr/bin/env swift
//
// render-demo.swift
//
// Renders the README demo images from the real menu bar artwork in
// Resources/Icons/*.svg — no screen capture involved.
//
// Output (docs/assets/):
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

/// Highlighter yellow, same as the website: pressed keys and the close-up frame.
let marker = NSColor(srgbRed: 1.0, green: 0.847, blue: 0.29, alpha: 1)
let onMarker = NSColor(srgbRed: 0.08, green: 0.08, blue: 0.08, alpha: 1)

/// Magnification of the menu bar strip.
let zoom: CGFloat = 2

/// A slice of the right side of the menu bar: [wifi] [battery] [cat] [clock].
/// Returns the cat rect so the close-up can point at it.
@discardableResult
func drawMenuBar(width: CGFloat, top: CGFloat, frame: String, theme: Theme) -> NSRect {
    let barHeight = 24 * zoom
    let catSize = NSSize(width: 16 * 89.0 / 51.0 * zoom, height: 16 * zoom)
    let y = top - barHeight
    theme.bar.setFill()
    NSRect(x: 0, y: y, width: width, height: barHeight).fill()

    let mid = y + barHeight / 2
    let glyph: CGFloat = 13 * zoom
    var x = width - 20 * zoom

    let clock = NSAttributedString(string: "12:14", attributes: [.font: NSFont.systemFont(ofSize: glyph, weight: .medium)])
    x -= clock.size().width
    drawText("12:14", at: NSPoint(x: x, y: mid), size: glyph, color: theme.fg)
    x -= 14 * zoom

    x -= catSize.width
    let catRect = NSRect(x: x, y: mid - catSize.height / 2, width: catSize.width, height: catSize.height)
    drawTemplate(frames[frame]!, in: catRect, color: theme.fg)
    x -= 14 * zoom

    for name in ["battery.75percent", "wifi"] {
        let symbol = NSImage(systemSymbolName: name, accessibilityDescription: nil)!
            .withSymbolConfiguration(.init(pointSize: glyph, weight: .regular))!
        x -= symbol.size.width
        _ = drawSymbol(name, at: NSPoint(x: x, y: mid), height: glyph, color: theme.fg)
        x -= 14 * zoom
    }
    return catRect
}

/// Keyboard rows; the first five keys of each row belong to the left hand
/// (same split as KeyMap). Space is a right-hand key in the app.
let rows: [[String]] = [
    ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
    ["A", "S", "D", "F", "G", "H", "J", "K", "L", ";"],
    ["Z", "X", "C", "V", "B", "N", "M", ",", ".", "/"],
]
let rightHandKeys: Set<String> = Set(rows.flatMap { $0.dropFirst(5) }).union([" "])

/// Draws a small keyboard; the two hands are split by a gap, pressed keys turn yellow.
func drawKeyboard(left: CGFloat, top: CGFloat, pressed: Set<String>, theme: Theme) {
    let key: CGFloat = 30, gap: CGFloat = 5, split: CGFloat = 18
    let unit = key + gap
    let stagger: [CGFloat] = [0, 0.25 * unit, 0.75 * unit]

    func cap(_ r: NSRect, _ label: String, down: Bool) {
        let path = NSBezierPath(roundedRect: r, xRadius: 6, yRadius: 6)
        (down ? marker : theme.keyFill).setFill()
        path.fill()
        path.lineWidth = 1
        (down ? marker : theme.keyStroke).setStroke()
        path.stroke()
        if !label.isEmpty {
            drawText(label, at: NSPoint(x: r.midX, y: r.midY), size: 13, color: down ? onMarker : theme.keyText,
                     weight: down ? .bold : .medium, centered: true)
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

// MARK: - Animated GIF: Follow Mode while typing

/// One keystroke: key label, time it goes down, time it comes up (seconds).
struct Stroke { let key: String; let down: Double; let up: Double }

/// Typing "bongo cat" slowly enough to follow each paw. "g" and "o" overlap,
/// so both paws stay down together for a moment.
let strokes: [Stroke] = [
    .init(key: "B", down: 0.80, up: 1.15),
    .init(key: "O", down: 1.35, up: 1.65),
    .init(key: "N", down: 1.85, up: 2.10),
    .init(key: "G", down: 2.30, up: 2.95),
    .init(key: "O", down: 2.50, up: 2.95),
    .init(key: " ", down: 3.15, up: 3.35),
    .init(key: "C", down: 3.50, up: 3.75),
    .init(key: "A", down: 3.90, up: 4.15),
    .init(key: "T", down: 4.30, up: 4.60),
]
let loopLength = 6.2

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

/// Layout: menu bar strip on top; keyboard and typed text on the left; on the
/// right a close-up of the menu bar cat, linked to it by two guide lines.
func renderGIFFrame(_ theme: Theme, _ shot: Shot) -> CGImage {
    let width: CGFloat = 720, height: CGFloat = 300
    return render(width: Int(width), height: Int(height), scale: 2) {
        theme.page.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        let small = drawMenuBar(width: width, top: height, frame: shot.frame, theme: theme)

        // Close-up panel under the menu bar cat.
        let bigH: CGFloat = 118, bigW = bigH * 89 / 51
        let panel = NSRect(x: min(small.midX - 130, width - 24 - 260), y: 40, width: 260, height: 186)
        let guide = NSBezierPath()
        guide.move(to: NSPoint(x: small.minX, y: small.minY - 3)); guide.line(to: NSPoint(x: panel.minX + 14, y: panel.maxY))
        guide.move(to: NSPoint(x: small.maxX, y: small.minY - 3)); guide.line(to: NSPoint(x: panel.maxX - 14, y: panel.maxY))
        guide.lineWidth = 1.5
        guide.setLineDash([5, 4], count: 2, phase: 0)
        theme.keyStroke.setStroke()
        guide.stroke()
        let box = NSBezierPath(roundedRect: panel, xRadius: 18, yRadius: 18)
        theme.page.setFill(); box.fill()
        box.lineWidth = 2
        theme.fg.setStroke(); box.stroke()
        let big = NSRect(x: panel.midX - bigW / 2, y: panel.midY - bigH / 2, width: bigW, height: bigH)
        drawTemplate(frames[shot.frame]!, in: big, color: theme.fg)

        // Text being typed, with a caret.
        let kbLeft: CGFloat = 32
        let font = NSFont.systemFont(ofSize: 24, weight: .regular)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: theme.fg]
        let full = NSAttributedString(string: "bongo cat", attributes: attrs).size()
        let typed = NSAttributedString(string: shot.typed, attributes: attrs)
        let textY: CGFloat = 214
        typed.draw(at: NSPoint(x: kbLeft + 4, y: textY - full.height / 2))
        theme.fg.setFill()
        NSRect(x: kbLeft + 4 + typed.size().width + 1, y: textY - 13, width: 2, height: 26).fill()

        drawKeyboard(left: kbLeft, top: 182, pressed: shot.pressed, theme: theme)
    }
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
    let gif = "\(outDir)/demo-\(theme.name).gif"
    writeGIF(timeline().map { (renderGIFFrame(theme, $0), $0.duration) }, to: gif)
    print("wrote \(gif)")
}
