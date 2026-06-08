import AppKit

final class StatusItemManager: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    var onPrimaryClick: (() -> Void)?
    var onMenuRequest: (() -> Void)?

    var button: NSStatusBarButton? {
        statusItem.button
    }

    override init() {
        super.init()
        configure()
    }

    func showMenu(_ menu: NSMenu) {
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    func remove() {
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    private func configure() {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "text.badge.star", accessibilityDescription: "PromptDock")
        button.image?.isTemplate = true
        button.imagePosition = .imageLeading
        button.title = " PromptDock"
        button.font = .systemFont(ofSize: 14, weight: .semibold)
        button.toolTip = "PromptDock：点击打开，右键显示菜单"
        button.target = self
        button.action = #selector(handleClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        if let event = NSApp.currentEvent,
           event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            onMenuRequest?()
        } else {
            onPrimaryClick?()
        }
    }
}
