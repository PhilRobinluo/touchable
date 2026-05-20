import AppKit
import SwiftUI

@MainActor
final class DebugWindowPresenter {
    static let shared = DebugWindowPresenter()

    private var window: NSWindow?

    private init() {}

    func show(preferences: PreferenceStore, controller: TouchAbleController) {
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
        self.window = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
