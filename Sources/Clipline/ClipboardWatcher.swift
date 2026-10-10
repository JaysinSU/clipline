import AppKit
import CryptoKit
import ImageIO

/// Receives image bytes from screenshot tools such as Feishu, without
/// changing the clipboard or importing the image that predates startup.
@MainActor
final class ClipboardWatcher {
    static let originType = NSPasteboard.PasteboardType("app.clipline.clipboard-origin")
    static let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Clipline/Clipboard", isDirectory: true)
    private static let ignoredTypes: Set<NSPasteboard.PasteboardType> = [
        originType,
        .init("org.nspasteboard.ConcealedType"),
        .init("org.nspasteboard.TransientType"),
    ]
    private static let imageTypes: [NSPasteboard.PasteboardType] = [
        .png, .tiff, .init("public.jpeg"), .init("public.heic"), .init("org.webmproject.webp")
    ]

    private let pasteboard: NSPasteboard
    private let outputFolder: URL
    private let accepts: (String) -> Bool
    private let onNew: (URL, String) -> Bool
    private let onError: (Error) -> Void
    private var timer: Timer?
    private var lastChangeCount: Int
    private var pendingCount: Int?
    private var attempts = 0

    init(pasteboard: NSPasteboard = .general, folder: URL? = nil,
         accepts: @escaping (String) -> Bool = { _ in true },
         onError: @escaping (Error) -> Void = { _ in },
         onNew: @escaping (URL, String) -> Bool) {
        self.pasteboard = pasteboard
        outputFolder = folder ?? Self.folder
        self.accepts = accepts
        self.onError = onError
        self.onNew = onNew
        lastChangeCount = pasteboard.changeCount
    }

    func start() {
        stop()
        lastChangeCount = pasteboard.changeCount
        let timer = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.poll() }
        }
        timer.tolerance = 0.02
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        pendingCount = nil
    }

    /// Internal so tests can exercise a named pasteboard without touching
    /// the user's real clipboard or depending on timer timing.
    func poll() {
        let count = pasteboard.changeCount
        guard count != lastChangeCount else { return }
        if pendingCount != count {
            pendingCount = count
            attempts = 0
        }
        let types = Set(pasteboard.types ?? [])
        if !types.isDisjoint(with: Self.ignoredTypes) {
            lastChangeCount = count
            return
        }

        // A copied Finder file is not a fresh screenshot. Raw image data
        // accompanied by a URL is still accepted (some screenshot tools do this).
        let hasImageBytes = Self.imageTypes.contains { types.contains($0) }
        if !hasImageBytes && !types.isEmpty {
            lastChangeCount = count
            return
        }

        // Some tools announce an image before providing its bytes. Retry for
        // up to 1.6 seconds, and never mark a temporarily empty image as handled.
        guard let capture = Self.readImage(from: pasteboard),
              let fingerprint = ImageFingerprint.of(capture.image) else {
            attempts += 1
            if attempts >= 8 { lastChangeCount = count }
            return
        }
        guard pasteboard.changeCount == count else { return }
        lastChangeCount = count
        guard accepts(fingerprint) else { return }

        do {
            try FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)
            let url = outputFolder.appendingPathComponent("Clipboard-\(UUID().uuidString).png")
            try capture.png.write(to: url, options: .atomic)
            // Remove an unclaimed duplicate/invalid file rather than accumulating it.
            if !onNew(url, fingerprint) { try? FileManager.default.removeItem(at: url) }
        } catch {
            onError(error)
        }
    }

    private static func readImage(from pasteboard: NSPasteboard) -> (image: CGImage, png: Data)? {
        for type in imageTypes {
            guard let data = pasteboard.data(forType: type),
                  let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
                  image.width <= 16384, image.height <= 16384,
                  image.width * image.height <= 80_000_000 else { continue }
            if type == .png { return (image, data) }
            if let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) {
                return (image, png)
            }
        }
        return nil
    }
}

/// Hash actual pixels, so PNG and TIFF versions of the same screenshot
/// (or a screenshot delivered as both a file and clipboard data) match.
enum ImageFingerprint {
    static func of(_ url: URL) -> String? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
        return of(image)
    }

    static func of(_ image: CGImage) -> String? {
        guard image.width > 0, image.height > 0,
              image.width <= 16384, image.height <= 16384,
              image.width * image.height <= 80_000_000,
              let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil, width: image.width, height: image.height,
                                      bitsPerComponent: 8, bytesPerRow: image.width * 4,
                                      space: space,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
              let pixels = context.data else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        var hash = SHA256()
        hash.update(data: Data("\(image.width)x\(image.height):".utf8))
        hash.update(data: Data(bytesNoCopy: pixels, count: image.width * image.height * 4, deallocator: .none))
        return hash.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
