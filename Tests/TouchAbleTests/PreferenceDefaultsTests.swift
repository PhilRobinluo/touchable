import Testing
@testable import TouchAbleCore

struct PreferenceDefaultsTests {
    @Test func conservativeHapticDefaultsAvoidNoise() {
        #expect(PreferenceDefaults.scrollHapticsEnabled == false)
        #expect(PreferenceDefaults.repeatSameTargetEnabled == false)
        #expect(PreferenceDefaults.trackpadOnlyHapticsEnabled == true)
    }

    @Test func timingDefaultsStayWithinInteractiveBounds() {
        #expect(PreferenceDefaults.pointerPollingHertz == 30)
        #expect(PreferenceDefaults.hapticMinimumInterval == 0.08)
        #expect(PreferenceDefaults.pointerEventDelay == 0)
    }

    @Test func standardStrengthDefaultsAreModerate() {
        #expect(PreferenceDefaults.strength == .standard)
        #expect(PreferenceDefaults.intensityLevel == 5)
    }
}
