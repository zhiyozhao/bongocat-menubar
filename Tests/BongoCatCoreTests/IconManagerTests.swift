import AppKit
import Testing
@testable import BongoCatCore

@Suite("IconManager: icon lookup order")
struct IconManagerTests {
    @Test("candidate order is svg → _color.png → png")
    func candidateOrder() {
        let c = IconManager.candidates(for: "idle")
        #expect(c.map { "\($0.resource).\($0.ext)" } == ["idle.svg", "idle_color.png", "idle.png"])
    }

    /// Builds a flat resource bundle in a temp dir containing the given files.
    /// Each PNG gets a distinct width so we can tell which one was loaded.
    private func bundle(with files: [String: Int]) throws -> Bundle {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("IconManagerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for (name, width) in files {
            let url = dir.appendingPathComponent(name)
            if name.hasSuffix(".svg") {
                let svg = #"<svg xmlns="http://www.w3.org/2000/svg" width="\#(width)" height="10"><rect width="\#(width)" height="10"/></svg>"#
                try svg.write(to: url, atomically: true, encoding: .utf8)
            } else {
                let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: 10,
                                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
                try rep.representation(using: .png, properties: [:])!.write(to: url)
            }
        }
        return try #require(Bundle(path: dir.path))
    }

    @Test("svg wins over png and is a template image")
    func svgFirst() throws {
        let b = try bundle(with: ["idle.svg": 20, "idle_color.png": 40, "idle.png": 80])
        let image = IconManager(bundle: b).icon(for: "idle")
        #expect(image.size.width == 32)   // 20:10 aspect at 16pt high
        #expect(image.size.height == IconManager.iconHeight)
        #expect(image.isTemplate)
    }

    @Test("_color.png wins over plain png and is not a template image")
    func colorBeforePlain() throws {
        let b = try bundle(with: ["idle_color.png": 40, "idle.png": 80])
        let image = IconManager(bundle: b).icon(for: "idle")
        #expect(image.size.width == 64)   // 40:10
        #expect(!image.isTemplate)
    }

    @Test("plain png is used last and is a template image")
    func plainPng() throws {
        let b = try bundle(with: ["idle.png": 80])
        let image = IconManager(bundle: b).icon(for: "idle")
        #expect(image.size.width == 128)  // 80:10
        #expect(image.isTemplate)
    }

    @Test("missing resources fall back to an SF Symbol")
    func symbolFallback() throws {
        let b = try bundle(with: [:])
        let image = IconManager(bundle: b).icon(for: "typing_a")
        #expect(image.size.width > 0)
    }

    @Test("bundled artwork: all four frames load from Resources/Icons as 16pt templates")
    func bundledArtwork() throws {
        let iconsDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Resources/Icons")
        let b = try #require(Bundle(path: iconsDir.path))
        let manager = IconManager(bundle: b)
        for frame in ["idle", "typing_a", "typing_b", "typing_both"] {
            let image = manager.icon(for: frame)
            #expect(image.isTemplate, "\(frame)")
            #expect(image.size.height == IconManager.iconHeight, "\(frame)")
            #expect(abs(image.size.width - 16.0 * 89.0 / 51.0) < 0.01, "\(frame)")
        }
    }
}
