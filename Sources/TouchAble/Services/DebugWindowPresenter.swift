import AppKit
import SwiftUI

@MainActor
final class DebugWindowPresenter: NSObject, NSWindowDelegate {
    static let shared = DebugWindowPresenter()

    private var window: NSWindow?
    private weak var controller: TouchAbleController?

    private override init() {}

    func show(preferences: PreferenceStore, controller: TouchAbleController) {
        self.controller = controller
        controller.setDiagnosticsEnabled(true)

        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let rootView = DebugView()
            .environmentObject(preferences)
            .environmentObject(controller)

        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "TouchAble Debug"
        window.contentViewController = hostingController
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        self.window = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        controller?.setDiagnosticsEnabled(false)
    }
}
