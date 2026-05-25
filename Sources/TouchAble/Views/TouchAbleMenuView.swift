import AppKit
import SwiftUI
import TouchAbleCore

struct TouchAbleMenuView: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var preferences: PreferenceStore
    @EnvironmentObject private var controller: TouchAbleController

    var body: some View {
        Section {
            Button {
                preferences.isEnabled.toggle()
            } label: {
                Label(
                    preferences.isEnabled ? "暂停 TouchAble" : "启用 TouchAble",
                    systemImage: preferences.isEnabled ? "pause.circle" : "play.circle"
                )
            }

            Toggle("边缘触感", isOn: $preferences.edgeHapticsEnabled)
            Toggle("点击 / 拖拽触感", isOn: $preferences.pointerEventHapticsEnabled)
            Toggle("滚动触感", isOn: $preferences.scrollHapticsEnabled)
            Toggle("光标触感", isOn: $preferences.cursorHapticsEnabled)
            Toggle("语义触感", isOn: $preferences.semanticHapticsEnabled)

            Picker("手感", selection: $preferences.strength) {
                ForEach(HapticStrength.allCases) { strength in
                    Text(strength.displayName).tag(strength)
                }
            }
        }

        Section {
            Label(
                controller.accessibilityTrusted ? "语义已授权" : "语义需授权",
                systemImage: controller.accessibilityTrusted ? "checkmark.shield" : "exclamationmark.shield"
            )
            Label(
                controller.inputMonitoringTrusted ? "操作已授权" : "操作需授权",
                systemImage: controller.inputMonitoringTrusted ? "checkmark.circle" : "exclamationmark.circle"
            )

            if !controller.accessibilityTrusted {
                Button {
                    controller.requestAccessibilityPermission()
                } label: {
                    Label("申请辅助功能权限", systemImage: "lock.open")
                }
            }

            if !controller.inputMonitoringTrusted {
                Button {
                    controller.requestInputMonitoringPermission()
                } label: {
                    Label("申请输入监控权限", systemImage: "cursorarrow.click")
                }
            }
        }

        Section {
            Button {
                controller.testPulse(zone: .control)
            } label: {
                Label("测试按钮触感", systemImage: "dot.radiowaves.left.and.right")
            }

            Button {
                openWindow(id: "playground")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label("打开 Playground", systemImage: "sparkles")
            }

            Button {
                DebugWindowPresenter.shared.show(
                    preferences: preferences,
                    controller: controller
                )
            } label: {
                Label("打开调试面板", systemImage: "waveform.path.ecg")
            }

            Button {
                SettingsWindowPresenter.shared.show(
                    preferences: preferences,
                    controller: controller
                )
            } label: {
                Label("设置", systemImage: "gearshape")
            }
        }

        Divider()

        Button {
            NSApp.terminate(nil)
        } label: {
            Label("退出", systemImage: "power")
        }
    }
}
