import AppKit
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
    @Published private(set) var pointerEventDescription = "未收到"
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
    private let cursorProbe = CursorProbeService()
    private let semanticProbe = SemanticProbeService()
    private let throttler = HapticThrottler()
    private let eventThrottler = HapticThrottler()
    private let playgroundThrottler = HapticThrottler()

    private var timer: Timer?
    private var tickCount = 0
    private var pointerEventCounter = 0

    init(preferences: PreferenceStore) {
        self.preferences = preferences
        accessibilityTrusted = accessibility.isTrusted
        inputMonitoringTrusted = inputMonitoring.isTrusted
        configurePointerEvents()
        start()
    }

    deinit {
        timer?.invalidate()
        pointerEventTap.stop()
    }

    func start() {
        guard timer == nil else { return }

        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }

        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        isRunning = true
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

    private func handlePointerEvent(_ kind: PointerEventKind, location: CGPoint) {
        pointerEventDescription = "\(kind.displayName) · x \(Int(location.x)), y \(Int(location.y))"

        guard preferences.isEnabled,
              preferences.pointerEventHapticsEnabled,
              let zone = kind.zone
        else {
            return
        }

        let profile = preferences.profile
        pointerEventCounter += 1

        let quantizedX = Int(location.x / 18)
        let quantizedY = Int(location.y / 18)
        let identity = "event:\(kind.rawValue):\(quantizedX):\(quantizedY):\(pointerEventCounter % 4)"
        let signal = HapticSignal(zone: zone, identity: identity)

        guard eventThrottler.shouldPulse(signal: signal, profile: profile) else { return }

        let detail = "全局\(kind.displayName): x \(Int(location.x)), y \(Int(location.y))"
        if kind.hapticDelay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + kind.hapticDelay) { [weak self] in
                guard let self else { return }
                self.haptics.perform(zone: zone, profile: profile)
                self.recordPulse(zone: zone, detail: "\(detail) · 延迟\(String(format: "%.2f", kind.hapticDelay))s")
            }
        } else {
            haptics.perform(zone: zone, profile: profile)
            recordPulse(zone: zone, detail: detail)
        }
    }

    func clearDebugEvents() {
        debugEvents.removeAll()
        record(title: "清空日志", detail: "调试事件已重置", zone: nil)
    }

    private func tick() {
        tickCount += 1
        if tickCount % 20 == 0 {
            refreshAccessibilityStatus()
            refreshInputMonitoringStatus()
            if inputMonitoringTrusted {
                _ = pointerEventTap.start()
            }
        }

        updatePointerDescription()

        guard preferences.isEnabled else {
            throttler.reset()
            lastZone = .quiet
            candidateDescription = "总开关关闭"
            lastDecision = "未运行"
            return
        }

        let profile = preferences.profile
        updateProfileDescription(profile)
        updateCursorDescription(profile: profile)
        let signal = currentSignal(profile: profile)

        guard let signal else {
            throttler.reset()
            lastZone = .quiet
            return
        }

        let decision = throttler.decision(for: signal, profile: profile)
        lastDecision = decision.displayReason
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
            semanticRole = "未探测"
            candidateDescription = "边缘命中: \(edgeSignal.identity)"
            lastDecision = "等待节流判断"
            return edgeSignal
        }

        guard preferences.semanticHapticsEnabled,
              accessibilityTrusted
        else {
            semanticRole = accessibilityTrusted ? "语义开关关闭" : "未授权"
            return currentCursorSignalOrNil(profile: profile, fallbackReason: accessibilityTrusted ? "语义触感关闭" : "需要辅助功能权限")
        }

        let result = semanticProbe.currentResult(profile: profile)
        semanticRole = result.role

        if let signal = result.signal {
            candidateDescription = result.reason
            lastDecision = "等待节流判断"
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

    private func updatePointerDescription() {
        let point = NSEvent.mouseLocation
        pointerDescription = "x \(Int(point.x)), y \(Int(point.y))"
    }

    private func updateCursorDescription(profile: HapticProfile) {
        cursorDescription = cursorProbe.currentResult(profile: profile).name
    }

    private func currentCursorSignalOrNil(profile: HapticProfile, fallbackReason: String) -> HapticSignal? {
        guard preferences.cursorHapticsEnabled else {
            candidateDescription = fallbackReason
            lastDecision = "光标触感关闭"
            return nil
        }

        let result = cursorProbe.currentResult(profile: profile)

        guard let signal = result.signal else {
            candidateDescription = "\(fallbackReason)；光标 \(result.reason)"
            lastDecision = "无候选触觉"
            return nil
        }

        candidateDescription = result.reason
        lastDecision = "等待节流判断"
        return signal
    }

    private func updateProfileDescription(_ profile: HapticProfile) {
        let repeatText = profile.sameIdentityRepeatInterval.map { String(format: "%.2fs", $0) } ?? "关闭"
        let modeText = profile.intensityLevel >= 6 ? "增强混合" : "标准"
        profileDescription = "强度 \(profile.intensityLevel) · \(profile.pulseCount) 次脉冲 · \(modeText) · 重触发 \(repeatText)"
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
