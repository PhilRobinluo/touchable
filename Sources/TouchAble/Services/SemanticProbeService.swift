import ApplicationServices
import AppKit
import Foundation
import TouchAbleCore

final class SemanticProbeService {
    private let systemWide = AXUIElementCreateSystemWide()

    func currentSignal(profile: HapticProfile) -> HapticSignal? {
        currentResult(profile: profile).signal
    }

    func currentResult(profile: HapticProfile) -> SemanticProbeResult {
        let location = NSEvent.mouseLocation
        let accessibilityPoint = accessibilityPoint(from: location)

        var element: AXUIElement?
        let error = AXUIElementCopyElementAtPosition(
            systemWide,
            Float(accessibilityPoint.x),
            Float(accessibilityPoint.y),
            &element
        )

        guard error == .success, let element else {
            return SemanticProbeResult(
                role: "none",
                zone: .quiet,
                signal: nil,
                reason: "AX 未返回光标下对象"
            )
        }

        guard let role = stringAttribute(element, name: kAXRoleAttribute as CFString) else {
            return SemanticProbeResult(
                role: "unknown",
                zone: .quiet,
                signal: nil,
                reason: "对象没有 AXRole"
            )
        }

        let actions = actionNames(for: element)
        let zone = SemanticRoleClassifier.zone(for: role, actions: actions)
        let identity = "semantic:\(role):\(stableGeometryIdentity(for: element))"

        guard zone != .quiet else {
            return SemanticProbeResult(
                role: role,
                zone: zone,
                signal: nil,
                reason: "\(role) 被归类为安静区域"
            )
        }

        guard profile.enabledZones.contains(zone) else {
            return SemanticProbeResult(
                role: role,
                zone: zone,
                signal: nil,
                reason: "\(zone.displayName) 在当前手感中未启用"
            )
        }

        let reason = actions.isEmpty
            ? "语义命中 \(zone.displayName)"
            : "语义命中 \(zone.displayName)，动作 \(actions.joined(separator: ","))"

        return SemanticProbeResult(
            role: role,
            zone: zone,
            signal: HapticSignal(zone: zone, identity: identity),
            reason: reason
        )
    }

    private func accessibilityPoint(from mouseLocation: CGPoint) -> CGPoint {
        let mainHeight = NSScreen.screens.first?.frame.height ?? 0
        return CGPoint(x: mouseLocation.x, y: mainHeight - mouseLocation.y)
    }

    private func stringAttribute(_ element: AXUIElement, name: CFString) -> String? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, name, &value)
        guard error == .success, let value else { return nil }
        return String(describing: value)
    }

    private func actionNames(for element: AXUIElement) -> [String] {
        var names: CFArray?
        let error = AXUIElementCopyActionNames(element, &names)
        guard error == .success,
              let names = names as? [String]
        else {
            return []
        }

        return names
    }

    private func stableGeometryIdentity(for element: AXUIElement) -> String {
        let point = pointAttribute(element, name: kAXPositionAttribute as CFString)
        let size = sizeAttribute(element, name: kAXSizeAttribute as CFString)

        guard let point, let size else {
            return "unknown-geometry"
        }

        return "\(Int(point.x)):\(Int(point.y)):\(Int(size.width)):\(Int(size.height))"
    }

    private func pointAttribute(_ element: AXUIElement, name: CFString) -> CGPoint? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, name, &value)
        guard error == .success,
              let value,
              CFGetTypeID(value) == AXValueGetTypeID()
        else {
            return nil
        }

        let axValue = value as! AXValue
        guard AXValueGetType(axValue) == .cgPoint else { return nil }

        var point = CGPoint.zero
        guard AXValueGetValue(axValue, .cgPoint, &point) else { return nil }
        return point
    }

    private func sizeAttribute(_ element: AXUIElement, name: CFString) -> CGSize? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, name, &value)
        guard error == .success,
              let value,
              CFGetTypeID(value) == AXValueGetTypeID()
        else {
            return nil
        }

        let axValue = value as! AXValue
        guard AXValueGetType(axValue) == .cgSize else { return nil }

        var size = CGSize.zero
        guard AXValueGetValue(axValue, .cgSize, &size) else { return nil }
        return size
    }
}
