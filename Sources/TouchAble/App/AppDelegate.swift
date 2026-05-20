import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let debugUI = ProcessInfo.processInfo.arguments.contains("--open-debug")
        NSApp.setActivationPolicy(debugUI ? .regular : .accessory)
        if debugUI {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
