import AppKit
import Foundation

final class KeyboardShortcutSender {
    private let source = CGEventSource(stateID: .hidSystemState)

    func send(_ shortcut: KeyboardShortcut) {
        guard shortcut.isValid,
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: shortcut.keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: shortcut.keyCode, keyDown: false)
        else {
            return
        }

        let flags = shortcut.modifierFlags.cgEventFlags
        keyDown.flags = flags
        keyUp.flags = flags
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}

private extension NSEvent.ModifierFlags {
    var cgEventFlags: CGEventFlags {
        var flags: CGEventFlags = []
        if contains(.command) {
            flags.insert(.maskCommand)
        }
        if contains(.option) {
            flags.insert(.maskAlternate)
        }
        if contains(.control) {
            flags.insert(.maskControl)
        }
        if contains(.shift) {
            flags.insert(.maskShift)
        }
        return flags
    }
}
