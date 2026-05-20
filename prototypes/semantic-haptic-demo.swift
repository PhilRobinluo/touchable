import ApplicationServices
import AppKit
import Foundation

let systemWide = AXUIElementCreateSystemWide()
let performer = NSHapticFeedbackManager.defaultPerformer
let duration: TimeInterval = CommandLine.arguments.dropFirst().first.flatMap(TimeInterval.init) ?? 45
let start = Date()
let minInterval: TimeInterval = 0.16

var lastSemanticZone = ""
var lastPulse = Date.distantPast

func attribute(_ element: AXUIElement, _ name: CFString) -> String? {
    var value: CFTypeRef?
    let error = AXUIElementCopyAttributeValue(element, name, &value)
    guard error == .success, let value else { return nil }
    return String(describing: value)
}

func elementAtMouse() -> AXUIElement? {
    let location = NSEvent.mouseLocation
    let mainHeight = NSScreen.screens.first?.frame.height ?? 0
    let topLeftY = mainHeight - location.y

    var element: AXUIElement?
    let error = AXUIElementCopyElementAtPosition(
        systemWide,
        Float(location.x),
        Float(topLeftY),
        &element
    )

    guard error == .success else { return nil }
    return element
}

func semanticZone(for role: String) -> String {
    switch role {
    case "AXButton", "AXMenuButton", "AXMenuItem", "AXCheckBox", "AXRadioButton", "AXPopUpButton":
        return "control"
    case "AXLink":
        return "link"
    case "AXTextField", "AXTextArea", "AXSearchField", "AXComboBox":
        return "input"
    case "AXStaticText":
        return "text"
    case "AXSlider", "AXIncrementor":
        return "adjustable"
    default:
        return "quiet"
    }
}

func pattern(for zone: String) -> NSHapticFeedbackManager.FeedbackPattern? {
    switch zone {
    case "control", "link":
        return .alignment
    case "input", "text", "adjustable":
        return .levelChange
    default:
        return nil
    }
}

print("Semantic haptic demo running for \(Int(duration))s.")
print("Move over buttons, links, text, and input areas. It pulses only when the semantic zone changes.")
print("Press Ctrl-C to stop early.")

while Date().timeIntervalSince(start) < duration {
    guard let element = elementAtMouse() else {
        Thread.sleep(forTimeInterval: 0.05)
        continue
    }

    let role = attribute(element, kAXRoleAttribute as CFString) ?? "unknown"
    let zone = semanticZone(for: role)
    let now = Date()

    if zone != lastSemanticZone && now.timeIntervalSince(lastPulse) >= minInterval {
        if let haptic = pattern(for: zone) {
            performer.perform(haptic, performanceTime: .now)
            print("pulse zone=\(zone) role=\(role)")
            lastPulse = now
        }
        lastSemanticZone = zone
    }

    Thread.sleep(forTimeInterval: 0.05)
}

print("Done.")
