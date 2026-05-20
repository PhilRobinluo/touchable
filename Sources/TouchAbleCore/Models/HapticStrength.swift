import Foundation

public enum HapticStrength: String, CaseIterable, Codable, Hashable, Identifiable {
    case gentle
    case standard
    case obvious

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .gentle:
            return "轻柔"
        case .standard:
            return "标准"
        case .obvious:
            return "明显"
        }
    }

    public var detail: String {
        switch self {
        case .gentle:
            return "更克制，适合长期打开"
        case .standard:
            return "默认手感，平衡清晰和安静"
        case .obvious:
            return "更明显，适合演示和调参"
        }
    }
}
