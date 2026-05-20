import SwiftUI

@main
struct TouchAbleApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @StateObject private var preferences: PreferenceStore
    @StateObject private var controller: TouchAbleController

    init() {
        let preferenceStore = PreferenceStore()
        let touchAbleController = TouchAbleController(preferences: preferenceStore)
        _preferences = StateObject(wrappedValue: preferenceStore)
        _controller = StateObject(wrappedValue: touchAbleController)

        if ProcessInfo.processInfo.arguments.contains("--open-debug") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                DebugWindowPresenter.shared.show(
                    preferences: preferenceStore,
                    controller: touchAbleController
                )
            }
        }
    }

    var body: some Scene {
        MenuBarExtra {
            TouchAbleMenuView()
                .environmentObject(preferences)
                .environmentObject(controller)
        } label: {
            Image(systemName: preferences.isEnabled ? "hand.tap.fill" : "hand.tap")
        }
        .menuBarExtraStyle(.menu)

        Window("TouchAble Playground", id: "playground") {
            PlaygroundView()
                .environmentObject(preferences)
                .environmentObject(controller)
        }
        .defaultSize(width: 760, height: 540)

        Settings {
            SettingsView()
                .environmentObject(preferences)
                .environmentObject(controller)
        }
    }
}
