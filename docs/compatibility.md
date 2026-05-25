# Compatibility Checklist

TouchAble depends on macOS pointer, cursor, Accessibility, HID, and haptic
behavior. This checklist keeps app-by-app testing repeatable.

## Test Setup

- Build and launch with `./script/build_and_run.sh --verify`.
- Keep `仅触控板触发` enabled.
- Open the Debug window and confirm:
  - `输入来源` switches between trackpad and mouse.
  - `当前输入设备` shows the active HID device.
  - `候选触觉` and `节流判断` explain skipped haptics.
- Test with a Force Touch trackpad or Magic Trackpad.
- If using a mouse, verify mouse movement is detected as mouse input and does
  not trigger global haptics while trackpad-only mode is enabled.

## App Matrix

| App | Pointer / Cursor | Semantic Roles | Click / Drag | Scroll | Notes |
| --- | --- | --- | --- | --- | --- |
| Safari | Not tested | Not tested | Not tested | Not tested | Links, buttons, page text, address bar |
| Chrome | Not tested | Not tested | Not tested | Not tested | Links, buttons, page text, address bar |
| Finder | Not tested | Not tested | Not tested | Not tested | Sidebar, file rows, toolbar buttons |
| Notion | Not tested | Not tested | Not tested | Not tested | Rich text, buttons, database rows |
| Obsidian | Not tested | Not tested | Not tested | Not tested | Editor text, links, sidebar items |
| Terminal | Not tested | Not tested | Not tested | Not tested | Text cursor, tabs, scrollback |

## Pass Criteria

- Trackpad movement can trigger enabled haptic categories.
- Mouse movement does not trigger global haptics in trackpad-only mode.
- Stationary cursor does not repeatedly vibrate.
- Scroll haptics remain off by default.
- Debug events explain why a haptic was triggered or skipped.
- No text contents, document titles, passwords, or keystrokes are logged.
