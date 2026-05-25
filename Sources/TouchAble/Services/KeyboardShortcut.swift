import AppKit
import Foundation

struct KeyboardShortcut: Equatable {
    var keyCode: UInt16
    var modifierFlags: NSEvent.ModifierFlags

    var isValid: Bool {
        keyCode != KeyboardShortcutKey.none.keyCode
    }

    var displayName: String {
        guard let key = KeyboardShortcutKey(keyCode: keyCode) else {
            return "未设置"
        }

        let flags = modifierFlags.intersection(.deviceIndependentFlagsMask)
        let modifierText = [
            flags.contains(.command) ? "⌘" : nil,
            flags.contains(.option) ? "⌥" : nil,
            flags.contains(.control) ? "⌃" : nil,
            flags.contains(.shift) ? "⇧" : nil
        ]
            .compactMap { $0 }
            .joined()

        return "\(modifierText)\(key.displayName)"
    }
}

enum KeyboardShortcutKey: String, CaseIterable, Identifiable {
    case none
    case space
    case returnKey
    case escape
    case tab
    case a
    case b
    case c
    case d
    case e
    case f
    case g
    case h
    case i
    case j
    case k
    case l
    case m
    case n
    case o
    case p
    case q
    case r
    case s
    case t
    case u
    case v
    case w
    case x
    case y
    case z
    case one
    case two
    case three
    case four
    case five
    case six
    case seven
    case eight
    case nine
    case zero
    case f1
    case f2
    case f3
    case f4
    case f5
    case f6
    case f7
    case f8
    case f9
    case f10
    case f11
    case f12

    var id: String { rawValue }

    init?(keyCode: UInt16) {
        guard let match = Self.allCases.first(where: { $0.keyCode == keyCode }) else {
            return nil
        }
        self = match
    }

    var displayName: String {
        switch self {
        case .none:
            return "未设置"
        case .space:
            return "Space"
        case .returnKey:
            return "Return"
        case .escape:
            return "Esc"
        case .tab:
            return "Tab"
        case .one:
            return "1"
        case .two:
            return "2"
        case .three:
            return "3"
        case .four:
            return "4"
        case .five:
            return "5"
        case .six:
            return "6"
        case .seven:
            return "7"
        case .eight:
            return "8"
        case .nine:
            return "9"
        case .zero:
            return "0"
        default:
            return rawValue.uppercased()
        }
    }

    var keyCode: UInt16 {
        switch self {
        case .none:
            return UInt16.max
        case .a:
            return 0
        case .s:
            return 1
        case .d:
            return 2
        case .f:
            return 3
        case .h:
            return 4
        case .g:
            return 5
        case .z:
            return 6
        case .x:
            return 7
        case .c:
            return 8
        case .v:
            return 9
        case .b:
            return 11
        case .q:
            return 12
        case .w:
            return 13
        case .e:
            return 14
        case .r:
            return 15
        case .y:
            return 16
        case .t:
            return 17
        case .one:
            return 18
        case .two:
            return 19
        case .three:
            return 20
        case .four:
            return 21
        case .six:
            return 22
        case .five:
            return 23
        case .zero:
            return 29
        case .nine:
            return 25
        case .seven:
            return 26
        case .eight:
            return 28
        case .o:
            return 31
        case .u:
            return 32
        case .i:
            return 34
        case .p:
            return 35
        case .l:
            return 37
        case .j:
            return 38
        case .k:
            return 40
        case .n:
            return 45
        case .m:
            return 46
        case .tab:
            return 48
        case .space:
            return 49
        case .escape:
            return 53
        case .returnKey:
            return 36
        case .f1:
            return 122
        case .f2:
            return 120
        case .f3:
            return 99
        case .f4:
            return 118
        case .f5:
            return 96
        case .f6:
            return 97
        case .f7:
            return 98
        case .f8:
            return 100
        case .f9:
            return 101
        case .f10:
            return 109
        case .f11:
            return 103
        case .f12:
            return 111
        }
    }
}
