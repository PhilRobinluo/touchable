import Foundation

public enum PreferenceDefaults {
    public static let isEnabled = true
    public static let edgeHapticsEnabled = true
    public static let pointerEventHapticsEnabled = true
    public static let scrollHapticsEnabled = false
    public static let trackpadOnlyHapticsEnabled = true
    public static let cursorHapticsEnabled = true
    public static let semanticHapticsEnabled = true
    public static let strength = HapticStrength.standard
    public static let intensityLevel = 5
    public static let repeatSameTargetEnabled = false
    public static let hoverRepeatInterval: TimeInterval = 1.1
    public static let pointerPollingHertz = 30.0
    public static let hapticMinimumInterval: TimeInterval = 0.08
    public static let pointerEventDelay: TimeInterval = 0
}
