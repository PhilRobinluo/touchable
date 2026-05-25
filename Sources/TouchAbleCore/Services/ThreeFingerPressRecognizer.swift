import Foundation

public struct ThreeFingerPressRecognition: Equatable {
    public let touchCount: Int
}

public final class ThreeFingerPressRecognizer {
    private let requiredTouchCount: Int
    private let touchStaleInterval: TimeInterval
    private let minimumPressInterval: TimeInterval

    private var currentTouchCount = 0
    private var recentQualifiedTouchCount = 0
    private var lastTouchDate: Date = .distantPast
    private var lastQualifiedTouchDate: Date = .distantPast
    private var lastPressDate: Date = .distantPast
    private var didFireForCurrentTouch = false

    public init(
        requiredTouchCount: Int = 3,
        touchStaleInterval: TimeInterval = 1.00,
        minimumPressInterval: TimeInterval = 0.45
    ) {
        self.requiredTouchCount = requiredTouchCount
        self.touchStaleInterval = touchStaleInterval
        self.minimumPressInterval = minimumPressInterval
    }

    public func updateTouchCount(_ count: Int, now: Date = Date()) {
        currentTouchCount = count
        lastTouchDate = now
        if count >= requiredTouchCount {
            recentQualifiedTouchCount = count
            lastQualifiedTouchDate = now
        } else if count == 0 {
            recentQualifiedTouchCount = 0
            lastQualifiedTouchDate = .distantPast
            didFireForCurrentTouch = false
        }
    }

    public func press(now: Date = Date()) -> ThreeFingerPressRecognition? {
        guard recentQualifiedTouchCount >= requiredTouchCount else { return nil }
        guard now.timeIntervalSince(lastQualifiedTouchDate) <= touchStaleInterval else { return nil }
        guard !didFireForCurrentTouch else { return nil }
        guard now.timeIntervalSince(lastPressDate) >= minimumPressInterval else { return nil }

        didFireForCurrentTouch = true
        lastPressDate = now
        return ThreeFingerPressRecognition(touchCount: recentQualifiedTouchCount)
    }

    public func reset() {
        currentTouchCount = 0
        recentQualifiedTouchCount = 0
        lastTouchDate = .distantPast
        lastQualifiedTouchDate = .distantPast
        didFireForCurrentTouch = false
    }
}
