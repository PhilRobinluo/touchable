import Foundation

public enum PulseDecision: Equatable {
    case allowed
    case quietZone
    case disabledZone(HapticZone)
    case sameIdentity
    case throttled(remaining: TimeInterval)

    public var displayReason: String {
        switch self {
        case .allowed:
            return "允许触发"
        case .quietZone:
            return "安静区域"
        case let .disabledZone(zone):
            return "\(zone.displayName) 已关闭"
        case .sameIdentity:
            return "同一对象内移动，避免重复触发"
        case let .throttled(remaining):
            return "节流中，还需 \(String(format: "%.2f", remaining))s"
        }
    }
}
