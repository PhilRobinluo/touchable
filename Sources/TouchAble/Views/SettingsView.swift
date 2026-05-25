import AppKit
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
                Toggle("点击 / 拖拽触感", isOn: $preferences.pointerEventHapticsEnabled)
                    .localPulse(zone: .control, identity: "settings-pointer-event")
                    .onChange(of: preferences.pointerEventHapticsEnabled) { _, _ in
                        pulse(.control, "settings-pointer-event-change")
                    }
                Toggle("滚动触感", isOn: $preferences.scrollHapticsEnabled)
                    .localPulse(zone: .control, identity: "settings-scroll")
                    .onChange(of: preferences.scrollHapticsEnabled) { _, _ in
                        pulse(.control, "settings-scroll-change")
                    }
                Toggle("仅触控板触发", isOn: $preferences.trackpadOnlyHapticsEnabled)
                    .localPulse(zone: .control, identity: "settings-trackpad-only")
                    .onChange(of: preferences.trackpadOnlyHapticsEnabled) { _, _ in
                        pulse(.control, "settings-trackpad-only-change")
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
                Toggle("三指按下快捷键", isOn: $preferences.threeFingerShortcutEnabled)
                    .localPulse(zone: .control, identity: "settings-three-finger-shortcut")
                    .onChange(of: preferences.threeFingerShortcutEnabled) { _, _ in
                        pulse(.control, "settings-three-finger-shortcut-change")
                    }
            }

            Section("三指快捷键") {
                Picker("按键", selection: $preferences.threeFingerShortcutKey) {
                    ForEach(KeyboardShortcutKey.allCases) { key in
                        Text(key.displayName).tag(key)
                    }
                }
                .localPulse(zone: .control, identity: "settings-three-finger-key")

                HStack {
                    Toggle("⌘", isOn: modifierBinding(.command))
                    Toggle("⌥", isOn: modifierBinding(.option))
                    Toggle("⌃", isOn: modifierBinding(.control))
                    Toggle("⇧", isOn: modifierBinding(.shift))
                }
                .toggleStyle(.button)

                HStack {
                    Text("当前映射")
                    Spacer()
                    Text(preferences.threeFingerShortcut.displayName)
                        .font(.body.monospaced())
                        .foregroundStyle(.secondary)
                }

                Button {
                    pulse(.control, "settings-three-finger-test-shortcut")
                    controller.testThreeFingerShortcut()
                } label: {
                    Label("测试发送当前快捷键", systemImage: "keyboard")
                }
                .disabled(!preferences.threeFingerShortcut.isValid)

                Text("开启后，触摸板三根手指同时落下会发送上面的快捷键。这个功能需要系统把三指触摸事件交给 App；如果某个三指手势已被系统占用，可能需要先在系统设置里避开冲突。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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

                Toggle("悬停保持时重复触发", isOn: $preferences.repeatSameTargetEnabled)
                    .localPulse(zone: .control, identity: "settings-repeat")
                    .onChange(of: preferences.repeatSameTargetEnabled) { _, _ in
                        pulse(.control, "settings-repeat-change")
                    }

                if preferences.repeatSameTargetEnabled {
                    HStack {
                        Text("重复间隔")
                        Slider(value: $preferences.hoverRepeatInterval, in: 0.25...2.0, step: 0.05) {
                            Text("重复间隔")
                        }
                        .localPulse(zone: .adjustable, identity: "settings-repeat-interval")
                        .onChange(of: preferences.hoverRepeatInterval) { _, newValue in
                            pulse(.adjustable, "settings-repeat-interval-\(Int((newValue * 100).rounded()))")
                        }
                        Text(String(format: "%.2fs", preferences.hoverRepeatInterval))
                            .monospacedDigit()
                            .frame(width: 48, alignment: .trailing)
                    }
                }

                Text("悬停重复默认关闭，避免光标停在按钮上一直震。仅触控板触发默认开启：使用鼠标移动、点击或滚动时不会触发全局触感。公开 API 不支持直接调电机力度；这里通过更多脉冲、更紧节奏和混合模式模拟强弱。6-8 档偏调试增强。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("响应调试") {
                HStack {
                    Text("光标轮询")
                    Slider(value: $preferences.pointerPollingHertz, in: 10...80, step: 5) {
                        Text("光标轮询")
                    }
                    .localPulse(zone: .adjustable, identity: "settings-polling-rate")
                    Text("\(Int(preferences.pointerPollingHertz.rounded()))Hz")
                        .monospacedDigit()
                        .frame(width: 48, alignment: .trailing)
                }

                HStack {
                    Text("节流间隔")
                    Slider(value: $preferences.hapticMinimumInterval, in: 0.04...0.35, step: 0.01) {
                        Text("节流间隔")
                    }
                    .localPulse(zone: .adjustable, identity: "settings-minimum-interval")
                    Text(String(format: "%.2fs", preferences.hapticMinimumInterval))
                        .monospacedDigit()
                        .frame(width: 48, alignment: .trailing)
                }

                HStack {
                    Text("操作延时")
                    Slider(value: $preferences.pointerEventDelay, in: 0...0.2, step: 0.01) {
                        Text("操作延时")
                    }
                    .localPulse(zone: .adjustable, identity: "settings-event-delay")
                    Text(String(format: "%.2fs", preferences.pointerEventDelay))
                        .monospacedDigit()
                        .frame(width: 48, alignment: .trailing)
                }

                Text("v0.x 先把跟手感完全打开给我们调。轮询越高越跟手，也越可能吃 CPU；节流越短越敏感，也越容易密。")
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

                Text("点击 / 拖拽触感需要监听全局鼠标事件；滚动触感有单独开关，默认关闭。TouchAble 只使用事件类型和位置，不记录输入内容。")
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

    private func modifierBinding(_ flag: NSEvent.ModifierFlags) -> Binding<Bool> {
        Binding {
            preferences.threeFingerShortcutModifiers.contains(flag)
        } set: { isOn in
            if isOn {
                preferences.threeFingerShortcutModifiers.insert(flag)
            } else {
                preferences.threeFingerShortcutModifiers.remove(flag)
            }
            pulse(.control, "settings-three-finger-modifier")
        }
    }
}
