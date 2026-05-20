import AppKit
import Foundation

let performer = NSHapticFeedbackManager.defaultPerformer
let screens = NSScreen.screens
let frame = screens.first?.frame ?? .zero

let edgeBand: CGFloat = 28
let gridColumns = 3
let gridRows = 2
let minInterval: TimeInterval = 0.18
let duration: TimeInterval = CommandLine.arguments.dropFirst().first.flatMap(TimeInterval.init) ?? 30

var lastZone = ""
var lastPulse = Date.distantPast
let start = Date()

func zone(for point: NSPoint) -> String {
    let x = point.x - frame.minX
    let y = point.y - frame.minY

    if x <= edgeBand { return "left-edge" }
    if x >= frame.width - edgeBand { return "right-edge" }
    if y <= edgeBand { return "bottom-edge" }
    if y >= frame.height - edgeBand { return "top-edge" }

    let column = max(0, min(gridColumns - 1, Int((x / frame.width) * CGFloat(gridColumns))))
    let row = max(0, min(gridRows - 1, Int((y / frame.height) * CGFloat(gridRows))))
    return "cell-\(column)-\(row)"
}

print("Edge haptic demo running for \(Int(duration))s.")
print("Move the cursor with the trackpad. Feel for pulses near screen edges and when crossing grid regions.")
print("Press Ctrl-C to stop early.")

while Date().timeIntervalSince(start) < duration {
    let current = zone(for: NSEvent.mouseLocation)
    let now = Date()

    if current != lastZone && now.timeIntervalSince(lastPulse) >= minInterval {
        let pattern: NSHapticFeedbackManager.FeedbackPattern =
            current.contains("edge") ? .alignment : .levelChange
        performer.perform(pattern, performanceTime: .now)
        lastPulse = now
        lastZone = current
    }

    Thread.sleep(forTimeInterval: 0.025)
}

print("Done.")
