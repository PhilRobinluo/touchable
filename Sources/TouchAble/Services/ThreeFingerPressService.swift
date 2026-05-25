import ApplicationServices
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
    private let lock = NSLock()

    private var multitouch: MultitouchSupportBridge?
    private var devices: [MTDeviceRef] = []
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var pressureMonitor: Any?
    private var lastTouchDebugDate: Date = .distantPast
    private var lastTouchDebugCount = -1

    deinit {
        stop()
    }

    func start() {
        guard eventTap == nil else { return }

        Self.activeService = self
        startMultitouch()
        startMouseDownTap()
        startPressureMonitor()
    }

    func stop() {
        stopMouseDownTap()
        stopPressureMonitor()
        stopMultitouch()
        lock.withLock {
            recognizer.reset()
        }

        if Self.activeService === self {
            Self.activeService = nil
        }
    }

    func simulateThreeFingerPressForDebug(location: CGPoint) {
        lock.withLock {
            recognizer.updateTouchCount(3)
        }
        handlePressSignal(source: "debug", pressure: 1.0, location: location)
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

    private func startMouseDownTap() {
        let mask =
            (1 << CGEventType.leftMouseDown.rawValue) |
            (1 << CGEventType.rightMouseDown.rawValue) |
            (1 << CGEventType.otherMouseDown.rawValue)

        let userInfo = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: Self.mouseCallback,
            userInfo: userInfo
        ) else {
            emitDebug("三指按下监听失败：需要输入监控权限")
            return
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        eventTap = tap
        runLoopSource = source
        emitDebug("三指按压 mouseDown 监听已启动")
    }

    private func stopMouseDownTap() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }

        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil
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

    private func handleTouchFrame(fingerCount: Int, timestamp: Double, frame: Int32) {
        lock.withLock {
            recognizer.updateTouchCount(fingerCount)
        }

        if fingerCount > 0 {
            emitTouchDebug(fingerCount: fingerCount, timestamp: timestamp, frame: frame)
        }
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

    private func emitTouchDebug(fingerCount: Int, timestamp: Double, frame: Int32) {
        let now = Date()
        let shouldEmit = fingerCount != lastTouchDebugCount ||
            now.timeIntervalSince(lastTouchDebugDate) >= 0.5
        guard shouldEmit else { return }

        lastTouchDebugCount = fingerCount
        lastTouchDebugDate = now
        emitDebug("rawTouch · fingers \(fingerCount) · frame \(frame) · \(String(format: "%.3f", timestamp))")
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

    private static let touchCallback: MTContactCallbackFunction = { _, _, fingerCount, timestamp, frame in
        activeService?.handleTouchFrame(fingerCount: Int(fingerCount), timestamp: timestamp, frame: frame)
        return 0
    }

    private static let mouseCallback: CGEventTapCallBack = { _, _, event, userInfo in
        guard let userInfo else {
            return Unmanaged.passUnretained(event)
        }

        let service = Unmanaged<ThreeFingerPressService>
            .fromOpaque(userInfo)
            .takeUnretainedValue()

        let location = event.location
        let pressure = event.getDoubleValueField(.mouseEventPressure)
        DispatchQueue.main.async {
            service.handlePressSignal(source: "mouseDown", pressure: pressure, location: location)
        }

        return Unmanaged.passUnretained(event)
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
