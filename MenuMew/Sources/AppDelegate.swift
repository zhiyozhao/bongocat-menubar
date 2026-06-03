import AppKit
import ApplicationServices

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var keyboardMonitor: KeyboardMonitor!
    private var animator: KeystrokeAnimator!
    private var iconManager: IconManager!
    private var permissionItem: NSMenuItem!
    private var normalModeItem: NSMenuItem!
    private var followHandsItem: NSMenuItem!
    private var permissionTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        iconManager = IconManager()
        animator = KeystrokeAnimator()

        animator.onFrameChange = { [weak self] frame in
            self?.statusItem.button?.image = self?.iconManager.icon(for: frame)
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            let image = iconManager.icon(for: "idle")
            button.image = image
            button.imagePosition = .imageOnly
            statusItem.length = image.size.width
        }

        keyboardMonitor = KeyboardMonitor()
        keyboardMonitor.onKeyDown = { [weak self] keycode in
            self?.animator.keyDown(keycode: keycode)
        }
        keyboardMonitor.onKeyUp = { [weak self] keycode in
            self?.animator.keyUp(keycode: keycode)
        }

        setupMenu()
        refreshPermissionUI()
        startMonitoringIfPermitted()
        startPermissionPolling()
    }

    private func startMonitoringIfPermitted() {
        if AXIsProcessTrusted() {
            keyboardMonitor.start()
        } else {
            showPermissionGuide()
        }
    }

    private func startPermissionPolling() {
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.refreshPermissionUI()
            if !self.keyboardMonitor.isRunning && AXIsProcessTrusted() {
                self.keyboardMonitor.start()
            }
        }
    }

    private func showPermissionGuide() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "MenuMew needs to monitor keyboard input so the cat can type along with you.\n\nClick \"Open Settings\" to grant access."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Later")

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            _ = AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as NSDictionary)
        }
    }

    private func refreshPermissionUI() {
        let granted = AXIsProcessTrusted()
        permissionItem.isHidden = granted
        if !granted {
            permissionItem.title = "Accessibility"
            permissionItem.action = #selector(requestPermission)
            permissionItem.image = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: nil)?
                .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: NSFont.menuFont(ofSize: 0).pointSize, weight: .regular))
        }
    }

    @objc private func requestPermission() {
        _ = AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as NSDictionary)
    }

    @objc private func selectNormalMode() {
        animator.followHands = false
        normalModeItem.state = .on
        followHandsItem.state = .off
    }

    @objc private func selectFollowHands() {
        animator.followHands = true
        normalModeItem.state = .off
        followHandsItem.state = .on
    }

    private func setupMenu() {
        let menu = NSMenu()

        permissionItem = NSMenuItem(title: "Accessibility", action: #selector(requestPermission), keyEquivalent: "")
        permissionItem.image = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: nil)?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: NSFont.menuFont(ofSize: 0).pointSize, weight: .regular))
        menu.addItem(permissionItem)

        menu.addItem(NSMenuItem.separator())

        normalModeItem = NSMenuItem(title: "Normal Mode", action: #selector(selectNormalMode), keyEquivalent: "")
        normalModeItem.state = .on
        menu.addItem(normalModeItem)

        followHandsItem = NSMenuItem(title: "Follow Mode", action: #selector(selectFollowHands), keyEquivalent: "")
        followHandsItem.state = .off
        menu.addItem(followHandsItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Quit MenuMew", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    @objc private func quitApp() { NSApplication.shared.terminate(nil) }

    func applicationWillTerminate(_ notification: Notification) {
        keyboardMonitor.stop()
        permissionTimer?.invalidate()
    }
}
