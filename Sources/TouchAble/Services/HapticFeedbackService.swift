import AppKit
import Foundation
import TouchAbleCore

final class HapticFeedbackService {
    private let performer = NSHapticFeedbackManager.defaultPerformer

    func perform(zone: HapticZone, profile: HapticProfile) {
        let patterns = patterns(for: zone, profile: profile)
        guard !patterns.isEmpty else { return }

        for index in 0..<profile.pulseCount {
            let delay = profile.pulseSpacing * Double(index)
            let pattern = patterns[index % patterns.count]
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [performer] in
                performer.perform(pattern, performanceTime: .now)
            }
        }
    }

    private func patterns(for zone: HapticZone, profile: HapticProfile) -> [NSHapticFeedbackManager.FeedbackPattern] {
        switch zone {
        case .edge, .control, .link:
            return profile.intensityLevel >= 6 ? [.alignment, .generic] : [.alignment]
        case .input, .text, .adjustable:
            return profile.intensityLevel >= 6 ? [.levelChange, .generic] : [.levelChange]
        case .quiet:
            return []
        }
    }
}
