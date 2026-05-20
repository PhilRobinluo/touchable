import Foundation
import TouchAbleCore

struct CursorProbeResult {
    let name: String
    let zone: HapticZone
    let signal: HapticSignal?
    let reason: String
}
