import TouchAbleCore
import XCTest

final class SemanticRoleClassifierTests: XCTestCase {
    func testControlRoles() {
        XCTAssertEqual(SemanticRoleClassifier.zone(for: "AXButton"), .control)
        XCTAssertEqual(SemanticRoleClassifier.zone(for: "AXMenuItem"), .control)
        XCTAssertEqual(SemanticRoleClassifier.zone(for: "AXPopUpButton"), .control)
    }

    func testTextAndInputRoles() {
        XCTAssertEqual(SemanticRoleClassifier.zone(for: "AXStaticText"), .text)
        XCTAssertEqual(SemanticRoleClassifier.zone(for: "AXTextField"), .input)
        XCTAssertEqual(SemanticRoleClassifier.zone(for: "AXTextArea"), .input)
        XCTAssertEqual(SemanticRoleClassifier.zone(for: "AXSearchField"), .input)
    }

    func testOtherRoles() {
        XCTAssertEqual(SemanticRoleClassifier.zone(for: "AXLink"), .link)
        XCTAssertEqual(SemanticRoleClassifier.zone(for: "AXSlider"), .adjustable)
        XCTAssertEqual(SemanticRoleClassifier.zone(for: "AXWindow"), .quiet)
    }

    func testActionNamesCanUpgradeGenericRoles() {
        XCTAssertEqual(SemanticRoleClassifier.zone(for: "AXGroup", actions: ["AXPress"]), .control)
        XCTAssertEqual(SemanticRoleClassifier.zone(for: "AXImage", actions: ["AXPress"]), .control)
        XCTAssertEqual(SemanticRoleClassifier.zone(for: "AXGroup", actions: ["AXIncrement"]), .adjustable)
        XCTAssertEqual(SemanticRoleClassifier.zone(for: "AXGroup", actions: []), .quiet)
    }
}
