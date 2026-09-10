import AppKit

class IconManager {
    static let iconHeight: CGFloat = 16.0

    private var cache: [String: NSImage] = [:]

    func icon(for frame: String) -> NSImage {
        if let cached = cache[frame] { return cached }
        let image = loadIcon(named: frame) ?? builtinFallback(for: frame)
        cache[frame] = image
        return image
    }

    private func loadIcon(named name: String) -> NSImage? {
        let candidates = [
            (name, "svg"),
            ("\(name)_color", "png"),
            (name, "png"),
        ]

        for (res, ext) in candidates {
            if let path = Bundle.main.path(forResource: res, ofType: ext) {
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
