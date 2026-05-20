import ApplicationServices
import Foundation

struct AccessibilityPermissionService {
    var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    func requestPermission() {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary

        _ = AXIsProcessTrustedWithOptions(options)
    }
}
