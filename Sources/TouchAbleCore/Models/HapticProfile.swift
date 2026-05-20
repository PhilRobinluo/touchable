import CoreGraphics
import Foundation

public struct HapticProfile: Equatable {
    public let strength: HapticStrength
    public let minimumInterval: TimeInterval
    public let edgeBand: CGFloat
    public let enabledZones: Set<HapticZone>
    public let intensityLevel: Int
    public let pulseCount: Int
    public let pulseSpacing: TimeInterval
    public let sameIdentityRepeatInterval: TimeInterval?

    public init(
        strength: HapticStrength,
        minimumInterval: TimeInterval,
        edgeBand: CGFloat,
        enabledZones: Set<HapticZone>,
        intensityLevel: Int = 3,
        pulseCount: Int = 1,
        pulseSpacing: TimeInterval = 0.06,
        sameIdentityRepeatInterval: TimeInterval? = nil
    ) {
        self.strength = strength
        self.minimumInterval = minimumInterval
        self.edgeBand = edgeBand
        self.enabledZones = enabledZones
        self.intensityLevel = intensityLevel
        self.pulseCount = pulseCount
        self.pulseSpacing = pulseSpacing
        self.sameIdentityRepeatInterval = sameIdentityRepeatInterval
    }

    public static func `default`(
        for strength: HapticStrength,
        intensityLevel: Int = 3,
        repeatSameTarget: Bool = false,
        sameTargetRepeatInterval: TimeInterval? = nil
    ) -> HapticProfile {
        let clampedIntensity = max(1, min(8, intensityLevel))
        let repeatInterval = repeatSameTarget
            ? max(0.25, min(2.0, sameTargetRepeatInterval ?? defaultSameIdentityRepeatInterval(for: clampedIntensity)))
            : nil

        switch strength {
        case .gentle:
            return HapticProfile(
                strength: strength,
                minimumInterval: 0.28,
                edgeBand: 22,
                enabledZones: [.edge, .control, .link, .input, .adjustable],
                intensityLevel: clampedIntensity,
                pulseCount: pulseCount(for: clampedIntensity),
                pulseSpacing: pulseSpacing(for: clampedIntensity),
                sameIdentityRepeatInterval: repeatInterval
            )
        case .standard:
            return HapticProfile(
                strength: strength,
                minimumInterval: 0.18,
                edgeBand: 28,
                enabledZones: [.edge, .control, .link, .input, .text, .adjustable],
                intensityLevel: clampedIntensity,
                pulseCount: pulseCount(for: clampedIntensity),
                pulseSpacing: pulseSpacing(for: clampedIntensity),
                sameIdentityRepeatInterval: repeatInterval
            )
        case .obvious:
            return HapticProfile(
                strength: strength,
                minimumInterval: 0.12,
                edgeBand: 40,
                enabledZones: [.edge, .control, .link, .input, .text, .adjustable],
                intensityLevel: clampedIntensity,
                pulseCount: pulseCount(for: clampedIntensity),
                pulseSpacing: pulseSpacing(for: clampedIntensity),
                sameIdentityRepeatInterval: repeatInterval
            )
        }
    }

    private static func pulseCount(for intensityLevel: Int) -> Int {
        switch intensityLevel {
        case 1:
            return 1
        case 2:
            return 2
        case 3:
            return 3
        case 4:
            return 4
        case 5:
            return 5
        case 6:
            return 6
        case 7:
            return 7
        default:
            return 8
        }
    }

    private static func pulseSpacing(for intensityLevel: Int) -> TimeInterval {
        switch intensityLevel {
        case 1:
            return 0.075
        case 2:
            return 0.065
        case 3:
            return 0.055
        case 4:
            return 0.045
        case 5:
            return 0.038
        case 6:
            return 0.034
        case 7:
            return 0.031
        default:
            return 0.028
        }
    }

    private static func defaultSameIdentityRepeatInterval(for intensityLevel: Int) -> TimeInterval {
        switch intensityLevel {
        case 1:
            return 1.2
        case 2:
            return 0.9
        case 3:
            return 0.65
        case 4:
            return 0.45
        case 5:
            return 0.3
        case 6:
            return 0.22
        case 7:
            return 0.16
        default:
            return 0.12
        }
    }
}
