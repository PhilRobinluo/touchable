import ApplicationServices
import Foundation

final class PointerEventTapService {
    var onEvent: ((PointerEventKind, CGPoint) -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let permission = InputMonitoringPermissionService()

    deinit {
        stop()
    }

    func start() -> Bool {
        guard eventTap == nil else { return true }
        guard permission.isTrusted else { return false }

        let mask =
            (1 << CGEventType.leftMouseDown.rawValue) |
            (1 << CGEventType.leftMouseUp.rawValue) |
            (1 << CGEventType.leftMouseDragged.rawValue) |
            (1 << CGEventType.rightMouseDown.rawValue) |
            (1 << CGEventType.rightMouseUp.rawValue) |
            (1 << CGEventType.rightMouseDragged.rawValue) |
            (1 << CGEventType.otherMouseDown.rawValue) |
            (1 << CGEventType.otherMouseUp.rawValue) |
            (1 << CGEventType.otherMouseDragged.rawValue) |
            (1 << CGEventType.scrollWheel.rawValue)

        let userInfo = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: PointerEventTapService.callback,
            userInfo: userInfo
        ) else {
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        eventTap = tap
        runLoopSource = source
        return true
    }

    func stop() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }

        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil
    }

    private static let callback: CGEventTapCallBack = { _, type, event, userInfo in
        guard let userInfo else {
            return Unmanaged.passUnretained(event)
        }

        let service = Unmanaged<PointerEventTapService>
            .fromOpaque(userInfo)
            .takeUnretainedValue()

        guard let kind = PointerEventKind(type: type) else {
            return Unmanaged.passUnretained(event)
        }

        let location = event.location
        DispatchQueue.main.async {
            service.onEvent?(kind, location)
        }

        return Unmanaged.passUnretained(event)
    }
}

private extension PointerEventKind {
    init?(type: CGEventType) {
        switch type {
        case .mouseMoved:
            self = .moved
        case .leftMouseDown, .rightMouseDown, .otherMouseDown:
            self = .pressed
        case .leftMouseUp, .rightMouseUp, .otherMouseUp:
            self = .released
        case .leftMouseDragged, .rightMouseDragged, .otherMouseDragged:
            self = .dragged
        case .scrollWheel:
            self = .scrolled
        default:
            return nil
        }
    }
}
