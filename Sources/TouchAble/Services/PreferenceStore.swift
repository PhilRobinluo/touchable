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
    }

    var profile: HapticProfile {
        HapticProfile.default(
            for: strength,
            intensityLevel: Int(intensityLevel.rounded()),
            repeatSameTarget: repeatSameTargetEnabled
        )
    }
}
