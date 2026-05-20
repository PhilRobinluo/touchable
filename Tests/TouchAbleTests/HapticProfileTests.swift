import TouchAbleCore
import XCTest

final class HapticProfileTests: XCTestCase {
    func testGentleDefaults() {
        let profile = HapticProfile.default(for: .gentle)

        XCTAssertEqual(profile.minimumInterval, 0.28)
        XCTAssertEqual(profile.edgeBand, 22)
        XCTAssertEqual(profile.intensityLevel, 3)
        XCTAssertEqual(profile.pulseCount, 3)
        XCTAssertTrue(profile.enabledZones.contains(.edge))
        XCTAssertFalse(profile.enabledZones.contains(.text))
    }

    func testStandardDefaults() {
        let profile = HapticProfile.default(for: .standard)

        XCTAssertEqual(profile.minimumInterval, 0.18)
        XCTAssertEqual(profile.edgeBand, 28)
        XCTAssertEqual(profile.pulseSpacing, 0.055)
        XCTAssertTrue(profile.enabledZones.contains(.text))
    }

    func testObviousDefaults() {
        let profile = HapticProfile.default(for: .obvious)

        XCTAssertEqual(profile.minimumInterval, 0.12)
        XCTAssertEqual(profile.edgeBand, 40)
        XCTAssertTrue(profile.enabledZones.contains(.adjustable))
    }

    func testIntensityIsClampedAndControlsPulseCount() {
        let low = HapticProfile.default(for: .standard, intensityLevel: -3)
        let high = HapticProfile.default(for: .standard, intensityLevel: 99)

        XCTAssertEqual(low.intensityLevel, 1)
        XCTAssertEqual(low.pulseCount, 1)
        XCTAssertEqual(high.intensityLevel, 8)
        XCTAssertEqual(high.pulseCount, 8)
    }

    func testRepeatSameTargetEnablesRepeatInterval() {
        let off = HapticProfile.default(for: .standard, intensityLevel: 3, repeatSameTarget: false)
        let on = HapticProfile.default(for: .standard, intensityLevel: 3, repeatSameTarget: true)

        XCTAssertNil(off.sameIdentityRepeatInterval)
        XCTAssertEqual(on.sameIdentityRepeatInterval, 0.65)
    }

    func testRepeatSameTargetCanUseCustomHoverInterval() {
        let profile = HapticProfile.default(
            for: .standard,
            intensityLevel: 3,
            repeatSameTarget: true,
            sameTargetRepeatInterval: 1.1
        )

        XCTAssertEqual(profile.sameIdentityRepeatInterval, 1.1)
    }

    func testCustomHoverIntervalIsClampedForDebugSafety() {
        let tooFast = HapticProfile.default(
            for: .standard,
            repeatSameTarget: true,
            sameTargetRepeatInterval: 0.01
        )
        let tooSlow = HapticProfile.default(
            for: .standard,
            repeatSameTarget: true,
            sameTargetRepeatInterval: 9
        )

        XCTAssertEqual(tooFast.sameIdentityRepeatInterval, 0.25)
        XCTAssertEqual(tooSlow.sameIdentityRepeatInterval, 2.0)
    }

    func testHighIntensityUsesDensePulsesWithSafeRepeatFloor() {
        let profile = HapticProfile.default(for: .obvious, intensityLevel: 8, repeatSameTarget: true)

        XCTAssertEqual(profile.intensityLevel, 8)
        XCTAssertEqual(profile.pulseCount, 8)
        XCTAssertEqual(profile.pulseSpacing, 0.028)
        XCTAssertEqual(profile.sameIdentityRepeatInterval, 0.25)
    }
}
