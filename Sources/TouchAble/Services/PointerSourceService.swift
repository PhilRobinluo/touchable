import Foundation
import IOKit.hid

final class PointerSourceService {
    var onDebugEvent: ((String) -> Void)?

    private static weak var activeService: PointerSourceService?

    private let lock = NSLock()
    private var manager: IOHIDManager?
    private var lastExternalMouseActivityDate: Date = .distantPast
    private var lastExternalMouseDebugDate: Date = .distantPast
    private var knownDevices: [IOHIDDevice: String] = [:]

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
        let name = deviceName(device)
        lock.withLock {
            knownDevices[device] = name
        }

        let kind = isTrackpadLikeDevice(device) ? "触控板类" : "鼠标类"
        emitDebug("HID 设备 · \(kind) · \(name)")
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
        guard !isTrackpadLikeDevice(device) else { return }

        let deviceName = deviceName(device)
        let valueDescription = "\(usageName(usage))=\(IOHIDValueGetIntegerValue(value))"
        let now = Date()
        let shouldEmit = lock.withLock {
            lastExternalMouseActivityDate = now
            let canEmit = now.timeIntervalSince(lastExternalMouseDebugDate) >= 0.5
            if canEmit {
                lastExternalMouseDebugDate = now
            }
            return canEmit
        }

        if shouldEmit {
            emitDebug("HID 鼠标活动 · \(deviceName) · \(valueDescription)")
        }
    }

    private func isTrackpadLikeDevice(_ device: IOHIDDevice) -> Bool {
        let name = deviceName(device).lowercased()
        return name.contains("trackpad") ||
            name.contains("touchpad") ||
            name.contains("internal keyboard")
    }

    private func deviceName(_ device: IOHIDDevice) -> String {
        let product = stringProperty(kIOHIDProductKey as CFString, device: device)
        let manufacturer = stringProperty(kIOHIDManufacturerKey as CFString, device: device)
        let transport = stringProperty(kIOHIDTransportKey as CFString, device: device)

        let name = [manufacturer, product, transport]
            .compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: " / ")
        return name.isEmpty ? "未知 HID Mouse" : name
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
        Self.appendDebugLine(detail)
        DispatchQueue.main.async { [weak self] in
            self?.onDebugEvent?(detail)
        }
    }

    private static func appendDebugLine(_ detail: String) {
        let line = "\(Date()) \(detail)\n"
        let url = URL(fileURLWithPath: "/tmp/touchable-pointer-source.log")
        guard let data = line.data(using: .utf8) else { return }

        if FileManager.default.fileExists(atPath: url.path),
           let handle = try? FileHandle(forWritingTo: url) {
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: data)
        } else {
            try? data.write(to: url)
        }
    }

    private static let deviceMatchingCallback: IOHIDDeviceCallback = { _, _, _, device in
        activeService?.registerDevice(device)
    }

    private static let inputValueCallback: IOHIDValueCallback = { _, _, _, value in
        activeService?.handleInputValue(value)
    }
}
