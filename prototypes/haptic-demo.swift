import AppKit
import Foundation

let performer = NSHapticFeedbackManager.defaultPerformer

func pulse(_ pattern: NSHapticFeedbackManager.FeedbackPattern, count: Int, interval: TimeInterval) {
    for _ in 0..<count {
        performer.perform(pattern, performanceTime: .now)
        Thread.sleep(forTimeInterval: interval)
    }
}

let mode = CommandLine.arguments.dropFirst().first ?? "ramp"

switch mode {
case "generic":
    pulse(.generic, count: 10, interval: 0.16)
case "align":
    pulse(.alignment, count: 8, interval: 0.22)
case "level":
    pulse(.levelChange, count: 12, interval: 0.12)
case "ramp":
    for interval in [0.28, 0.22, 0.18, 0.14, 0.11, 0.09, 0.11, 0.14, 0.18, 0.22] {
        performer.perform(.levelChange, performanceTime: .now)
        Thread.sleep(forTimeInterval: interval)
    }
default:
    print("Usage: swift haptic-demo.swift [ramp|generic|align|level]")
}
