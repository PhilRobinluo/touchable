import Foundation

public final class HapticThrottler {
    private var lastIdentity: String?
    private var lastPulseDate: Date = .distantPast

    public init() {}

    public func decision(
        for signal: HapticSignal,
        profile: HapticProfile,
        now: Date = Date()
    ) -> PulseDecision {
        guard signal.zone != .quiet else {
            return .quietZone
        }

        guard profile.enabledZones.contains(signal.zone) else {
            return .disabledZone(signal.zone)
        }

        let elapsed = now.timeIntervalSince(lastPulseDate)

        if signal.identity == lastIdentity {
            guard let repeatInterval = profile.sameIdentityRepeatInterval else {
                return .sameIdentity
            }

            let requiredInterval = max(profile.minimumInterval, repeatInterval)
            guard elapsed >= requiredInterval else {
                return .throttled(remaining: requiredInterval - elapsed)
            }

            return .allowed
        }

        guard elapsed >= profile.minimumInterval else {
            return .throttled(remaining: profile.minimumInterval - elapsed)
        }

        return .allowed
    }

    public func shouldPulse(
        signal: HapticSignal,
        profile: HapticProfile,
        now: Date = Date()
    ) -> Bool {
        guard decision(for: signal, profile: profile, now: now) == .allowed else {
            return false
        }

        lastIdentity = signal.identity
        lastPulseDate = now
        return true
    }

    public func reset() {
        lastIdentity = nil
        lastPulseDate = .distantPast
    }
}
