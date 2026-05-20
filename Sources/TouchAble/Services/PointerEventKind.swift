import Foundation
import TouchAbleCore

enum PointerEventKind: String {
    case moved
    case pressed
    case dragged
    case scrolled
    case released

    var zone: HapticZone? {
        switch self {
        case .released:
            return .control
        case .dragged, .scrolled:
            return .adjustable
        case .moved, .pressed:
            return nil
        }
    }

    var hapticDelay: TimeInterval {
        switch self {
        case .released:
            return 0.08
        case .dragged, .scrolled:
            return 0
        case .moved, .pressed:
            return 0
        }
    }

    var displayName: String {
        switch self {
        case .moved:
            return "移动"
        case .pressed:
            return "点击"
        case .dragged:
            return "拖拽"
        case .scrolled:
            return "滚动"
        case .released:
            return "释放"
        }
    }
}
