import SwiftUI
import TouchAbleCore

struct DebugView: View {
    @EnvironmentObject private var preferences: PreferenceStore
    @EnvironmentObject private var controller: TouchAbleController

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    statusGrid
                    tuningPanel
                    testPanel
                    eventList
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "waveform.path.ecg")
                .font(.title2)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text("TouchAble Debug")
                    .font(.title2.weight(.semibold))
                Text("边摸边看：这里会显示识别、节流和触发状态")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("清空日志") {
                controller.clearDebugEvents()
            }
        }
        .padding(16)
    }

    private var statusGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            alignment: .leading,
            spacing: 12
        ) {
            DebugMetricCard(title: "总开关", value: preferences.isEnabled ? "开启" : "关闭", icon: preferences.isEnabled ? "power.circle.fill" : "power.circle")
            DebugMetricCard(title: "辅助功能", value: controller.accessibilityTrusted ? "已授权" : "未授权", icon: controller.accessibilityTrusted ? "checkmark.shield.fill" : "exclamationmark.shield")
            DebugMetricCard(title: "输入监控", value: controller.inputMonitoringTrusted ? "已授权" : "未授权", icon: controller.inputMonitoringTrusted ? "checkmark.circle.fill" : "exclamationmark.circle")
            DebugMetricCard(title: "鼠标位置", value: controller.pointerDescription, icon: "cursorarrow.motionlines")
            DebugMetricCard(title: "最近操作", value: controller.pointerEventDescription, icon: "computermouse")
            DebugMetricCard(title: "三指快捷键", value: controller.threeFingerShortcutDescription, icon: "hand.tap")
            DebugMetricCard(title: "当前光标", value: controller.cursorDescription, icon: "cursorarrow.click.2")
            DebugMetricCard(title: "当前 AX Role", value: controller.semanticRole, icon: "viewfinder")
            DebugMetricCard(title: "候选触觉", value: controller.candidateDescription, icon: "target")
            DebugMetricCard(title: "节流判断", value: controller.lastDecision, icon: "speedometer")
            DebugMetricCard(title: "当前参数", value: controller.profileDescription, icon: "slider.horizontal.3")
            DebugMetricCard(title: "最后触发", value: controller.lastPulseDescription, icon: "waveform")
            DebugMetricCard(title: "触发次数", value: "\(controller.pulseCount)", icon: "number")
        }
    }

    private var tuningPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("手感调试")
                    .font(.headline)
                Text("v0.x 先完全打开调参。轮询越高越跟手，也越可能吃 CPU。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Picker("手感预设", selection: $preferences.strength) {
                ForEach(HapticStrength.allCases) { strength in
                    Text(strength.displayName).tag(strength)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 12) {
                Text("触感强度")
                    .frame(width: 72, alignment: .leading)

                Slider(value: $preferences.intensityLevel, in: 1...8, step: 1)

                Text("\(Int(preferences.intensityLevel.rounded()))")
                    .font(.body.monospacedDigit())
                    .frame(width: 24, alignment: .trailing)
            }

            Toggle("悬停保持时重复触发", isOn: $preferences.repeatSameTargetEnabled)
            if preferences.repeatSameTargetEnabled {
                HStack(spacing: 12) {
                    Text("重复间隔")
                        .frame(width: 72, alignment: .leading)

                    Slider(value: $preferences.hoverRepeatInterval, in: 0.25...2.0, step: 0.05)

                    Text(String(format: "%.2fs", preferences.hoverRepeatInterval))
                        .font(.body.monospacedDigit())
                        .frame(width: 52, alignment: .trailing)
                }
            }

            Divider()

            HStack(spacing: 12) {
                Text("光标轮询")
                    .frame(width: 72, alignment: .leading)

                Slider(value: $preferences.pointerPollingHertz, in: 10...80, step: 5)

                Text("\(Int(preferences.pointerPollingHertz.rounded()))Hz")
                    .font(.body.monospacedDigit())
                    .frame(width: 52, alignment: .trailing)
            }

            HStack(spacing: 12) {
                Text("节流间隔")
                    .frame(width: 72, alignment: .leading)

                Slider(value: $preferences.hapticMinimumInterval, in: 0.04...0.35, step: 0.01)

                Text(String(format: "%.2fs", preferences.hapticMinimumInterval))
                    .font(.body.monospacedDigit())
                    .frame(width: 52, alignment: .trailing)
            }

            HStack(spacing: 12) {
                Text("操作延时")
                    .frame(width: 72, alignment: .leading)

                Slider(value: $preferences.pointerEventDelay, in: 0...0.2, step: 0.01)

                Text(String(format: "%.2fs", preferences.pointerEventDelay))
                    .font(.body.monospacedDigit())
                    .frame(width: 52, alignment: .trailing)
            }

            Toggle("启用点击 / 拖拽触感", isOn: $preferences.pointerEventHapticsEnabled)
            Toggle("启用滚动触感", isOn: $preferences.scrollHapticsEnabled)
            Toggle("启用光标形状触感", isOn: $preferences.cursorHapticsEnabled)
            Toggle("启用三指按下快捷键", isOn: $preferences.threeFingerShortcutEnabled)

            if !controller.inputMonitoringTrusted {
                Button {
                    controller.requestInputMonitoringPermission()
                } label: {
                    Label("申请输入监控权限", systemImage: "cursorarrow.click")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var testPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("触觉测试")
                    .font(.headline)
                Text("这些按钮绕过识别链路，直接测试触觉硬件和手感映射。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button {
                    controller.testPulse(zone: .edge)
                } label: {
                    Label("边缘", systemImage: "rectangle.inset.filled")
                }

                Button {
                    controller.testPulse(zone: .control)
                } label: {
                    Label("按钮", systemImage: "button.programmable")
                }

                Button {
                    controller.testPulse(zone: .text)
                } label: {
                    Label("文字", systemImage: "text.alignleft")
                }

                Button {
                    controller.testPulse(zone: .input)
                } label: {
                    Label("输入框", systemImage: "keyboard")
                }

                Button {
                    controller.testPulse(zone: .adjustable)
                } label: {
                    Label("滑杆", systemImage: "slider.horizontal.3")
                }
            }
            .buttonStyle(.bordered)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var eventList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("事件流")
                .font(.headline)

            if controller.debugEvents.isEmpty {
                Text("还没有触发事件。先点上面的测试按钮，或把光标滑到屏幕边缘 / Playground 组件上。")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            } else {
                VStack(spacing: 0) {
                    ForEach(controller.debugEvents) { event in
                        DebugEventRow(event: event)
                        if event.id != controller.debugEvents.last?.id {
                            Divider()
                        }
                    }
                }
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

private struct DebugMetricCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body.monospacedDigit())
                    .lineLimit(2)
                    .textSelection(.enabled)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 74, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct DebugEventRow: View {
    let event: DebugEvent

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(event.timestamp)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 86, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.body.weight(.medium))
                Text(event.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .textSelection(.enabled)
            }

            Spacer()

            if let zone = event.zone {
                Text(zone.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.tertiary, in: Capsule())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }
}
