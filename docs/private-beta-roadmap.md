# TouchAble Private Beta Roadmap

TouchAble is staying private until the core haptic experience feels stable in
normal Mac apps. This roadmap keeps commercialization behind product readiness:
first polish, then private beta, then signing and packaging, and only then sales.

## Current Baseline

- Local project: `/Users/philrobin/work/touchable`
- Private GitHub repository: `https://github.com/PhilRobinluo/touchable`
- Baseline commit: `54b7df6 Initial TouchAble macOS prototype`
- Runtime shape: SwiftPM native macOS menu bar app
- Local app path: `~/Applications/TouchAble.app`
- Verification: `swift test` passes 19 tests

## Phase 1: Stabilize The Feeling

- Verify haptics in Finder, Safari or Chrome, Obsidian, TextEdit, Terminal, and Notion.
- Tune default intensity, pulse count, and throttling for daily use.
- Keep Debug useful enough to explain why a pulse did or did not fire.
- Keep Settings and Playground on the local direct haptic path.

Exit criteria: normal app operations feel consistently noticeable without being noisy.

## Phase 2: Productize Permissions

- Add a first-launch guide for Accessibility and Input Monitoring.
- Explain that TouchAble reads UI roles and pointer event type/location only.
- Avoid storing text content, titles, or input content.
- Provide a clear recovery path when TouchAble does not appear in System Settings.

Exit criteria: a non-technical tester can install, grant permissions, and understand the privacy boundary.

## Phase 3: Make It Feel Like A Real App

- Add a production app icon.
- Add version, About, and privacy surfaces.
- Separate ordinary user settings from Debug-only controls.
- Keep release and debug modes clearly distinct.

Exit criteria: the app feels trustworthy enough to send to 5-10 private testers.

## Phase 4: Distribution Readiness

- Add a release packaging script.
- Support Developer ID signing separately from local development signing.
- Submit for Apple notarization and staple the ticket.
- Build a DMG and verify it with Gatekeeper on a clean Mac.

Exit criteria: the downloaded app opens under normal macOS security settings.

## Phase 5: Commercial Validation

This phase stays parked until the private beta is good.

- Define early-bird pricing.
- Add license key or trial mechanism.
- Write privacy policy and landing page.
- Invite a small set of trusted testers before public launch.

Exit criteria: at least a few external users keep TouchAble running after the first novelty moment.
