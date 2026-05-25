import Testing
@testable import TouchAbleCore

struct PointerDeviceClassifierTests {
    @Test func appleInternalKeyboardTrackpadIsTrackpad() {
        let descriptor = PointerDeviceDescriptor(
            manufacturer: "Apple",
            product: "Apple Internal Keyboard / Trackpad",
            transport: "FIFO"
        )

        #expect(PointerDeviceClassifier.classify(descriptor) == .trackpad)
    }

    @Test func logitechReceiverIsMouse() {
        let descriptor = PointerDeviceDescriptor(
            manufacturer: "Logitech",
            product: "USB Receiver",
            transport: "USB"
        )

        #expect(PointerDeviceClassifier.classify(descriptor) == .mouse)
    }

    @Test func mxMasterBluetoothIsMouse() {
        let descriptor = PointerDeviceDescriptor(
            manufacturer: "Logitech",
            product: "MX Master 3S",
            transport: "Bluetooth Low Energy"
        )

        #expect(PointerDeviceClassifier.classify(descriptor) == .mouse)
    }
}
