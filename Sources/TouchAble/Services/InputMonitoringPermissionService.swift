import CoreGraphics
import Foundation

struct InputMonitoringPermissionService {
    var isTrusted: Bool {
        CGPreflightListenEventAccess()
    }

    func requestPermission() -> Bool {
        CGRequestListenEventAccess()
    }
}
