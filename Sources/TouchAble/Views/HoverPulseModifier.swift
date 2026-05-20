import SwiftUI
import TouchAbleCore

struct HoverPulseModifier: ViewModifier {
    @EnvironmentObject private var preferences: PreferenceStore
    @EnvironmentObject private var playgroundHaptics: PlaygroundHapticController

    let zone: HapticZone
    let identity: String

    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                guard hovering else { return }
                playgroundHaptics.pulse(
                    zone: zone,
                    identity: identity,
                    profile: preferences.profile
                )
            }
    }
}

extension View {
    func playgroundPulse(zone: HapticZone, identity: String) -> some View {
        modifier(HoverPulseModifier(zone: zone, identity: identity))
    }
}

struct LocalPulseModifier: ViewModifier {
    @EnvironmentObject private var controller: TouchAbleController

    let zone: HapticZone
    let identity: String

    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                guard hovering else { return }
                controller.pulseForLocalSurface(zone: zone, identity: identity)
            }
    }
}

extension View {
    func localPulse(zone: HapticZone, identity: String) -> some View {
        modifier(LocalPulseModifier(zone: zone, identity: identity))
    }
}
