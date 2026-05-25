import Foundation

public struct TrackpadContactSample: Equatable {
    public let identifier: Int
    public let x: Double
    public let y: Double
    public let velocityX: Double
    public let velocityY: Double

    public init(identifier: Int, x: Double, y: Double, velocityX: Double = 0, velocityY: Double = 0) {
        self.identifier = identifier
        self.x = x
        self.y = y
        self.velocityX = velocityX
        self.velocityY = velocityY
    }
}

public final class TrackpadActivityTracker {
    private let minimumPositionDelta: Double
    private let minimumVelocity: Double

    private var lastTrackpadActivityDate: Date = .distantPast
    private var previousContactsByIdentifier: [Int: TrackpadContactSample] = [:]

    public init(minimumPositionDelta: Double = 0.004, minimumVelocity: Double = 0.010) {
        self.minimumPositionDelta = minimumPositionDelta
        self.minimumVelocity = minimumVelocity
    }

    @discardableResult
    public func update(contacts: [TrackpadContactSample], now: Date = Date()) -> Bool {
        guard !contacts.isEmpty else {
            previousContactsByIdentifier.removeAll()
            return false
        }

        var didMove = false
        var nextContactsByIdentifier: [Int: TrackpadContactSample] = [:]

        for contact in contacts {
            nextContactsByIdentifier[contact.identifier] = contact

            if hasMeaningfulVelocity(contact) {
                didMove = true
                continue
            }

            guard let previous = previousContactsByIdentifier[contact.identifier] else {
                continue
            }

            if distance(from: previous, to: contact) >= minimumPositionDelta {
                didMove = true
            }
        }

        previousContactsByIdentifier = nextContactsByIdentifier

        guard didMove else { return false }
        markActive(now: now)
        return true
    }

    public func markActive(now: Date = Date()) {
        lastTrackpadActivityDate = now
    }

    public func hasRecentTrackpadActivity(now: Date = Date(), within interval: TimeInterval = 0.75) -> Bool {
        now.timeIntervalSince(lastTrackpadActivityDate) <= interval
    }

    public func reset() {
        lastTrackpadActivityDate = .distantPast
        previousContactsByIdentifier.removeAll()
    }

    private func hasMeaningfulVelocity(_ contact: TrackpadContactSample) -> Bool {
        hypot(contact.velocityX, contact.velocityY) >= minimumVelocity
    }

    private func distance(from previous: TrackpadContactSample, to current: TrackpadContactSample) -> Double {
        hypot(current.x - previous.x, current.y - previous.y)
    }
}
