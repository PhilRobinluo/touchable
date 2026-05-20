import Foundation

public enum SemanticRoleClassifier {
    public static func zone(for role: String) -> HapticZone {
        zone(for: role, actions: [])
    }

    public static func zone(for role: String, actions: [String]) -> HapticZone {
        if actions.contains("AXPress") {
            return .control
        }

        if actions.contains("AXIncrement") || actions.contains("AXDecrement") {
            return .adjustable
        }

        switch role {
        case "AXButton", "AXMenuButton", "AXMenuItem", "AXCheckBox", "AXRadioButton", "AXPopUpButton":
            return .control
        case "AXLink":
            return .link
        case "AXTextField", "AXTextArea", "AXSearchField", "AXComboBox":
            return .input
        case "AXStaticText":
            return .text
        case "AXSlider", "AXIncrementor":
            return .adjustable
        default:
            return .quiet
        }
    }
}
