import CoreGraphics
import Foundation

public enum EdgeDetector {
    public static func signal(
        for point: CGPoint,
        in screenFrames: [CGRect],
        profile: HapticProfile
    ) -> HapticSignal? {
        guard profile.enabledZones.contains(.edge),
              let frame = frame(containing: point, from: screenFrames) ?? screenFrames.first
        else {
            return nil
        }

        let band = profile.edgeBand
        let x = point.x
        let y = point.y

        let edge: String?
        if x <= frame.minX + band {
            edge = "left"
        } else if x >= frame.maxX - band {
            edge = "right"
        } else if y <= frame.minY + band {
            edge = "bottom"
        } else if y >= frame.maxY - band {
            edge = "top"
        } else {
            edge = nil
        }

        guard let edge else { return nil }
        let screenID = "\(Int(frame.minX)):\(Int(frame.minY)):\(Int(frame.width)):\(Int(frame.height))"
        return HapticSignal(zone: .edge, identity: "edge:\(edge):\(screenID)")
    }

    private static func frame(containing point: CGPoint, from frames: [CGRect]) -> CGRect? {
        frames.first { $0.contains(point) }
    }
}
