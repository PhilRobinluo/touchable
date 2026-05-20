import AppKit
import Foundation
import TouchAbleCore

final class CursorProbeService {
    func currentResult(profile: HapticProfile) -> CursorProbeResult {
        let cursor = NSCursor.current
        let match = classify(cursor)

        guard let match else {
            let identity = "cursor:custom:\(ObjectIdentifier(cursor).hashValue)"
            let zone = HapticZone.control
            guard profile.enabledZones.contains(zone) else {
                return CursorProbeResult(
                    name: "custom",
                    zone: zone,
                    signal: nil,
                    reason: "自定义光标，但 \(zone.displayName) 未启用"
                )
            }

            return CursorProbeResult(
                name: "custom",
                zone: zone,
                signal: HapticSignal(zone: zone, identity: identity),
                reason: "自定义光标变化"
            )
        }

        guard match.zone != .quiet else {
            return CursorProbeResult(
                name: match.name,
                zone: match.zone,
                signal: nil,
                reason: "\(match.name) 光标为安静状态"
            )
        }

        guard profile.enabledZones.contains(match.zone) else {
            return CursorProbeResult(
                name: match.name,
                zone: match.zone,
                signal: nil,
                reason: "\(match.name) 光标命中，但 \(match.zone.displayName) 未启用"
            )
        }

        return CursorProbeResult(
            name: match.name,
            zone: match.zone,
            signal: HapticSignal(zone: match.zone, identity: "cursor:\(match.name)"),
            reason: "\(match.name) 光标命中 \(match.zone.displayName)"
        )
    }

    private func classify(_ cursor: NSCursor) -> (name: String, zone: HapticZone)? {
        if cursor == .arrow {
            return ("arrow", .quiet)
        }

        if cursor == .iBeam || cursor == .iBeamCursorForVerticalLayout {
            return ("iBeam", .text)
        }

        if cursor == .pointingHand {
            return ("pointingHand", .link)
        }

        if cursor == .openHand || cursor == .closedHand {
            return ("handDrag", .control)
        }

        if cursor == .crosshair {
            return ("crosshair", .adjustable)
        }

        if cursor == .resizeLeft ||
            cursor == .resizeRight ||
            cursor == .resizeLeftRight ||
            cursor == .resizeUp ||
            cursor == .resizeDown ||
            cursor == .resizeUpDown {
            return ("resize", .adjustable)
        }

        if cursor == .dragLink {
            return ("dragLink", .link)
        }

        if cursor == .dragCopy || cursor == .contextualMenu {
            return ("dragOrMenu", .control)
        }

        if cursor == .operationNotAllowed || cursor == .disappearingItem {
            return ("system", .quiet)
        }

        return nil
    }
}
