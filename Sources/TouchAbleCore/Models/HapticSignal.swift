import Foundation

public struct HapticSignal: Equatable {
    public let zone: HapticZone
    public let identity: String

    public init(zone: HapticZone, identity: String) {
        self.zone = zone
        self.identity = identity
    }
}
