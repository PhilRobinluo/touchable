import Foundation
import IOKit.hid
import TouchAbleCore

final class PointerSourceService {
    var onDebugEvent: ((String) -> Void)?
    var onStateChange: ((String, String, String) -> Void)?

    private static weak var activeService: PointerSourceService?

    private let lock = NSLock()
    private var manager: IOHIDManager?
    private var lastExternalMouseActivityDate: Date = .distantPast
    private var lastExternalMouseDebugDate: Date = .distantPast
    private var knownDevices: [IOHIDDevice: PointerDeviceDescriptor] = [:]
    private var lastDeviceDescription = "未识别"
    private var lastEventDescription = "未收到"

    deinit {
        stop()
    }

    func start() -> Bool {
        guard manager == nil else { return true }

        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        let matching: [String: Any] = [
            kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey: kHIDUsage_GD_Mouse
        ]

        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)
        Self.activeService = self
        IOHIDManagerRegisterDeviceMatchingCallback(manager, Self.deviceMatchingCallback, nil)
        IOHIDManagerRegisterInputValueCallback(manager, Self.inputValueCallback, nil)
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)

        let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        guard result == kIOReturnSuccess else {
            IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
            emitDebug("HID 鼠标来源监听失败 · \(result)")
            return false
        }

        self.manager = manager
        emitDebug("HID 鼠标来源监听已启动")
        loadExistingDevices()
        return true
    }

    func stop() {
        guard let manager else { return }

        IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        self.manager = nil
        lock.withLock {
            knownDevices.removeAll()
            lastExternalMouseActivityDate = .distantPast
            lastExternalMouseDebugDate = .distantPast
            lastDeviceDescription = "未识别"
            lastEventDescription = "未收到"
        }

        if Self.activeService === self {
            Self.activeService = nil
        }
    }

    func hasRecentExternalMouseActivity(now: Date = Date(), within interval: TimeInterval = 0.45) -> Bool {
        lock.withLock {
            now.timeIntervalSince(lastExternalMouseActivityDate) <= interval
        }
    }

    private func loadExistingDevices() {
        guard let manager,
              let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else { return }
        for device in devices {
            registerDevice(device)
        }
    }

    private func registerDevice(_ device: IOHIDDevice) {
        let descriptor = deviceDescriptor(device)
        let name = descriptor.displayName
        let kind = PointerDeviceClassifier.classify(descriptor)
        lock.withLock {
            knownDevices[device] = descriptor
            lastDeviceDescription = summarizeKnownDevices()
        }

        let kindDescription = displayName(for: kind)
        emitDebug("HID 设备 · \(kindDescription) · \(name)")
        emitState()
    }

    private func handleInputValue(_ value: IOHIDValue) {
        let element = IOHIDValueGetElement(value)
        let usagePage = IOHIDElementGetUsagePage(element)
        let usage = IOHIDElementGetUsage(element)

        guard usagePage == kHIDPage_GenericDesktop,
              usage == kHIDUsage_GD_X || usage == kHIDUsage_GD_Y || usage == kHIDUsage_GD_Wheel
        else {
            return
        }

        guard IOHIDValueGetIntegerValue(value) != 0 else { return }
        let device = IOHIDElementGetDevice(element)
        let descriptor = deviceDescriptor(device)
        guard PointerDeviceClassifier.classify(descriptor) == .mouse else { return }

        let deviceName = descriptor.displayName
        let valueDescription = "\(usageName(usage))=\(IOHIDValueGetIntegerValue(value))"
        let now = Date()
        let shouldEmit = lock.withLock {
            lastExternalMouseActivityDate = now
            lastDeviceDescription = deviceName
            lastEventDescription = "\(deviceName) · \(valueDescription)"
            let canEmit = now.timeIntervalSince(lastExternalMouseDebugDate) >= 0.5
            if canEmit {
                lastExternalMouseDebugDate = now
            }
            return canEmit
        }

        if shouldEmit {
            emitDebug("HID 鼠标活动 · \(deviceName) · \(valueDescription)")
        }
        emitState()
    }

    private func deviceDescriptor(_ device: IOHIDDevice) -> PointerDeviceDescriptor {
        let product = stringProperty(kIOHIDProductKey as CFString, device: device)
        let manufacturer = stringProperty(kIOHIDManufacturerKey as CFString, device: device)
        let transport = stringProperty(kIOHIDTransportKey as CFString, device: device)

        return PointerDeviceDescriptor(
            manufacturer: manufacturer,
            product: product,
            transport: transport
        )
    }

    private func stringProperty(_ key: CFString, device: IOHIDDevice) -> String? {
        IOHIDDeviceGetProperty(device, key) as? String
    }

    private func usageName(_ usage: UInt32) -> String {
        switch usage {
        case UInt32(kHIDUsage_GD_X):
            return "X"
        case UInt32(kHIDUsage_GD_Y):
            return "Y"
        case UInt32(kHIDUsage_GD_Wheel):
            return "Wheel"
        default:
            return "\(usage)"
        }
    }

    private func emitDebug(_ detail: String) {
        DispatchQueue.main.async { [weak self] in
            self?.onDebugEvent?(detail)
        }
    }

    private func emitState() {
        let state = lock.withLock {
            (lastDeviceDescription, lastEventDescription, summarizeKnownDevices())
        }
        DispatchQueue.main.async { [weak self] in
            self?.onStateChange?(state.0, state.1, state.2)
        }
    }

    private func summarizeKnownDevices() -> String {
        let names = Set(knownDevices.values.map(\.displayName))
            .sorted()

        guard !names.isEmpty else {
            return "未识别"
        }
        return names.joined(separator: "\n")
    }

    private func displayName(for kind: PointerDeviceKind) -> String {
        switch kind {
        case .trackpad:
            return "触控板"
        case .mouse:
            return "鼠标"
        case .unknown:
            return "未知"
        }
    }

    private static let deviceMatchingCallback: IOHIDDeviceCallback = { _, _, _, device in
        activeService?.registerDevice(device)
    }

    private static let inputValueCallback: IOHIDValueCallback = { _, _, _, value in
        activeService?.handleInputValue(value)
    }
}
