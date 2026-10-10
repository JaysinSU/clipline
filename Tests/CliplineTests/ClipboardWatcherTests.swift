import AppKit

@MainActor
final class ClipboardWatcherTests {
    private var board: NSPasteboard!
    private var folder: URL!
    private var received: [(URL, String)] = []
    private var failures: [Error] = []
    private var watcher: ClipboardWatcher!

    func setUp() {
        board = NSPasteboard(name: .init("CliplineTests-\(UUID().uuidString)"))
        folder = FileManager.default.temporaryDirectory.appendingPathComponent("CliplineTests-\(UUID().uuidString)")
        received = []
        failures = []
        watcher = makeWatcher()
    }

    func tearDown() {
        watcher.stop()
        board.releaseGlobally()
        try? FileManager.default.removeItem(at: folder)
    }

    private func makeWatcher(accepts: @escaping (String) -> Bool = { _ in true }, claimed: Bool = true) -> ClipboardWatcher {
        ClipboardWatcher(pasteboard: board, folder: folder, accepts: accepts,
                         onError: { [weak self] in self?.failures.append($0) },
                         onNew: { [weak self] url, fingerprint in
                             self?.received.append((url, fingerprint))
                             return claimed
                         })
    }

    private func image(_ format: NSBitmapImageRep.FileType = .png, width: Int = 64, height: Int = 32) -> Data {
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let pixels = context.data!.assumingMemoryBound(to: UInt8.self)
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                pixels[offset] = UInt8(x * 255 / width)
                pixels[offset + 1] = 102
                pixels[offset + 2] = UInt8(y * 255 / height)
                pixels[offset + 3] = 255
            }
        }
        let rep = NSBitmapImageRep(cgImage: context.makeImage()!)
        return rep.representation(using: format, properties: [:])!
    }

    private func put(_ data: Data, type: NSPasteboard.PasteboardType = .png, marker: NSPasteboard.PasteboardType? = nil) {
        let entry = NSPasteboardItem()
        entry.setData(data, forType: type)
        if let marker { entry.setString("test", forType: marker) }
        board.clearContents()
        board.writeObjects([entry])
    }

    func testPNGIsSavedOnceWithoutChangingClipboard() throws {
        let png = image()
        put(png)
        let count = board.changeCount
        watcher.poll()
        watcher.poll()
        try XCTAssertEqual(received.count, 1)
        try XCTAssertEqual(board.changeCount, count)
        try XCTAssertEqual(board.data(forType: .png), png)
        try XCTAssertEqual(try Data(contentsOf: received[0].0), png)
    }

    func testTIFFIsConvertedAtFullPixelResolution() throws {
        put(image(.tiff, width: 128, height: 64), type: .tiff)
        watcher.poll()
        try XCTAssertEqual(received.count, 1)
        let rep = try XCTUnwrap(NSBitmapImageRep(data: try Data(contentsOf: received[0].0)))
        try XCTAssertEqual(rep.pixelsWide, 128)
        try XCTAssertEqual(rep.pixelsHigh, 64)
        try XCTAssertEqual(received[0].0.pathExtension, "png")
    }

    func testPNGAndTIFFHaveSamePixelFingerprint() throws {
        put(image())
        watcher.poll()
        put(image(.tiff), type: .tiff)
        watcher.poll()
        try XCTAssertEqual(received.count, 2)
        try XCTAssertEqual(received[0].1, received[1].1)
    }

    func testStartupDoesNotImportOldClipboard() throws {
        put(image())
        watcher = makeWatcher()
        watcher.start()
        watcher.poll()
        try XCTAssertTrue(received.isEmpty)
    }

    func testSelfCopiesAndConcealedImagesAreIgnored() throws {
        for marker in [ClipboardWatcher.originType, .init("org.nspasteboard.ConcealedType"), .init("org.nspasteboard.TransientType")] {
            put(image(), marker: marker)
            watcher.poll()
        }
        try XCTAssertTrue(received.isEmpty)
    }

    func testTextAndFinderFileCopiesAreIgnored() throws {
        board.clearContents()
        board.setString("test text", forType: .string)
        watcher.poll()
        board.clearContents()
        board.writeObjects([URL(fileURLWithPath: "/tmp/example.png") as NSURL])
        watcher.poll()
        try XCTAssertTrue(received.isEmpty)
    }

    func testRawImageWithFileURLIsAccepted() throws {
        let item = NSPasteboardItem()
        item.setData(image(), forType: .png)
        item.setString("file:///tmp/feishu.png", forType: .fileURL)
        board.clearContents()
        board.writeObjects([item])
        watcher.poll()
        try XCTAssertEqual(received.count, 1)
    }

    func testRejectedDuplicateDoesNotCreateAFile() throws {
        watcher = makeWatcher(accepts: { _ in false })
        put(image())
        watcher.poll()
        try XCTAssertTrue(received.isEmpty)
        try XCTAssertFalse(FileManager.default.fileExists(atPath: folder.path))
    }

    func testUnclaimedFileIsRemoved() throws {
        watcher = makeWatcher(claimed: false)
        put(image())
        watcher.poll()
        try XCTAssertEqual(received.count, 1)
        try XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: folder.path).isEmpty)
    }

    func testMalformedImageIsIgnoredAndNextScreenshotStillWorks() throws {
        put(Data("invalid".utf8))
        for _ in 0..<10 { watcher.poll() }
        try XCTAssertTrue(received.isEmpty)
        put(image())
        watcher.poll()
        try XCTAssertEqual(received.count, 1)
    }

    func testWriteFailureIsReportedWithoutClaimingAnImage() throws {
        try FileManager.default.createDirectory(at: folder.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not a directory".utf8).write(to: folder)
        put(image())
        watcher.poll()
        try XCTAssertTrue(received.isEmpty)
        try XCTAssertEqual(failures.count, 1)
    }

    func testAnnouncedImageCanArriveLater() throws {
        board.declareTypes([.png], owner: nil)
        watcher.poll()
        try XCTAssertTrue(received.isEmpty)
        board.setData(image(), forType: .png)
        watcher.poll()
        try XCTAssertEqual(received.count, 1)
    }

    func testTimerReceivesAndStopDisablesReception() throws {
        watcher.start()
        put(image())
        let deadline = Date().addingTimeInterval(1.5)
        while received.isEmpty && Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
        try XCTAssertEqual(received.count, 1)
        watcher.stop()
        put(image(.png, width: 32))
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        try XCTAssertEqual(received.count, 1)
        watcher.start()
        watcher.poll()
        try XCTAssertEqual(received.count, 1)
    }

    func testLineDeduplicatesBothDeliveryOrdersAndPersists() throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let clipboardFolder = folder.appendingPathComponent("clipboard")
        try FileManager.default.createDirectory(at: clipboardFolder, withIntermediateDirectories: true)
        let diskFile = folder.appendingPathComponent("system-screenshot.png")
        let clipFile = clipboardFolder.appendingPathComponent("clipboard.png")
        try image().write(to: diskFile)
        try image().write(to: clipFile)
        let fingerprint = try XCTUnwrap(ImageFingerprint.of(diskFile))
        let suite = "CliplineTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(true, forKey: "soundOff")
        let fileFirst = Line(defaults: defaults, clipboardFolder: clipboardFolder)
        try XCTAssertTrue(fileFirst.hang(diskFile, quietly: true) != nil)
        try XCTAssertFalse(fileFirst.hangClipboard(clipFile, fingerprint: fingerprint))
        try XCTAssertEqual(fileFirst.liveCount, 1)

        defaults.removeObject(forKey: "pegged")
        let clipboardFirst = Line(defaults: defaults, clipboardFolder: clipboardFolder)
        try XCTAssertTrue(clipboardFirst.hangClipboard(clipFile, fingerprint: fingerprint))
        try XCTAssertTrue(clipboardFirst.hang(diskFile, quietly: true) == nil)
        try XCTAssertEqual(clipboardFirst.liveCount, 1)
        try XCTAssertTrue(clipboardFirst.isInInbox(clipboardFirst.items[0].id))
        let restored = Line(defaults: defaults, clipboardFolder: clipboardFolder)
        try XCTAssertEqual(restored.liveCount, 1)
        try XCTAssertTrue(restored.containsImage(fingerprint))
    }

    func testCopyingFromLineDoesNotLoopBack() throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appendingPathComponent("copy-test.png")
        try image().write(to: file)
        let suite = "CliplineTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(true, forKey: "soundOff")
        let line = Line(defaults: defaults)
        let id = try XCTUnwrap(line.hang(file, quietly: true))
        line.copy(id, to: board)
        watcher.poll()
        try XCTAssertTrue(received.isEmpty)
        try XCTAssertTrue(board.data(forType: .png) != nil)
        try XCTAssertEqual(line.liveCount, 1)
    }
}

private struct TestFailure: Error, CustomStringConvertible {
    let description: String
}
private func XCTAssertTrue(_ value: Bool, file: StaticString = #filePath, line: UInt = #line) throws {
    if !value { throw TestFailure(description: "Expected true at \(file):\(line)") }
}
private func XCTAssertFalse(_ value: Bool, file: StaticString = #filePath, line: UInt = #line) throws {
    try XCTAssertTrue(!value, file: file, line: line)
}
private func XCTAssertEqual<T: Equatable>(_ a: T, _ b: T, file: StaticString = #filePath, line: UInt = #line) throws {
    if a != b { throw TestFailure(description: "Values differ at \(file):\(line)") }
}
private func XCTUnwrap<T>(_ value: T?, file: StaticString = #filePath, line: UInt = #line) throws -> T {
    guard let value else { throw TestFailure(description: "Unexpected nil at \(file):\(line)") }
    return value
}

@main
struct TestRunner {
    @MainActor
    static func main() {
        let suite = ClipboardWatcherTests()
        let cases: [(String, () throws -> Void)] = [
            ("testPNGIsSavedOnceWithoutChangingClipboard", suite.testPNGIsSavedOnceWithoutChangingClipboard),
            ("testTIFFIsConvertedAtFullPixelResolution", suite.testTIFFIsConvertedAtFullPixelResolution),
            ("testPNGAndTIFFHaveSamePixelFingerprint", suite.testPNGAndTIFFHaveSamePixelFingerprint),
            ("testStartupDoesNotImportOldClipboard", suite.testStartupDoesNotImportOldClipboard),
            ("testSelfCopiesAndConcealedImagesAreIgnored", suite.testSelfCopiesAndConcealedImagesAreIgnored),
            ("testTextAndFinderFileCopiesAreIgnored", suite.testTextAndFinderFileCopiesAreIgnored),
            ("testRawImageWithFileURLIsAccepted", suite.testRawImageWithFileURLIsAccepted),
            ("testRejectedDuplicateDoesNotCreateAFile", suite.testRejectedDuplicateDoesNotCreateAFile),
            ("testUnclaimedFileIsRemoved", suite.testUnclaimedFileIsRemoved),
            ("testMalformedImageIsIgnoredAndNextScreenshotStillWorks", suite.testMalformedImageIsIgnoredAndNextScreenshotStillWorks),
            ("testWriteFailureIsReportedWithoutClaimingAnImage", suite.testWriteFailureIsReportedWithoutClaimingAnImage),
            ("testAnnouncedImageCanArriveLater", suite.testAnnouncedImageCanArriveLater),
            ("testTimerReceivesAndStopDisablesReception", suite.testTimerReceivesAndStopDisablesReception),
            ("testLineDeduplicatesBothDeliveryOrdersAndPersists", suite.testLineDeduplicatesBothDeliveryOrdersAndPersists),
            ("testCopyingFromLineDoesNotLoopBack", suite.testCopyingFromLineDoesNotLoopBack)
        ]
        var failures = 0
        for (name, test) in cases {
            suite.setUp()
            do {
                try test()
                print("PASS \(name)")
            } catch {
                failures += 1
                print("FAIL \(name): \(error)")
            }
            suite.tearDown()
        }
        print("\(cases.count - failures)/\(cases.count) tests passed")
        exit(failures == 0 ? 0 : 1)
    }
}
