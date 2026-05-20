import ApplicationServices
import AppKit
import Foundation

let systemWide = AXUIElementCreateSystemWide()
let duration: TimeInterval = CommandLine.arguments.dropFirst().first.flatMap(TimeInterval.init) ?? 30
let start = Date()

func attribute(_ element: AXUIElement, _ name: CFString) -> String? {
    var value: CFTypeRef?
    let error = AXUIElementCopyAttributeValue(element, name, &value)
    guard error == .success, let value else { return nil }
    return String(describing: value)
}

func roleAtMouse() -> (role: String, title: String, description: String)? {
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

    guard error == .success, let element else {
        return nil
    }

    let role = attribute(element, kAXRoleAttribute as CFString) ?? "unknown"
    let title = attribute(element, kAXTitleAttribute as CFString) ?? ""
    let description = attribute(element, kAXDescriptionAttribute as CFString) ?? ""
    return (role, title, description)
}

print("Semantic probe running for \(Int(duration))s.")
print("Move the cursor over buttons, text, links, inputs, Finder items, browser UI, etc.")
print("If everything is unknown, grant Accessibility permission to Terminal/Codex and run again.")
print("Press Ctrl-C to stop early.")

var lastSignature = ""

while Date().timeIntervalSince(start) < duration {
    if let hit = roleAtMouse() {
        let title = hit.title.prefix(40)
        let desc = hit.description.prefix(40)
        let signature = "\(hit.role)|\(title)|\(desc)"

        if signature != lastSignature {
            print("role=\(hit.role) title=\(title) desc=\(desc)")
            lastSignature = signature
        }
    }

    Thread.sleep(forTimeInterval: 0.12)
}

print("Done.")
