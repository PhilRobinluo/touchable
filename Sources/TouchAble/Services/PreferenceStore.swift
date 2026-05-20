import Foundation
import TouchAbleCore

@MainActor
final class PreferenceStore: ObservableObject {
    private enum Key {
        static let isEnabled = "isEnabled"
        static let edgeHapticsEnabled = "edgeHapticsEnabled"
        static let pointerEventHapticsEnabled = "pointerEventHapticsEnabled"
        static let cursorHapticsEnabled = "cursorHapticsEnabled"
        static let semanticHapticsEnabled = "semanticHapticsEnabled"
        static let strength = "strength"
        static let intensityLevel = "intensityLevel"
        static let repeatSameTargetEnabled = "repeatSameTargetEnabled"
        static let hoverRepeatInterval = "hoverRepeatInterval"
        static let pointerPollingHertz = "pointerPollingHertz"
        static let hapticMinimumInterval = "hapticMinimumInterval"
        static let pointerEventDelay = "pointerEventDelay"
    }

    private let defaults: UserDefaults

    @Published var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Key.isEnabled) }
    }

    @Published var edgeHapticsEnabled: Bool {
        didSet { defaults.set(edgeHapticsEnabled, forKey: Key.edgeHapticsEnabled) }
    }

    @Published var pointerEventHapticsEnabled: Bool {
        didSet { defaults.set(pointerEventHapticsEnabled, forKey: Key.pointerEventHapticsEnabled) }
    }

    @Published var cursorHapticsEnabled: Bool {
        didSet { defaults.set(cursorHapticsEnabled, forKey: Key.cursorHapticsEnabled) }
    }

    @Published var semanticHapticsEnabled: Bool {
        didSet { defaults.set(semanticHapticsEnabled, forKey: Key.semanticHapticsEnabled) }
    }

    @Published var strength: HapticStrength {
        didSet { defaults.set(strength.rawValue, forKey: Key.strength) }
    }

    @Published var intensityLevel: Double {
        didSet { defaults.set(Int(intensityLevel.rounded()), forKey: Key.intensityLevel) }
    }

    @Published var repeatSameTargetEnabled: Bool {
        didSet { defaults.set(repeatSameTargetEnabled, forKey: Key.repeatSameTargetEnabled) }
    }

    @Published var hoverRepeatInterval: Double {
        didSet { defaults.set(hoverRepeatInterval, forKey: Key.hoverRepeatInterval) }
    }

    @Published var pointerPollingHertz: Double {
        didSet { defaults.set(pointerPollingHertz, forKey: Key.pointerPollingHertz) }
    }

    @Published var hapticMinimumInterval: Double {
        didSet { defaults.set(hapticMinimumInterval, forKey: Key.hapticMinimumInterval) }
    }

    @Published var pointerEventDelay: Double {
        didSet { defaults.set(pointerEventDelay, forKey: Key.pointerEventDelay) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        isEnabled = defaults.object(forKey: Key.isEnabled) as? Bool ?? true
        edgeHapticsEnabled = defaults.object(forKey: Key.edgeHapticsEnabled) as? Bool ?? true
        pointerEventHapticsEnabled = defaults.object(forKey: Key.pointerEventHapticsEnabled) as? Bool ?? true
        cursorHapticsEnabled = defaults.object(forKey: Key.cursorHapticsEnabled) as? Bool ?? true
        semanticHapticsEnabled = defaults.object(forKey: Key.semanticHapticsEnabled) as? Bool ?? true

        let rawStrength = defaults.string(forKey: Key.strength) ?? HapticStrength.standard.rawValue
        strength = HapticStrength(rawValue: rawStrength) ?? .standard

        let savedIntensity = defaults.object(forKey: Key.intensityLevel) as? Int ?? 5
        intensityLevel = Double(max(1, min(8, savedIntensity)))
        repeatSameTargetEnabled = defaults.object(forKey: Key.repeatSameTargetEnabled) as? Bool ?? false
        let savedHoverRepeatInterval = defaults.object(forKey: Key.hoverRepeatInterval) as? Double ?? 1.1
        hoverRepeatInterval = max(0.25, min(2.0, savedHoverRepeatInterval))
        let savedPollingHertz = defaults.object(forKey: Key.pointerPollingHertz) as? Double ?? 30
        pointerPollingHertz = max(10, min(80, savedPollingHertz))
        let savedMinimumInterval = defaults.object(forKey: Key.hapticMinimumInterval) as? Double ?? 0.08
        hapticMinimumInterval = max(0.04, min(0.35, savedMinimumInterval))
        let savedPointerEventDelay = defaults.object(forKey: Key.pointerEventDelay) as? Double ?? 0
        pointerEventDelay = max(0, min(0.2, savedPointerEventDelay))
    }

    var profile: HapticProfile {
        HapticProfile.default(
            for: strength,
            intensityLevel: Int(intensityLevel.rounded()),
            repeatSameTarget: repeatSameTargetEnabled,
            sameTargetRepeatInterval: hoverRepeatInterval,
            minimumIntervalOverride: hapticMinimumInterval
        )
    }

    var pointerPollingInterval: TimeInterval {
        1.0 / max(10, min(80, pointerPollingHertz))
    }
}
