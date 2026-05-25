import XCTest
@testable import TouchAbleCore

final class ThreeFingerPressRecognizerTests: XCTestCase {
    func testThreeFingerTouchThenPressRecognizesOnce() {
        let recognizer = ThreeFingerPressRecognizer()
        let start = Date(timeIntervalSince1970: 100)

        recognizer.updateTouchCount(3, now: start)

        XCTAssertEqual(
            recognizer.press(pressure: 0.9, now: start.addingTimeInterval(0.05)),
            ThreeFingerPressRecognition(touchCount: 3, pressure: 0.9)
        )
        XCTAssertNil(recognizer.press(pressure: 0.9, now: start.addingTimeInterval(0.10)))
    }

    func testPressWithoutThreeFingerTouchDoesNotRecognize() {
        let recognizer = ThreeFingerPressRecognizer()
        let start = Date(timeIntervalSince1970: 100)

        recognizer.updateTouchCount(2, now: start)

        XCTAssertNil(recognizer.press(pressure: 0.9, now: start.addingTimeInterval(0.05)))
    }

    func testThreeFingerTouchWithoutPressureDoesNotRecognize() {
        let recognizer = ThreeFingerPressRecognizer()
        let start = Date(timeIntervalSince1970: 100)

        recognizer.updateTouchCount(3, now: start)

        XCTAssertNil(recognizer.press(pressure: 0.2, now: start.addingTimeInterval(0.05)))
    }

    func testStaleThreeFingerTouchDoesNotRecognize() {
        let recognizer = ThreeFingerPressRecognizer(touchStaleInterval: 0.30)
        let start = Date(timeIntervalSince1970: 100)

        recognizer.updateTouchCount(3, now: start)

        XCTAssertNil(recognizer.press(pressure: 0.9, now: start.addingTimeInterval(0.40)))
    }

    func testPressRecognizesAfterTouchCountTemporarilyDrops() {
        let recognizer = ThreeFingerPressRecognizer()
        let start = Date(timeIntervalSince1970: 100)

        recognizer.updateTouchCount(3, now: start)
        recognizer.updateTouchCount(2, now: start.addingTimeInterval(0.05))

        XCTAssertEqual(
            recognizer.press(pressure: 0.9, now: start.addingTimeInterval(0.10)),
            ThreeFingerPressRecognition(touchCount: 3, pressure: 0.9)
        )
    }

    func testDroppingBelowThreeFingersRearmsRecognition() {
        let recognizer = ThreeFingerPressRecognizer()
        let start = Date(timeIntervalSince1970: 100)

        recognizer.updateTouchCount(3, now: start)
        XCTAssertNotNil(recognizer.press(pressure: 0.9, now: start.addingTimeInterval(0.05)))

        recognizer.updateTouchCount(0, now: start.addingTimeInterval(0.10))
        recognizer.updateTouchCount(3, now: start.addingTimeInterval(0.60))

        XCTAssertEqual(
            recognizer.press(pressure: 0.9, now: start.addingTimeInterval(0.65)),
            ThreeFingerPressRecognition(touchCount: 3, pressure: 0.9)
        )
    }

    func testFourFingerTouchDoesNotRecognizeAsThreeFingerPress() {
        let recognizer = ThreeFingerPressRecognizer()
        let start = Date(timeIntervalSince1970: 100)

        recognizer.updateTouchCount(4, now: start)

        XCTAssertNil(recognizer.press(pressure: 0.9, now: start.addingTimeInterval(0.05)))
    }
}
