# TouchAble Open Roadmap

TouchAble is now an open-source experiment. The near-term goal is to make the
core haptic experience stable enough for daily dogfooding before thinking about
packaged releases or broader distribution.

## Current Baseline

- Runtime shape: SwiftPM native macOS menu bar app.
- Local app path: `~/Applications/TouchAble.app`.
- Default development path: build locally, install to the stable app path, and
  grant macOS permissions to that stable copy.
- Verification target: `swift test` plus manual haptic testing in normal Mac
  apps.

## Phase 1: Stabilize The Feeling

- Verify haptics in Finder, Safari or Chrome, Obsidian, TextEdit, Terminal, and
  Notion.
- Tune default intensity, pulse count, and throttling for daily use.
- Reduce perceived latency so UI transitions feel immediate.
- Keep Debug useful enough to explain why a pulse did or did not fire.
- Keep Settings and Playground on the local direct haptic path.

Exit criteria: normal app operations feel consistently noticeable without being
noisy.

## Phase 2: Reduce Runtime Cost

- Measure CPU use in ordinary mode and debug mode separately.
- Reduce Accessibility probing when the pointer is stationary.
- Prefer event-driven signals where possible without breaking stability.
- Keep polling rate adjustable while the haptic language is still being tuned.

Exit criteria: ordinary mode is comfortable to leave running for long sessions.

## Phase 3: Productize Permissions

- Add a first-launch guide for Accessibility and Input Monitoring.
- Explain that TouchAble reads UI roles and pointer event type/location only.
- Avoid storing text content, titles, or input content.
- Provide a clear recovery path when TouchAble does not appear in System
  Settings.

Exit criteria: a non-technical tester can install, grant permissions, and
understand the privacy boundary.

## Phase 4: Make It Feel Like A Real App

- Add version, About, and privacy surfaces.
- Separate ordinary user settings from debug-only controls.
- Keep release and debug modes clearly distinct.
- Improve app icon and visible identity as needed.

Exit criteria: the app feels trustworthy enough to share with external testers.

## Phase 5: Distribution Readiness

- Add a release packaging script.
- Support Developer ID signing separately from local development signing.
- Submit for Apple notarization and staple the ticket.
- Build a DMG and verify it with Gatekeeper on a clean Mac.

Exit criteria: the downloaded app opens under normal macOS security settings.

## Parked Ideas

- License keys or paid distribution.
- App Store submission.
- Continuous vibration, custom waveforms, or private driver-level control.
- Window snapping or scroll-end haptics beyond public API boundaries.
