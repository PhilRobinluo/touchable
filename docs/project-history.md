# Project History

TouchAble began as a small question: can a Mac trackpad make the interface feel
less flat?

The first prototype used `NSHapticFeedbackManager` to confirm that the machine
could trigger real haptic feedback through public AppKit APIs. The available
system patterns were enough to explore short, meaningful pulses:

- `generic`
- `alignment`
- `levelChange`

The second prototype treated pointer movement as a proxy for touch movement. It
triggered edge feedback near screen boundaries and level-change feedback when
crossing coarse screen regions. That experiment established the first product
constraint: TouchAble should be a haptic punctuation layer, not a continuous
vibration effect.

The larger breakthrough came from Accessibility role detection. By asking macOS
what UI element is under the pointer, TouchAble could map interface semantics to
different tactile cues:

- Buttons and menu items feel clickable.
- Links feel actionable.
- Text feels different from controls.
- Inputs feel ready for editing.
- Screen edges feel like boundaries.

That moved the project from position-based haptics to semantic haptics: the UI
does not merely look different; it can feel different.

TouchAble v0.x is the open-source version of that experiment: a native macOS
menu bar app with edge haptics, semantic haptics, pointer-event haptics, cursor
shape haptics, a Playground, and a Debug panel for tuning.
