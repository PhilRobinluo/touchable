import Foundation
import TouchAbleCore

@MainActor
final class PlaygroundHapticController: ObservableObject {
    private let haptics = HapticFeedbackService()
    private let throttler = HapticThrottler()

    func pulse(zone: HapticZone, identity: String, profile: HapticProfile) {
        let signal = HapticSignal(zone: zone, identity: "playground:\(identity)")
        guard throttler.shouldPulse(signal: signal, profile: profile) else { return }
        haptics.perform(zone: zone, profile: profile)
    }
}
