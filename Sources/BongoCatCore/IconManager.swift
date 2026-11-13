import AppKit

public class IconManager {
    public static let iconHeight: CGFloat = 16.0

    private let bundle: Bundle
    private var cache: [String: NSImage] = [:]

    public init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    public func icon(for frame: String) -> NSImage {
        if let cached = cache[frame] { return cached }
        let image = loadIcon(named: frame) ?? builtinFallback(for: frame)
        cache[frame] = image
        return image
    }

    /// Resource lookup order for a frame: `<name>.svg` → `<name>_color.png` → `<name>.png`.
    static func candidates(for name: String) -> [(resource: String, ext: String)] {
        [
            (name, "svg"),
            ("\(name)_color", "png"),
            (name, "png"),
        ]
    }

    private func loadIcon(named name: String) -> NSImage? {
        for (res, ext) in Self.candidates(for: name) {
            if let path = bundle.path(forResource: res, ofType: ext) {
                if let image = NSImage(contentsOfFile: path) {
                    let aspectRatio = image.size.width / image.size.height
                    let w = Self.iconHeight * aspectRatio
                    image.size = NSSize(width: w, height: Self.iconHeight)
                    image.isTemplate = !res.contains("_color")
                    return image
                }
            }
        }
        return nil
    }

    private func builtinFallback(for frame: String) -> NSImage {
        if frame == "idle" {
            return symbolIcon("cat")
        }
        return symbolIcon("cat.fill")
    }

    private func symbolIcon(_ name: String) -> NSImage {
        if let image = NSImage(systemSymbolName: name, accessibilityDescription: nil) {
            let config = NSImage.SymbolConfiguration(pointSize: Self.iconHeight, weight: .regular)
            if let configured = image.withSymbolConfiguration(config) {
                return configured
            }
        }
        let image = NSImage(size: NSSize(width: Self.iconHeight, height: Self.iconHeight))
        return image
    }
}
