public enum PointerDeviceKind: Equatable {
    case trackpad
    case mouse
    case unknown
}

public struct PointerDeviceDescriptor: Equatable {
    public let manufacturer: String?
    public let product: String?
    public let transport: String?

    public init(manufacturer: String?, product: String?, transport: String?) {
        self.manufacturer = manufacturer
        self.product = product
        self.transport = transport
    }

    public var displayName: String {
        let parts = [manufacturer, product, transport]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? "未知 HID 设备" : parts.joined(separator: " / ")
    }
}

public enum PointerDeviceClassifier {
    public static func classify(_ descriptor: PointerDeviceDescriptor) -> PointerDeviceKind {
        let text = descriptor.displayName.lowercased()

        if text.contains("trackpad") ||
            text.contains("touchpad") ||
            text.contains("internal keyboard") {
            return .trackpad
        }

        if text.contains("mouse") ||
            text.contains("receiver") ||
            text.contains("logitech") ||
            text.contains("mx master") ||
            text.contains("usb") ||
            text.contains("bluetooth") {
            return .mouse
        }

        return .unknown
    }
}
