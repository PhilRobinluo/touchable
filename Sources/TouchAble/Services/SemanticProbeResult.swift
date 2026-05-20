import Foundation
import TouchAbleCore

struct SemanticProbeResult {
    let role: String
    let zone: HapticZone
    let signal: HapticSignal?
    let reason: String
}
