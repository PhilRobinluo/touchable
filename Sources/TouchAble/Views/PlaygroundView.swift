import SwiftUI
import TouchAbleCore

struct PlaygroundView: View {
    @EnvironmentObject private var preferences: PreferenceStore
    @EnvironmentObject private var controller: TouchAbleController

    @StateObject private var playgroundHaptics = PlaygroundHapticController()
    @State private var text = "把光标滑过这里，感受输入区域"
    @State private var sliderValue = 4.0

    private let columns = [
        GridItem(.adaptive(minimum: 92), spacing: 10)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                controlsDemo
                textDemo
                sliderDemo
                edgeDemo
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .environmentObject(playgroundHaptics)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TouchAble Playground")
                .font(.largeTitle.weight(.semibold))

            Text("这个窗口不依赖辅助功能权限，用来稳定体验按钮、文字、输入框、滑杆和边缘触感。")
                .foregroundStyle(.secondary)
        }
    }

    private var controlsDemo: some View {
        PlaygroundSection(title: "按钮和链接", subtitle: "进入可操作对象时给一个轻确认感") {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                ForEach(1...8, id: \.self) { index in
                    Button("按钮 \(index)") {}
                        .buttonStyle(.borderedProminent)
                        .playgroundPulse(zone: .control, identity: "button-\(index)")
                }
            }

            Link("示例链接", destination: URL(string: "https://www.apple.com")!)
                .playgroundPulse(zone: .link, identity: "link-demo")
        }
    }

    private var textDemo: some View {
        PlaygroundSection(title: "文字和输入框", subtitle: "进入文字区和输入区时给出更细的层级感") {
            Text("按钮像实体开关，文字像纸面区域，输入框像可以落笔的地方。TouchAble 要做的是这种很轻、很准的触觉标点。")
                .lineSpacing(4)
                .foregroundStyle(.primary)
                .playgroundPulse(zone: .text, identity: "text-paragraph")

            TextField("输入框", text: $text)
                .textFieldStyle(.roundedBorder)
                .playgroundPulse(zone: .input, identity: "input-field")
        }
    }

    private var sliderDemo: some View {
        PlaygroundSection(title: "滑杆刻度", subtitle: "跨过离散等级时给一个层级变化感") {
            Slider(value: $sliderValue, in: 0...10, step: 1)
                .onChange(of: sliderValue) { _, newValue in
                    playgroundHaptics.pulse(
                        zone: .adjustable,
                        identity: "slider-\(Int(newValue))",
                        profile: preferences.profile
                    )
                }

            Text("当前刻度 \(Int(sliderValue))")
                .foregroundStyle(.secondary)
        }
    }

    private var edgeDemo: some View {
        PlaygroundSection(title: "边缘吸附", subtitle: "靠近容器边界时模拟屏幕墙面感") {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.secondary.opacity(0.45), lineWidth: 1)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))

                Text("滑到四条边缘试试")
                    .foregroundStyle(.secondary)

                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: 28)
                        .playgroundPulse(zone: .edge, identity: "playground-top-edge")
                    Spacer(minLength: 0)
                    Color.clear
                        .frame(height: 28)
                        .playgroundPulse(zone: .edge, identity: "playground-bottom-edge")
                }

                HStack(spacing: 0) {
                    Color.clear
                        .frame(width: 28)
                        .playgroundPulse(zone: .edge, identity: "playground-left-edge")
                    Spacer(minLength: 0)
                    Color.clear
                        .frame(width: 28)
                        .playgroundPulse(zone: .edge, identity: "playground-right-edge")
                }
            }
            .frame(height: 180)
        }
    }
}

private struct PlaygroundSection<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            content
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
