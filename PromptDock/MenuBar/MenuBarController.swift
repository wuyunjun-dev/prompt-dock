import AppKit
import SwiftUI

@MainActor
final class MenuBarController: NSObject {
    private let statusItemManager = StatusItemManager()
    private let popover = NSPopover()
    private let hotKeyManager = HotKeyManager()
    private let viewModel: PromptDockViewModel
    private var mainWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var observers: [NSObjectProtocol] = []

    init(viewModel: PromptDockViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    func start() {
        configurePopover()
        Logger.info("Status item button created: \(statusItemManager.button != nil)")

        statusItemManager.onPrimaryClick = { [weak self] in
            self?.openMainWindow()
        }
        statusItemManager.onMenuRequest = { [weak self] in
            self?.showStatusMenu()
        }

        hotKeyManager.onHotKey = { [weak self] in
            self?.openMainWindow()
        }
        hotKeyManager.register()

        let observer = NotificationCenter.default.addObserver(
            forName: .promptDockOpenSettings,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.openSettings()
            }
        }
        observers.append(observer)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.showMainWindow()
        }
    }

    func showMainWindow() {
        openMainWindow()
    }

    func stop() {
        hotKeyManager.unregister()
        observers.forEach(NotificationCenter.default.removeObserver)
        statusItemManager.remove()
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 980, height: 640)
        popover.contentViewController = NSHostingController(
            rootView: MainPopoverView(viewModel: viewModel)
        )
    }

    private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItemManager.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showStatusMenu() {
        statusItemManager.showMenu(makeMenu())
    }

    private func openMainWindow() {
        if let mainWindow {
            bringWindowToFront(mainWindow)
            return
        }

        let hostingController = NSHostingController(
            rootView: MainPopoverView(viewModel: viewModel)
        )
        let window = NSWindow(contentViewController: hostingController)
        window.title = "PromptDock"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 980, height: 640))
        window.minSize = NSSize(width: 860, height: 560)
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        mainWindow = window
        bringWindowToFront(window)
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(menuItem(title: "打开 PromptDock", action: #selector(openPromptDock)))
        menu.addItem(menuItem(title: "优化剪贴板", action: #selector(optimizeClipboard)))
        menu.addItem(.separator())
        menu.addItem(menuItem(title: "设置", action: #selector(openSettings)))
        menu.addItem(.separator())
        menu.addItem(menuItem(title: "退出", action: #selector(quit)))
        return menu
    }

    private func menuItem(title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    @objc private func openPromptDock() {
        openMainWindow()
    }

    @objc private func optimizeClipboard() {
        openMainWindow()
        viewModel.optimizeClipboard()
    }

    @objc private func openSettings() {
        if let settingsWindow {
            bringWindowToFront(settingsWindow)
            return
        }

        let hostingController = NSHostingController(rootView: SettingsView(viewModel: viewModel))
        let window = NSWindow(contentViewController: hostingController)
        window.title = "PromptDock 设置"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 560, height: 620))
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        settingsWindow = window
        bringWindowToFront(window)
    }

    private func bringWindowToFront(_ window: NSWindow) {
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        if #available(macOS 14.0, *) {
            NSRunningApplication.current.activate(options: [.activateAllWindows])
        } else {
            NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

extension MenuBarController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow === mainWindow {
            mainWindow = nil
        }
        if notification.object as? NSWindow === settingsWindow {
            settingsWindow = nil
        }
    }
}
