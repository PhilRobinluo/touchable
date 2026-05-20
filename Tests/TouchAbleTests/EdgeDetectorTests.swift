import TouchAbleCore
import XCTest

final class EdgeDetectorTests: XCTestCase {
    private let frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    private let profile = HapticProfile(
        strength: .standard,
        minimumInterval: 0.18,
        edgeBand: 10,
        enabledZones: [.edge]
    )

    func testDetectsEdges() {
        XCTAssertEqual(EdgeDetector.signal(for: CGPoint(x: 5, y: 50), in: [frame], profile: profile)?.identity, "edge:left:0:0:100:100")
        XCTAssertEqual(EdgeDetector.signal(for: CGPoint(x: 95, y: 50), in: [frame], profile: profile)?.identity, "edge:right:0:0:100:100")
        XCTAssertEqual(EdgeDetector.signal(for: CGPoint(x: 50, y: 5), in: [frame], profile: profile)?.identity, "edge:bottom:0:0:100:100")
        XCTAssertEqual(EdgeDetector.signal(for: CGPoint(x: 50, y: 95), in: [frame], profile: profile)?.identity, "edge:top:0:0:100:100")
    }

    func testQuietAwayFromEdges() {
        XCTAssertNil(EdgeDetector.signal(for: CGPoint(x: 50, y: 50), in: [frame], profile: profile))
    }

    func testDisabledEdgeZoneReturnsNil() {
        let disabled = HapticProfile(
            strength: .standard,
            minimumInterval: 0.18,
            edgeBand: 10,
            enabledZones: []
        )

        XCTAssertNil(EdgeDetector.signal(for: CGPoint(x: 5, y: 50), in: [frame], profile: disabled))
    }
}
