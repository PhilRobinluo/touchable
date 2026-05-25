# TouchAble 可触

TouchAble is an experimental macOS menu bar app that makes interface changes
feel more tactile on Force Touch trackpads and Magic Trackpads.

It listens to pointer position, pointer events, cursor shape, and optionally
Accessibility UI roles, then maps meaningful changes to short system haptic
feedback. The goal is not "more vibration"; the goal is a quieter layer of
touch feedback for edges, buttons, links, text, inputs, and dragging.

## Status

TouchAble is early v0.x software. It is useful for local testing and tuning, but
the haptic language, CPU profile, permissions flow, and packaging are still
being shaped.

The repository is open source so the idea can be explored in public.

## What It Can Do

- Menu bar app with global enable/disable.
- Edge haptics near screen boundaries.
- Semantic haptics for buttons, links, text, inputs, sliders, and other UI roles
  after Accessibility permission is granted.
- Pointer-event haptics for clicks and drags after Input Monitoring is granted.
- Optional scroll haptics, disabled by default.
- Trackpad-only global haptics, enabled by default, so mouse input does not
  waste haptic feedback or battery.
- HID-level pointer source detection for distinguishing mouse movement from
  internal trackpad activity.
- Configurable three-finger trackpad press shortcut mapping.
- Cursor-shape haptics for I-beam, pointing hand, drag, resize, and related
  cursor transitions.
- Playground window for stable in-app demos and tuning.
- Debug window with live pointer, role, zone, throttling, and event-stream state.
- Adjustable strength, minimum haptic interval, pointer polling rate, event
  delay, and same-target repeat behavior.

## Privacy Boundary

TouchAble is designed to use the narrowest data needed for haptic feedback:

- Pointer position.
- Pointer event type and location.
- Cursor shape.
- Raw trackpad finger count for three-finger shortcut mapping.
- Recent raw trackpad activity to ignore mouse-driven global haptic triggers by
  default.
- HID pointer device metadata such as manufacturer, product, and transport, used
  only to classify input as mouse, trackpad, or unknown.
- Accessibility role/subrole/action metadata for the UI element under the
  pointer.

It should not store text content, input content, document titles, passwords, or
keystrokes. If you spot code that violates this boundary, please open an issue.

## Requirements

- macOS with a Force Touch-capable trackpad or compatible Magic Trackpad.
- Swift toolchain from Xcode or Command Line Tools.
- Optional permissions:
  - Accessibility: enables semantic UI role detection.
  - Input Monitoring: enables global click, drag, scroll, and shortcut mapping
    events.

## Downloadable Package

Build a release zip locally:

```bash
./script/package_release.sh
```

The package is written to `dist/release/TouchAble-<version>-macos.zip`. It
contains `TouchAble.app`, signed with the local `TouchAble Local Dev` identity
when available, or ad-hoc signed as a fallback. It is not notarized by Apple, so
first launch on another Mac may require opening it from Finder with
Control-click > Open or allowing it in System Settings.

The packaging script verifies the unzipped app executable and prints package
size plus a SHA-256 checksum for release notes.

## Build And Run

```bash
git clone https://github.com/PhilRobinluo/touchable.git
cd touchable
swift test
./script/build_and_run.sh
```

Run and verify that the app process starts:

```bash
./script/build_and_run.sh --verify
```

Run with the debug panel open:

```bash
./script/build_and_run.sh --debug-ui
```

The script builds `dist/TouchAble.app`, copies it to
`~/Applications/TouchAble.app`, and launches that stable app path. Keeping the
path stable helps macOS privacy permissions survive frequent local builds.

If TouchAble does not appear in System Settings permission lists, run:

```bash
./script/build_and_run.sh --permissions
```

Then add `~/Applications/TouchAble.app` manually in System Settings.

For local development, you can create a stable self-signed code-signing identity:

```bash
./script/setup_local_signing.sh
```

## Documentation

- [Product brief](docs/product-brief.md)
- [Open roadmap](docs/roadmap.md)
- [Implementation study](docs/implementation-study.md)
- [Semantic haptics plan](docs/semantic-haptics-plan.md)
- [Compatibility checklist](docs/compatibility.md)
- [Project history](docs/project-history.md)
- [Task list](TASKS.md)

## Development Principles

- Prefer Apple public APIs. The three-finger global shortcut mapping uses
  Apple's private `MultitouchSupport.framework` because macOS public APIs do not
  expose reliable global trackpad finger counts.
- Keep feedback short and throttled.
- Prefer "changed meaning" over constant vibration.
- Make all experimental tuning reversible.
- Keep permissions understandable and privacy boundaries explicit.

## License

MIT. See [LICENSE](LICENSE).
