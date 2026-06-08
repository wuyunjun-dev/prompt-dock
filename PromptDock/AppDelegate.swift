import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private let viewModel = PromptDockViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else {
            return
        }

        NSApp.setActivationPolicy(.accessory)

        let controller = MenuBarController(viewModel: viewModel)
        controller.start()
        menuBarController = controller
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        menuBarController?.showMainWindow()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        menuBarController?.stop()
    }
}
