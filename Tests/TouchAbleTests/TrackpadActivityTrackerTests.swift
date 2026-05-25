import Foundation
import Testing
@testable import TouchAbleCore

struct TrackpadActivityTrackerTests {
    @Test func contactMovementMarksTrackpadActive() {
        let tracker = TrackpadActivityTracker()
        let now = Date()

        tracker.update(
            contacts: [TrackpadContactSample(identifier: 1, x: 0.1, y: 0.1)],
            now: now
        )
        tracker.update(
            contacts: [TrackpadContactSample(identifier: 1, x: 0.12, y: 0.1)],
            now: now.addingTimeInterval(0.05)
        )

        #expect(tracker.hasRecentTrackpadActivity(now: now.addingTimeInterval(0.5)))
    }

    @Test func stationaryContactDoesNotMarkTrackpadActive() {
        let tracker = TrackpadActivityTracker()
        let now = Date()

        tracker.update(
            contacts: [TrackpadContactSample(identifier: 1, x: 0.1, y: 0.1)],
            now: now
        )
        tracker.update(
            contacts: [TrackpadContactSample(identifier: 1, x: 0.1002, y: 0.1001)],
            now: now.addingTimeInterval(0.05)
        )

        #expect(!tracker.hasRecentTrackpadActivity(now: now.addingTimeInterval(0.1)))
    }

    @Test func staleTrackpadActivityExpires() {
        let tracker = TrackpadActivityTracker()
        let now = Date()

        tracker.update(
            contacts: [TrackpadContactSample(identifier: 1, x: 0.1, y: 0.1)],
            now: now
        )
        tracker.update(
            contacts: [TrackpadContactSample(identifier: 1, x: 0.12, y: 0.1)],
            now: now.addingTimeInterval(0.05)
        )

        #expect(!tracker.hasRecentTrackpadActivity(now: now.addingTimeInterval(0.81)))
    }
}
