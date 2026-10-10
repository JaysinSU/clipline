import AppKit

@MainActor
final class SmokeDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let subject = AppDelegate()
    var window: NSWindow!
    var results: [String: Bool] = [:]
    let resultURL = URL(fileURLWithPath: CommandLine.arguments[1])

    func applicationDidFinishLaunching(_ notification: Notification) {
        subject.applicationDidFinishLaunching(notification)
        window = NSWindow(contentRect: NSRect(x: 220, y: 220, width: 800, height: 500),
                          styleMask: [.titled, .resizable, .closable], backing: .buffered, defer: false)
        window.title = "Clipline 全屏显示验证"
        window.collectionBehavior = [.fullScreenPrimary]
        window.delegate = self
        let label = NSTextField(labelWithString: "正在验证全屏显示与收起，完成后会自动关闭")
        label.font = .systemFont(ofSize: 22, weight: .medium)
        label.frame = NSRect(x: 50, y: 200, width: 700, height: 50)
        window.contentView?.addSubview(label)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.window.toggleFullScreen(nil) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 12) {
            self.results["completed"] = false
            self.finish()
        }
    }

    func windowDidEnterFullScreen(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            guard let panel = NSApp.windows.compactMap({ $0 as? LinePanel }).first,
                  let screen = self.window.screen else { self.finish(); return }
            self.results["realFullScreenSpace"] = FullScreen.isActive(on: screen)
            self.results["auxiliaryWindowBehavior"] = panel.collectionBehavior.contains(.fullScreenAuxiliary)
            self.results["automaticDisplaySuppressed"] = !panel.isVisible
            self.results["manualActionDispatched"] = NSApp.sendAction(NSSelectorFromString("toggle"), to: self.subject, from: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.results["manualPanelVisible"] = panel.isVisible
                self.results["manualPanelOnCurrentScreen"] = panel.screen == screen
                self.results["manualPanelOnScreen"] = self.onScreen(panel)
                _ = NSApp.sendAction(NSSelectorFromString("toggle"), to: self.subject, from: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    self.results["panelRemovedAfterHide"] = !panel.isVisible && !self.onScreen(panel)
                    self.results["completed"] = true
                    self.finish()
                }
            }
        }
    }

    private func onScreen(_ panel: NSWindow) -> Bool {
        let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
        return windows.contains { ($0[kCGWindowNumber as String] as? Int) == panel.windowNumber }
    }

    private func finish() {
        if let data = try? JSONSerialization.data(withJSONObject: results, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: resultURL)
        }
        NSApp.terminate(nil)
    }
    func applicationWillTerminate(_ notification: Notification) { subject.applicationWillTerminate(notification) }
}

@main
struct SmokeMain {
    @MainActor
    static func main() {
    let app = NSApplication.shared
    let delegate = SmokeDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.regular)
    withExtendedLifetime(delegate) { app.run() }
}

}
