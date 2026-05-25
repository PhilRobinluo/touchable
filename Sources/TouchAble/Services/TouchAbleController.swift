import AppKit
import Combine
import Foundation
import TouchAbleCore

@MainActor
final class TouchAbleController: ObservableObject {
    @Published private(set) var accessibilityTrusted: Bool
    @Published private(set) var inputMonitoringTrusted: Bool
    @Published private(set) var lastZone: HapticZone = .quiet
    @Published private(set) var isRunning = false
    @Published private(set) var pointerDescription = "未读取"
    @Published private(set) var cursorDescription = "未读取"
    @Published private(set) var semanticRole = "未探测"
    @Published private(set) var inputSourceDescription = "未识别"
    @Published private(set) var pointerEventDescription = "未收到"
    @Published private(set) var threeFingerShortcutDescription = "未启用"
    @Published private(set) var candidateDescription = "等待"
    @Published private(set) var lastDecision = "等待"
    @Published private(set) var lastPulseDescription = "尚未触发"
    @Published private(set) var pulseCount = 0
    @Published private(set) var debugEvents: [DebugEvent] = []
    @Published private(set) var profileDescription = "未读取"

    private let preferences: PreferenceStore
    private let accessibility = AccessibilityPermissionService()
    private let inputMonitoring = InputMonitoringPermissionService()
    private let haptics = HapticFeedbackService()
    private let pointerEventTap = PointerEventTapService()
    private let pointerSource = PointerSourceService()
    private let threeFingerPress = ThreeFingerPressService()
    private let shortcutSender = KeyboardShortcutSender()
    private let cursorProbe = CursorProbeService()
    private let semanticProbe = SemanticProbeService()
    private let throttler = HapticThrottler()
    private let eventThrottler = HapticThrottler()
    private let playgroundThrottler = HapticThrottler()

    private var timer: Timer?
    private var cancellables: Set<AnyCancellable> = []
    private var tickCount = 0
    private var pointerEventCounter = 0
    private var lastTickPointerLocation: CGPoint?
    private var lastSemanticProbeLocation: CGPoint?
    private var lastSemanticProbeResult: SemanticProbeResult?
    private var lastSemanticProbeDate: Date = .distantPast

    init(preferences: PreferenceStore) {
        self.preferences = preferences
        accessibilityTrusted = accessibility.isTrusted
        inputMonitoringTrusted = inputMonitoring.isTrusted
        configurePointerEvents()
        configurePointerSourceMonitoring()
        configureTrackpadInputMonitoring()
        observeTimingPreferences()
        start()
    }

    deinit {
        timer?.invalidate()
        pointerEventTap.stop()
        pointerSource.stop()
        threeFingerPress.stop()
    }

    func start() {
        guard timer == nil else { return }

        let timer = Timer(timeInterval: preferences.pointerPollingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }

        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        isRunning = true
    }

    private func restartTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        start()
        record(
            title: "刷新轮询",
            detail: "光标轮询 \(Int(preferences.pointerPollingHertz.rounded()))Hz",
            zone: nil
        )
    }

    private func observeTimingPreferences() {
        preferences.$pointerPollingHertz
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                self?.restartTimer()
            }
            .store(in: &cancellables)

        preferences.$threeFingerShortcutEnabled
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] isEnabled in
                self?.configureTrackpadInputMonitoring()
                self?.record(
                    title: isEnabled ? "三指快捷键已开启" : "三指快捷键已关闭",
                    detail: isEnabled ? "三指按下会发送映射快捷键" : "仍保留触控板输入识别，用于过滤鼠标触发",
                    zone: nil
                )
                self?.updateThreeFingerShortcutDescription()
            }
            .store(in: &cancellables)
    }

    func requestAccessibilityPermission() {
        accessibility.requestPermission()
        refreshAccessibilityStatus()
        record(title: "请求权限", detail: "已打开辅助功能授权提示", zone: nil)
    }

    func requestInputMonitoringPermission() {
        let granted = inputMonitoring.requestPermission()
        refreshInputMonitoringStatus()
        if granted {
            configurePointerEvents()
        }
        record(
            title: "请求输入监控",
            detail: granted ? "输入监控已授权" : "已打开输入监控授权提示，请在系统设置里允许 TouchAble",
            zone: nil
        )
    }

    func pulseForPlayground(zone: HapticZone, identity: String) {
        pulseForLocalSurface(zone: zone, identity: "playground:\(identity)")
    }

    func pulseForLocalSurface(zone: HapticZone, identity: String) {
        guard preferences.isEnabled else { return }
        let profile = preferences.profile
        let signal = HapticSignal(zone: zone, identity: "local:\(identity)")
        guard playgroundThrottler.shouldPulse(signal: signal, profile: profile) else { return }
        haptics.perform(zone: zone, profile: profile)
        recordPulse(zone: zone, detail: "本地窗口: \(identity)")
    }

    func testPulse(zone: HapticZone) {
        haptics.perform(zone: zone, profile: preferences.profile)
        recordPulse(zone: zone, detail: "手动测试触觉")
    }

    func testThreeFingerShortcut() {
        let shortcut = preferences.threeFingerShortcut
        guard shortcut.isValid else {
            record(title: "测试快捷键失败", detail: "三指快捷键未设置按键", zone: nil)
            return
        }

        shortcutSender.send(shortcut)
        record(title: "测试快捷键", detail: "手动发送 \(shortcut.displayName)", zone: .control)
    }

    func simulateThreeFingerPressForDebug() {
        threeFingerPress.simulateThreeFingerPressForDebug(location: NSEvent.mouseLocation)
    }

    private func configurePointerEvents() {
        pointerEventTap.onEvent = { [weak self] kind, location in
            self?.handlePointerEvent(kind, location: location)
        }

        let started = pointerEventTap.start()
        refreshInputMonitoringStatus()
        record(
            title: started ? "事件监听已启动" : "事件监听失败",
            detail: started ? "CGEvent tap 正在监听点击、拖拽、滚动" : "需要输入监控权限才能监听真实点击、拖拽、滚动",
            zone: nil
        )
    }

    private func configurePointerSourceMonitoring() {
        pointerSource.onDebugEvent = { [weak self] detail in
            self?.record(title: "输入来源探针", detail: detail, zone: nil)
        }

        let started = pointerSource.start()
        record(
            title: started ? "输入来源监听已启动" : "输入来源监听失败",
            detail: started ? "HID 正在监听鼠标设备的移动和滚轮" : "无法启动 HID 鼠标来源监听",
            zone: nil
        )
    }

    private func configureTrackpadInputMonitoring() {
        threeFingerPress.onPress = { [weak self] event in
            self?.handleThreeFingerPress(event)
        }
        threeFingerPress.onDebugEvent = { [weak self] detail in
            self?.record(title: "三指事件探针", detail: detail, zone: nil)
        }
        threeFingerPress.start()
        updateThreeFingerShortcutDescription()
        record(title: "触控板输入监听已启动", detail: "用于三指快捷键和仅触控板触发过滤", zone: nil)
    }

    private func handlePointerEvent(_ kind: PointerEventKind, location: CGPoint) {
        pointerEventDescription = "\(kind.displayName) · x \(Int(location.x)), y \(Int(location.y))"

        guard preferences.isEnabled,
              let zone = kind.zone
        else {
            return
        }

        if kind == .scrolled {
            guard preferences.scrollHapticsEnabled else { return }
        } else {
            guard preferences.pointerEventHapticsEnabled else { return }
        }

        guard allowsGlobalHapticTrigger(context: kind.displayName) else { return }

        let profile = preferences.profile
        pointerEventCounter += 1

        let quantizedX = Int(location.x / 18)
        let quantizedY = Int(location.y / 18)
        let identity = "event:\(kind.rawValue):\(quantizedX):\(quantizedY):\(pointerEventCounter % 4)"
        let signal = HapticSignal(zone: zone, identity: identity)

        guard eventThrottler.shouldPulse(signal: signal, profile: profile) else { return }

        let detail = "全局\(kind.displayName): x \(Int(location.x)), y \(Int(location.y))"
        let hapticDelay = max(0, min(0.2, preferences.pointerEventDelay))
        if hapticDelay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + hapticDelay) { [weak self] in
                guard let self else { return }
                self.haptics.perform(zone: zone, profile: profile)
                self.recordPulse(zone: zone, detail: "\(detail) · 延迟\(String(format: "%.2f", hapticDelay))s")
            }
        } else {
            haptics.perform(zone: zone, profile: profile)
            recordPulse(zone: zone, detail: detail)
        }
    }

    private func handleThreeFingerPress(_ event: ThreeFingerPressEvent) {
        updateThreeFingerShortcutDescription()

        guard preferences.isEnabled,
              preferences.threeFingerShortcutEnabled
        else {
            return
        }

        let shortcut = preferences.threeFingerShortcut
        guard shortcut.isValid else {
            record(title: "三指按下", detail: "未设置快捷键", zone: nil)
            return
        }

        shortcutSender.send(shortcut)
        let detail = "\(event.touchCount) 指 · x \(Int(event.location.x)), y \(Int(event.location.y)) · 发送 \(shortcut.displayName)"
        threeFingerShortcutDescription = shortcut.displayName
        record(title: "三指快捷键", detail: detail, zone: .control)
    }

    func clearDebugEvents() {
        debugEvents.removeAll()
        record(title: "清空日志", detail: "调试事件已重置", zone: nil)
    }

    private func tick() {
        tickCount += 1
        let permissionRefreshTicks = max(10, Int(preferences.pointerPollingHertz.rounded()))
        if tickCount % permissionRefreshTicks == 0 {
            refreshAccessibilityStatus()
            refreshInputMonitoringStatus()
            if inputMonitoringTrusted {
                _ = pointerEventTap.start()
            }
        }

        let pointerLocation = NSEvent.mouseLocation
        updatePointerDescription(location: pointerLocation)

        guard preferences.isEnabled else {
            throttler.reset()
            lastZone = .quiet
            setText(\.candidateDescription, "总开关关闭")
            setText(\.lastDecision, "未运行")
            lastTickPointerLocation = pointerLocation
            return
        }

        let profile = preferences.profile
        updateProfileDescription(profile)
        updateCursorDescription(profile: profile)

        guard pointerMovedEnough(pointerLocation) else {
            setText(\.candidateDescription, "光标静止")
            setText(\.lastDecision, "静止不触发")
            return
        }

        guard allowsGlobalHapticTrigger(context: "光标移动") else {
            throttler.reset()
            lastZone = .quiet
            lastTickPointerLocation = pointerLocation
            return
        }

        let signal = currentSignal(profile: profile)
        lastTickPointerLocation = pointerLocation

        guard let signal else {
            throttler.reset()
            lastZone = .quiet
            return
        }

        let decision = throttler.decision(for: signal, profile: profile)
        setText(\.lastDecision, decision.displayReason)
        guard decision == .allowed else { return }
        guard throttler.shouldPulse(signal: signal, profile: profile) else { return }

        haptics.perform(zone: signal.zone, profile: profile)
        lastZone = signal.zone
        recordPulse(zone: signal.zone, detail: signal.identity)
    }

    private func currentSignal(profile: HapticProfile) -> HapticSignal? {
        if preferences.edgeHapticsEnabled,
           let edgeSignal = EdgeDetector.signal(
            for: NSEvent.mouseLocation,
            in: NSScreen.screens.map(\.frame),
            profile: profile
           ) {
            setText(\.semanticRole, "未探测")
            setText(\.candidateDescription, "边缘命中: \(edgeSignal.identity)")
            setText(\.lastDecision, "等待节流判断")
            return edgeSignal
        }

        guard preferences.semanticHapticsEnabled,
              accessibilityTrusted
        else {
            setText(\.semanticRole, accessibilityTrusted ? "语义开关关闭" : "未授权")
            return currentCursorSignalOrNil(profile: profile, fallbackReason: accessibilityTrusted ? "语义触感关闭" : "需要辅助功能权限")
        }

        let result = cachedSemanticResult(profile: profile)
        setText(\.semanticRole, result.role)

        if let signal = result.signal {
            setText(\.candidateDescription, result.reason)
            setText(\.lastDecision, "等待节流判断")
            return signal
        }

        return currentCursorSignalOrNil(profile: profile, fallbackReason: result.reason)
    }

    private func refreshAccessibilityStatus() {
        let latest = accessibility.isTrusted
        if latest != accessibilityTrusted {
            accessibilityTrusted = latest
            record(
                title: "权限变化",
                detail: latest ? "辅助功能已授权" : "辅助功能未授权",
                zone: nil
            )
        } else {
            accessibilityTrusted = latest
        }
    }

    private func refreshInputMonitoringStatus() {
        let latest = inputMonitoring.isTrusted
        if latest != inputMonitoringTrusted {
            inputMonitoringTrusted = latest
            record(
                title: "输入监控变化",
                detail: latest ? "输入监控已授权" : "输入监控未授权",
                zone: nil
            )
        } else {
            inputMonitoringTrusted = latest
        }
    }

    private func updatePointerDescription(location: CGPoint) {
        let nextDescription = "x \(Int(location.x)), y \(Int(location.y))"
        if pointerDescription != nextDescription {
            pointerDescription = nextDescription
        }
    }

    private func pointerMovedEnough(_ location: CGPoint) -> Bool {
        guard let lastTickPointerLocation else {
            lastTickPointerLocation = location
            return false
        }

        return abs(lastTickPointerLocation.x - location.x) >= 2 ||
            abs(lastTickPointerLocation.y - location.y) >= 2
    }

    private func updateCursorDescription(profile: HapticProfile) {
        let nextDescription = cursorProbe.currentResult(profile: profile).name
        if cursorDescription != nextDescription {
            cursorDescription = nextDescription
        }
    }

    private func currentCursorSignalOrNil(profile: HapticProfile, fallbackReason: String) -> HapticSignal? {
        guard preferences.cursorHapticsEnabled else {
            setText(\.candidateDescription, fallbackReason)
            setText(\.lastDecision, "光标触感关闭")
            return nil
        }

        let result = cursorProbe.currentResult(profile: profile)

        guard let signal = result.signal else {
            setText(\.candidateDescription, "\(fallbackReason)；光标 \(result.reason)")
            setText(\.lastDecision, "无候选触觉")
            return nil
        }

        setText(\.candidateDescription, result.reason)
        setText(\.lastDecision, "等待节流判断")
        return signal
    }

    private func allowsGlobalHapticTrigger(context: String) -> Bool {
        guard preferences.trackpadOnlyHapticsEnabled else {
            setText(\.inputSourceDescription, "不限制")
            return true
        }

        if pointerSource.hasRecentExternalMouseActivity() {
            setText(\.inputSourceDescription, "鼠标")
            setText(\.candidateDescription, "仅触控板触发")
            setText(\.lastDecision, "\(context) 来自鼠标，跳过")
            return false
        }

        let hasRecentTrackpadActivity = threeFingerPress.hasRecentTrackpadActivity()
        setText(\.inputSourceDescription, hasRecentTrackpadActivity ? "触控板" : "鼠标 / 未知")
        guard hasRecentTrackpadActivity else {
            setText(\.candidateDescription, "仅触控板触发")
            setText(\.lastDecision, "\(context) 来自鼠标 / 未知，跳过")
            return false
        }

        return true
    }

    private func updateProfileDescription(_ profile: HapticProfile) {
        let repeatText = profile.sameIdentityRepeatInterval.map { String(format: "%.2fs", $0) } ?? "关闭"
        let modeText = profile.intensityLevel >= 6 ? "增强混合" : "标准"
        let inputMode = preferences.trackpadOnlyHapticsEnabled ? "仅触控板" : "不限输入"
        let nextDescription = "强度 \(profile.intensityLevel) · \(profile.pulseCount) 次脉冲 · \(modeText) · 节流 \(String(format: "%.2fs", profile.minimumInterval)) · 轮询 \(Int(preferences.pointerPollingHertz.rounded()))Hz · 操作延时 \(String(format: "%.2fs", preferences.pointerEventDelay)) · 重触发 \(repeatText) · \(inputMode)"
        if profileDescription != nextDescription {
            profileDescription = nextDescription
        }
        updateThreeFingerShortcutDescription()
    }

    private func updateThreeFingerShortcutDescription() {
        let nextDescription = preferences.threeFingerShortcutEnabled ? preferences.threeFingerShortcut.displayName : "未启用"
        if threeFingerShortcutDescription != nextDescription {
            threeFingerShortcutDescription = nextDescription
        }
    }

    private func cachedSemanticResult(profile: HapticProfile) -> SemanticProbeResult {
        let location = NSEvent.mouseLocation
        let now = Date()
        if let lastSemanticProbeLocation,
           let lastSemanticProbeResult,
           abs(lastSemanticProbeLocation.x - location.x) < 3,
           abs(lastSemanticProbeLocation.y - location.y) < 3,
           now.timeIntervalSince(lastSemanticProbeDate) < 0.5 {
            return lastSemanticProbeResult
        }

        let result = semanticProbe.currentResult(profile: profile)
        lastSemanticProbeLocation = location
        lastSemanticProbeResult = result
        lastSemanticProbeDate = now
        return result
    }

    private func setText(_ keyPath: ReferenceWritableKeyPath<TouchAbleController, String>, _ value: String) {
        if self[keyPath: keyPath] != value {
            self[keyPath: keyPath] = value
        }
    }

    private func recordPulse(zone: HapticZone, detail: String) {
        pulseCount += 1
        lastZone = zone
        lastPulseDescription = "\(zone.displayName) · \(Date.now.formatted(date: .omitted, time: .standard))"
        record(title: "触发 \(zone.displayName)", detail: detail, zone: zone)
    }

    private func record(title: String, detail: String, zone: HapticZone?) {
        debugEvents.insert(DebugEvent(title: title, detail: detail, zone: zone), at: 0)
        if debugEvents.count > 80 {
            debugEvents.removeLast(debugEvents.count - 80)
        }
    }
}
