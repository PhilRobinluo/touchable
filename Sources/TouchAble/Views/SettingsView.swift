import SwiftUI
import TouchAbleCore

struct SettingsView: View {
    @EnvironmentObject private var preferences: PreferenceStore
    @EnvironmentObject private var controller: TouchAbleController

    var body: some View {
        Form {
            Section("运行") {
                Toggle("启用 TouchAble", isOn: $preferences.isEnabled)
                    .localPulse(zone: .control, identity: "settings-enable")
                    .onChange(of: preferences.isEnabled) { _, _ in
                        pulse(.control, "settings-enable-change")
                    }
                Toggle("边缘触感", isOn: $preferences.edgeHapticsEnabled)
                    .localPulse(zone: .control, identity: "settings-edge")
                    .onChange(of: preferences.edgeHapticsEnabled) { _, _ in
                        pulse(.control, "settings-edge-change")
                    }
                Toggle("操作触感", isOn: $preferences.pointerEventHapticsEnabled)
                    .localPulse(zone: .control, identity: "settings-pointer-event")
                    .onChange(of: preferences.pointerEventHapticsEnabled) { _, _ in
                        pulse(.control, "settings-pointer-event-change")
                    }
                Toggle("光标触感", isOn: $preferences.cursorHapticsEnabled)
                    .localPulse(zone: .control, identity: "settings-cursor")
                    .onChange(of: preferences.cursorHapticsEnabled) { _, _ in
                        pulse(.control, "settings-cursor-change")
                    }
                Toggle("语义触感", isOn: $preferences.semanticHapticsEnabled)
                    .localPulse(zone: .control, identity: "settings-semantic")
                    .onChange(of: preferences.semanticHapticsEnabled) { _, _ in
                        pulse(.control, "settings-semantic-change")
                    }
            }

            Section("手感") {
                Picker("强度", selection: $preferences.strength) {
                    ForEach(HapticStrength.allCases) { strength in
                        Text(strength.displayName).tag(strength)
                    }
                }
                .pickerStyle(.segmented)
                .localPulse(zone: .control, identity: "settings-strength-picker")
                .onChange(of: preferences.strength) { _, newValue in
                    pulse(.adjustable, "settings-strength-\(newValue.rawValue)")
                }

                Text(preferences.strength.detail)
                    .foregroundStyle(.secondary)

                HStack {
                    Text("触感强度")
                    Slider(value: $preferences.intensityLevel, in: 1...8, step: 1) {
                        Text("触感强度")
                    }
                    .localPulse(zone: .adjustable, identity: "settings-intensity-slider")
                    .onChange(of: preferences.intensityLevel) { _, newValue in
                        pulse(.adjustable, "settings-intensity-\(Int(newValue.rounded()))")
                    }
                    Text("\(Int(preferences.intensityLevel.rounded()))")
                        .monospacedDigit()
                        .frame(width: 18, alignment: .trailing)
                }

                Toggle("同一对象可重复触发", isOn: $preferences.repeatSameTargetEnabled)
                    .localPulse(zone: .control, identity: "settings-repeat")
                    .onChange(of: preferences.repeatSameTargetEnabled) { _, _ in
                        pulse(.control, "settings-repeat-change")
                    }

                Text("公开 API 不支持直接调电机力度；这里通过更多脉冲、更紧节奏和混合模式模拟强弱。6-8 档偏调试增强。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("辅助功能权限") {
                HStack {
                    Label(
                        controller.accessibilityTrusted ? "已授权" : "未授权",
                        systemImage: controller.accessibilityTrusted ? "checkmark.shield" : "exclamationmark.shield"
                    )

                    Spacer()

                    Button("打开授权提示") {
                        pulse(.control, "settings-accessibility-request")
                        controller.requestAccessibilityPermission()
                    }
                    .disabled(controller.accessibilityTrusted)
                    .localPulse(zone: .control, identity: "settings-accessibility-button")
                }

                Text("语义触感只读取光标下方 UI 对象的类型，例如按钮、链接、文字或输入框。TouchAble 不保存文本内容、标题或输入内容。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("输入监控权限") {
                HStack {
                    Label(
                        controller.inputMonitoringTrusted ? "已授权" : "未授权",
                        systemImage: controller.inputMonitoringTrusted ? "checkmark.circle" : "exclamationmark.circle"
                    )

                    Spacer()

                    Button("打开授权提示") {
                        pulse(.control, "settings-input-monitoring-request")
                        controller.requestInputMonitoringPermission()
                    }
                    .disabled(controller.inputMonitoringTrusted)
                    .localPulse(zone: .control, identity: "settings-input-monitoring-button")
                }

                Text("操作触感需要监听全局点击、拖拽和滚动事件。TouchAble 只使用事件类型和位置，不记录输入内容。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 480)
    }

    private func pulse(_ zone: HapticZone, _ identity: String) {
        controller.pulseForLocalSurface(zone: zone, identity: identity)
    }
}
