import AppKit
import CoreFoundation
import Darwin
import Foundation
import os
import TouchAbleCore

struct ThreeFingerPressEvent {
    let touchCount: Int
    let location: CGPoint
}

final class ThreeFingerPressService {
    var onPress: ((ThreeFingerPressEvent) -> Void)?
    var onDebugEvent: ((String) -> Void)?

    private static weak var activeService: ThreeFingerPressService?
    private static let logger = Logger(subsystem: "com.philrobin.TouchAble", category: "ThreeFingerPress")

    private let recognizer = ThreeFingerPressRecognizer()
    private let activityTracker = TrackpadActivityTracker()
    private let lock = NSLock()

    private var multitouch: MultitouchSupportBridge?
    private var devices: [MTDeviceRef] = []
    private var pressureMonitor: Any?
    private var lastTouchDebugDate: Date = .distantPast
    private var lastTouchDebugCount = -1

    deinit {
        stop()
    }

    func start() {
        guard multitouch == nil, pressureMonitor == nil else { return }

        Self.activeService = self
        startMultitouch()
        startPressureMonitor()
    }

    func stop() {
        stopPressureMonitor()
        stopMultitouch()
        lock.withLock {
            recognizer.reset()
            activityTracker.reset()
        }

        if Self.activeService === self {
            Self.activeService = nil
        }
    }

    func simulateThreeFingerPressForDebug(location: CGPoint) {
        lock.withLock {
            recognizer.updateTouchCount(3)
            activityTracker.markActive()
        }
        handlePressSignal(source: "debug", pressure: 1.0, location: location)
    }

    func hasRecentTrackpadActivity(now: Date = Date(), within interval: TimeInterval = 0.75) -> Bool {
        lock.withLock {
            activityTracker.hasRecentTrackpadActivity(now: now, within: interval)
        }
    }

    private func startMultitouch() {
        guard multitouch == nil else { return }

        guard let bridge = MultitouchSupportBridge.load() else {
            emitDebug("MultitouchSupport 不可用，无法读取原始触控板手指数")
            return
        }

        let loadedDevices = bridge.devices()
        guard !loadedDevices.isEmpty else {
            emitDebug("MultitouchSupport 未返回触控设备")
            return
        }

        multitouch = bridge
        devices = loadedDevices
        for device in loadedDevices {
            bridge.register(device: device, callback: Self.touchCallback)
            bridge.start(device: device)
        }

        emitDebug("MultitouchSupport 已启动 · devices \(loadedDevices.count)")
    }

    private func stopMultitouch() {
        guard let multitouch else { return }

        let activeDevices = devices
        for device in activeDevices {
            multitouch.unregister(device: device, callback: Self.touchCallback)
        }

        // The private framework may still have an in-flight callback immediately
        // after unregistering. A short delay avoids racing its cleanup thread.
        Thread.sleep(forTimeInterval: 0.06)

        for device in activeDevices {
            multitouch.stop(device: device)
        }

        devices.removeAll()
        self.multitouch = nil
    }

    private func startPressureMonitor() {
        guard pressureMonitor == nil else { return }

        pressureMonitor = NSEvent.addGlobalMonitorForEvents(matching: .pressure) { [weak self] event in
            guard event.stage >= 1 || event.pressure >= 0.70 else { return }
            self?.handlePressSignal(
                source: "pressure",
                pressure: Double(max(event.pressure, Float(event.stage))),
                location: NSEvent.mouseLocation
            )
        }
        emitDebug("三指按压 pressure 监听已启动")
    }

    private func stopPressureMonitor() {
        if let pressureMonitor {
            NSEvent.removeMonitor(pressureMonitor)
        }
        pressureMonitor = nil
    }

    private func handleTouchFrame(fingerCount: Int, timestamp: Double, frame: Int32, contacts: [MTContact]) {
        lock.withLock {
            recognizer.updateTouchCount(fingerCount)
            let activeSamples = contacts
                .filter(\.isActiveContact)
                .map(\.trackpadSample)
            activityTracker.update(contacts: activeSamples)
        }

        if let rawPressure = rawForcePressure(from: contacts) {
            handlePressSignal(source: "rawForceTouch", pressure: rawPressure, location: NSEvent.mouseLocation)
        }

        if fingerCount > 0 {
            emitTouchDebug(fingerCount: fingerCount, timestamp: timestamp, frame: frame, contacts: contacts)
        }
    }

    private func rawForcePressure(from contacts: [MTContact]) -> Double? {
        guard contacts.count == 3 else { return nil }

        let activeContacts = contacts.filter { $0.state != 7 && $0.size > 0 }
        guard activeContacts.count == 3 else { return nil }

        let sizes = activeContacts.map { Double($0.size) }
        let minimumSize = sizes.min() ?? 0
        let averageSize = sizes.reduce(0, +) / Double(sizes.count)
        let forceStateCount = activeContacts.filter { contact in
            contact.state == 3 || contact.state == 4 || contact.state == 5 || contact.state == 6
        }.count

        guard minimumSize >= 0.55, averageSize >= 0.75, forceStateCount >= 2 else {
            return nil
        }

        return min(1.0, averageSize)
    }

    private func handlePressSignal(source: String, pressure: Double, location: CGPoint) {
        let recognition = lock.withLock {
            recognizer.press(pressure: pressure)
        }

        guard let recognition else {
            emitDebug("\(source) · 未命中三指按压 · pressure \(String(format: "%.2f", pressure))")
            return
        }

        emitDebug("\(source) · 命中三指按压 \(recognition.touchCount) · pressure \(String(format: "%.2f", recognition.pressure))")
        DispatchQueue.main.async { [weak self] in
            self?.onPress?(ThreeFingerPressEvent(touchCount: recognition.touchCount, location: location))
        }
    }

    private func emitDebug(_ detail: String) {
        Self.appendDebugLine(detail)
        Self.logger.info("\(detail, privacy: .public)")
        DispatchQueue.main.async { [weak self] in
            self?.onDebugEvent?(detail)
        }
    }

    private func emitTouchDebug(fingerCount: Int, timestamp: Double, frame: Int32, contacts: [MTContact]) {
        let now = Date()
        let shouldEmit = fingerCount != lastTouchDebugCount ||
            now.timeIntervalSince(lastTouchDebugDate) >= 0.5
        guard shouldEmit else { return }

        lastTouchDebugCount = fingerCount
        lastTouchDebugDate = now
        let contactSummary = contacts
            .prefix(5)
            .map { contact in
                "id \(contact.identifier) state \(contact.state) size \(String(format: "%.3f", contact.size)) major \(String(format: "%.3f", contact.majorAxis)) minor \(String(format: "%.3f", contact.minorAxis))"
            }
            .joined(separator: " | ")
        emitDebug("rawTouch · fingers \(fingerCount) · frame \(frame) · \(String(format: "%.3f", timestamp)) · \(contactSummary)")
    }

    private static func appendDebugLine(_ detail: String) {
        let line = "\(Date()) \(detail)\n"
        let url = URL(fileURLWithPath: "/tmp/touchable-threefinger.log")
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

    private static let touchCallback: MTContactCallbackFunction = { _, data, fingerCount, timestamp, frame in
        var contacts: [MTContact] = []
        if let data {
            let contactData = data.assumingMemoryBound(to: MTContact.self)
            contacts = (0..<Int(fingerCount)).map { contactData[$0] }
        }
        activeService?.handleTouchFrame(fingerCount: Int(fingerCount), timestamp: timestamp, frame: frame, contacts: contacts)
        return 0
    }

}

private typealias MTDeviceRef = UnsafeMutableRawPointer
private typealias MTContactCallbackFunction = @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafeMutableRawPointer?,
    Int32,
    Double,
    Int32
) -> Int32

private struct MTPoint {
    var x: Float
    var y: Float
}

private struct MTVector {
    var position: MTPoint
    var velocity: MTPoint
}

private struct MTContact {
    var frame: Int32
    var timestamp: Double
    var identifier: Int32
    var state: Int32
    var unknown1: Int32
    var unknown2: Int32
    var normalized: MTVector
    var size: Float
    var unknown3: Int32
    var angle: Float
    var majorAxis: Float
    var minorAxis: Float
    var unknown4: MTVector
    var unknown5_1: Int32
    var unknown5_2: Int32
    var unknown6: Float
}

private extension MTContact {
    var isActiveContact: Bool {
        state != 7 && size > 0
    }

    var trackpadSample: TrackpadContactSample {
        TrackpadContactSample(
            identifier: Int(identifier),
            x: Double(normalized.position.x),
            y: Double(normalized.position.y),
            velocityX: Double(normalized.velocity.x),
            velocityY: Double(normalized.velocity.y)
        )
    }
}

private final class MultitouchSupportBridge {
    private typealias MTDeviceCreateListFunction = @convention(c) () -> Unmanaged<CFArray>?
    private typealias MTRegisterContactFrameCallbackFunction = @convention(c) (MTDeviceRef, MTContactCallbackFunction) -> Void
    private typealias MTUnregisterContactFrameCallbackFunction = @convention(c) (MTDeviceRef, MTContactCallbackFunction?) -> Void
    private typealias MTDeviceStartFunction = @convention(c) (MTDeviceRef, Int32) -> Void
    private typealias MTDeviceStopFunction = @convention(c) (MTDeviceRef) -> Void

    private let handle: UnsafeMutableRawPointer
    private let createList: MTDeviceCreateListFunction
    private let registerCallback: MTRegisterContactFrameCallbackFunction
    private let unregisterCallback: MTUnregisterContactFrameCallbackFunction?
    private let startDevice: MTDeviceStartFunction
    private let stopDevice: MTDeviceStopFunction?
    private var retainedDeviceList: CFArray?

    private init?() {
        let path = "/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport"
        guard let handle = dlopen(path, RTLD_LAZY | RTLD_LOCAL) else {
            return nil
        }

        guard let createList: MTDeviceCreateListFunction = Self.symbol("MTDeviceCreateList", handle: handle),
              let registerCallback: MTRegisterContactFrameCallbackFunction = Self.symbol("MTRegisterContactFrameCallback", handle: handle),
              let startDevice: MTDeviceStartFunction = Self.symbol("MTDeviceStart", handle: handle)
        else {
            dlclose(handle)
            return nil
        }

        self.handle = handle
        self.createList = createList
        self.registerCallback = registerCallback
        self.unregisterCallback = Self.symbol("MTUnregisterContactFrameCallback", handle: handle)
        self.startDevice = startDevice
        self.stopDevice = Self.symbol("MTDeviceStop", handle: handle)
    }

    deinit {
        dlclose(handle)
    }

    static func load() -> MultitouchSupportBridge? {
        MultitouchSupportBridge()
    }

    func devices() -> [MTDeviceRef] {
        guard let unmanagedArray = createList() else { return [] }
        let array = unmanagedArray.takeRetainedValue()
        retainedDeviceList = array
        let count = CFArrayGetCount(array)
        guard count > 0 else { return [] }

        return (0..<count).compactMap { index in
            guard let value = CFArrayGetValueAtIndex(array, index) else { return nil }
            return UnsafeMutableRawPointer(mutating: value)
        }
    }

    func register(device: MTDeviceRef, callback: MTContactCallbackFunction) {
        registerCallback(device, callback)
    }

    func unregister(device: MTDeviceRef, callback: MTContactCallbackFunction) {
        unregisterCallback?(device, callback)
    }

    func start(device: MTDeviceRef) {
        startDevice(device, 0)
    }

    func stop(device: MTDeviceRef) {
        stopDevice?(device)
    }

    private static func symbol<T>(_ name: String, handle: UnsafeMutableRawPointer) -> T? {
        guard let symbol = dlsym(handle, name) else { return nil }
        return unsafeBitCast(symbol, to: T.self)
    }
}

private extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}
