import AppKit
import ApplicationServices
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var keyboardMonitor: KeyboardMonitor!
    private var animator: KeystrokeAnimator!
    private var iconManager: IconManager!
    private var permissionItem: NSMenuItem!
    private var normalModeItem: NSMenuItem!
    private var followHandsItem: NSMenuItem!
    private var launchAtLoginItem: NSMenuItem!
    private var permissionTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        iconManager = IconManager()
        animator = KeystrokeAnimator()

        let savedFollowHands = UserDefaults.standard.bool(forKey: "followHands")
        animator.followHands = savedFollowHands

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
        alert.messageText = NSLocalizedString("permission.alert.title", comment: "")
        alert.informativeText = NSLocalizedString("permission.alert.message", comment: "")
        alert.alertStyle = .informational
        alert.addButton(withTitle: NSLocalizedString("permission.alert.open_settings", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("permission.alert.later", comment: ""))

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
            permissionItem.title = NSLocalizedString("menu.accessibility", comment: "")
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
        UserDefaults.standard.set(false, forKey: "followHands")
        normalModeItem.state = .on
        followHandsItem.state = .off
    }

    @objc private func selectFollowHands() {
        animator.followHands = true
        UserDefaults.standard.set(true, forKey: "followHands")
        normalModeItem.state = .off
        followHandsItem.state = .on
    }

    @objc private func toggleLaunchAtLogin() {
        if SMAppService.mainApp.status == .enabled {
            try? SMAppService.mainApp.unregister()
        } else {
            try? SMAppService.mainApp.register()
        }
        launchAtLoginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    private func setupMenu() {
        let menu = NSMenu()

        permissionItem = NSMenuItem(title: NSLocalizedString("menu.accessibility", comment: ""), action: #selector(requestPermission), keyEquivalent: "")
        permissionItem.image = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: nil)?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: NSFont.menuFont(ofSize: 0).pointSize, weight: .regular))
        menu.addItem(permissionItem)

        menu.addItem(NSMenuItem.separator())

        normalModeItem = NSMenuItem(title: NSLocalizedString("menu.normal_mode", comment: ""), action: #selector(selectNormalMode), keyEquivalent: "")
        normalModeItem.state = animator.followHands ? .off : .on
        menu.addItem(normalModeItem)

        followHandsItem = NSMenuItem(title: NSLocalizedString("menu.follow_mode", comment: ""), action: #selector(selectFollowHands), keyEquivalent: "")
        followHandsItem.state = animator.followHands ? .on : .off
        menu.addItem(followHandsItem)

        menu.addItem(NSMenuItem.separator())

        launchAtLoginItem = NSMenuItem(title: NSLocalizedString("menu.launch_at_login", comment: ""), action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(launchAtLoginItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: NSLocalizedString("menu.quit", comment: ""), action: #selector(quitApp), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    @objc private func quitApp() { NSApplication.shared.terminate(nil) }

    func applicationWillTerminate(_ notification: Notification) {
        keyboardMonitor.stop()
        permissionTimer?.invalidate()
    }
}
