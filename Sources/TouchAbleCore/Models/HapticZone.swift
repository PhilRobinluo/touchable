import Foundation

public enum HapticZone: String, CaseIterable, Codable, Hashable, Identifiable {
    case edge
    case control
    case link
    case input
    case text
    case adjustable
    case quiet

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .edge:
            return "屏幕边缘"
        case .control:
            return "按钮 / 菜单"
        case .link:
            return "链接"
        case .input:
            return "输入框"
        case .text:
            return "文字"
        case .adjustable:
            return "滑杆 / 调节"
        case .quiet:
            return "安静区域"
        }
    }
}
