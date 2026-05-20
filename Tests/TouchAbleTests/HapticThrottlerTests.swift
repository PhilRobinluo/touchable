import TouchAbleCore
import XCTest

final class HapticThrottlerTests: XCTestCase {
    func testAllowsFirstPulseThenBlocksSameIdentity() {
        let throttler = HapticThrottler()
        let profile = HapticProfile.default(for: .standard)
        let now = Date(timeIntervalSince1970: 100)
        let signal = HapticSignal(zone: .control, identity: "button-1")

        XCTAssertTrue(throttler.shouldPulse(signal: signal, profile: profile, now: now))
        XCTAssertFalse(throttler.shouldPulse(signal: signal, profile: profile, now: now.addingTimeInterval(1)))
    }

    func testBlocksDifferentIdentityInsideInterval() {
        let throttler = HapticThrottler()
        let profile = HapticProfile.default(for: .standard)
        let now = Date(timeIntervalSince1970: 100)

        XCTAssertTrue(throttler.shouldPulse(signal: HapticSignal(zone: .control, identity: "button-1"), profile: profile, now: now))
        XCTAssertFalse(throttler.shouldPulse(signal: HapticSignal(zone: .input, identity: "input-1"), profile: profile, now: now.addingTimeInterval(0.05)))
    }

    func testAllowsDifferentIdentityAfterInterval() {
        let throttler = HapticThrottler()
        let profile = HapticProfile.default(for: .standard)
        let now = Date(timeIntervalSince1970: 100)

        XCTAssertTrue(throttler.shouldPulse(signal: HapticSignal(zone: .control, identity: "button-1"), profile: profile, now: now))
        XCTAssertTrue(throttler.shouldPulse(signal: HapticSignal(zone: .input, identity: "input-1"), profile: profile, now: now.addingTimeInterval(0.2)))
    }

    func testResetAllowsSameIdentityAgain() {
        let throttler = HapticThrottler()
        let profile = HapticProfile.default(for: .standard)
        let now = Date(timeIntervalSince1970: 100)
        let signal = HapticSignal(zone: .edge, identity: "left-edge")

        XCTAssertTrue(throttler.shouldPulse(signal: signal, profile: profile, now: now))
        throttler.reset()
        XCTAssertTrue(throttler.shouldPulse(signal: signal, profile: profile, now: now.addingTimeInterval(0.2)))
    }

    func testDecisionReportsWhySignalIsBlocked() {
        let throttler = HapticThrottler()
        let profile = HapticProfile.default(for: .gentle)
        let now = Date(timeIntervalSince1970: 100)

        XCTAssertEqual(
            throttler.decision(for: HapticSignal(zone: .quiet, identity: "quiet"), profile: profile, now: now),
            .quietZone
        )

        XCTAssertEqual(
            throttler.decision(for: HapticSignal(zone: .text, identity: "text"), profile: profile, now: now),
            .disabledZone(.text)
        )

        let signal = HapticSignal(zone: .control, identity: "button")
        XCTAssertTrue(throttler.shouldPulse(signal: signal, profile: profile, now: now))
        XCTAssertEqual(throttler.decision(for: signal, profile: profile, now: now.addingTimeInterval(1)), .sameIdentity)

        let nextSignal = HapticSignal(zone: .input, identity: "input")
        if case .throttled = throttler.decision(for: nextSignal, profile: profile, now: now.addingTimeInterval(0.1)) {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected throttled decision")
        }
    }

    func testSameIdentityCanRepeatWhenEnabled() {
        let throttler = HapticThrottler()
        let profile = HapticProfile.default(for: .standard, intensityLevel: 5, repeatSameTarget: true)
        let now = Date(timeIntervalSince1970: 100)
        let signal = HapticSignal(zone: .control, identity: "same-button")

        XCTAssertTrue(throttler.shouldPulse(signal: signal, profile: profile, now: now))
        XCTAssertFalse(throttler.shouldPulse(signal: signal, profile: profile, now: now.addingTimeInterval(0.1)))
        XCTAssertTrue(throttler.shouldPulse(signal: signal, profile: profile, now: now.addingTimeInterval(0.31)))
    }
}
