import AppKit
import ApplicationServices
import CoreGraphics
import Foundation
import os

@MainActor
struct CleanKeyPermissionManager {
    var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    func promptAccessibilityPermission() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func openAccessibilitySettings() {
        SystemSettingsNavigator.openAccessibilityPrivacy()
    }
}

@MainActor
final class CleanKeyCountdownManager: ObservableObject {
    @Published private(set) var remainingSeconds = 0
    @Published private(set) var isActive = false

    private var timerTask: Task<Void, Never>?
    var onFinish: (() -> Void)?

    func start(duration: Int) {
        cancel()
        remainingSeconds = duration
        isActive = true

        timerTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let startTime = Date()

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 200_000_000)
                guard !Task.isCancelled else { break }

                let elapsed = Date().timeIntervalSince(startTime)
                let remaining = max(0, duration - Int(elapsed))
                remainingSeconds = remaining

                if remaining <= 0 {
                    isActive = false
                    onFinish?()
                    break
                }
            }
        }
    }

    func cancel() {
        timerTask?.cancel()
        timerTask = nil
        isActive = false
    }
}

@MainActor
final class CleanKeySoundManager {
    static let shared = CleanKeySoundManager()
    private init() {}

    func playLock() {
        NSSound(named: "Purr")?.play()
    }

    func playUnlock() {
        NSSound(named: "Glass")?.play()
    }

    func playTap(progress: Double) {
        if progress >= 1.0 {
            playUnlock()
        } else {
            NSSound(named: "Tink")?.play()
        }
    }
}

private struct CleanKeyEventTapContext {
    var isLocked = false
    var allowedPID: pid_t = 0
    var tapRunLoop: CFRunLoop?
}

nonisolated(unsafe) private var cleanKeyContextLock = os_unfair_lock()
nonisolated(unsafe) private var cleanKeyContext = CleanKeyEventTapContext()
nonisolated(unsafe) private var cleanKeyEventTap: CFMachPort?
nonisolated(unsafe) private var cleanKeyRunLoopSource: CFRunLoopSource?
nonisolated(unsafe) private weak var cleanKeyCurrentBlocker: CleanKeyEventBlocker?

private func cleanKeyRead<T>(_ keyPath: KeyPath<CleanKeyEventTapContext, T>) -> T {
    withUnsafeMutablePointer(to: &cleanKeyContextLock, os_unfair_lock_lock)
    defer { withUnsafeMutablePointer(to: &cleanKeyContextLock, os_unfair_lock_unlock) }
    return cleanKeyContext[keyPath: keyPath]
}

private func cleanKeyWrite<T>(_ keyPath: WritableKeyPath<CleanKeyEventTapContext, T>, _ value: T) {
    withUnsafeMutablePointer(to: &cleanKeyContextLock, os_unfair_lock_lock)
    defer { withUnsafeMutablePointer(to: &cleanKeyContextLock, os_unfair_lock_unlock) }
    cleanKeyContext[keyPath: keyPath] = value
}

private enum CleanKeyEventBlockerConstants {
    static let escKeyCode: CGKeyCode = 53
    static let sysDefinedEventType: UInt32 = 14
    static let escTapRequired = 5
    static let escTapResetDelay: TimeInterval = 3.0
    static let runLoopPollInterval: CFTimeInterval = 0.5
}

// Read both fields inside the same lock to prevent a torn read
// between the guard check and the subsequent use.
private func cleanKeyReadLockState() -> (isLocked: Bool, blocker: CleanKeyEventBlocker?) {
    withUnsafeMutablePointer(to: &cleanKeyContextLock, os_unfair_lock_lock)
    defer { withUnsafeMutablePointer(to: &cleanKeyContextLock, os_unfair_lock_unlock) }
    return (cleanKeyContext.isLocked, cleanKeyCurrentBlocker)
}

private func cleanKeyHandleEventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    _: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    let (isLocked, blocker) = cleanKeyReadLockState()
    guard isLocked, let blocker else {
        return Unmanaged.passUnretained(event)
    }

    return blocker.handleEvent(proxy: proxy, type: type, event: event)
}

final class CleanKeyEventBlocker {
    private let eventQueue = DispatchQueue(label: "com.gravity.heybar.cleankey", qos: .userInteractive)
    private let stateLock = NSLock()

    private var onEscTapProgress: ((Double) -> Void)?
    private var onEscTapTriggered: (() -> Void)?
    private var onTapInterruption: (() -> Void)?
    private var escTapCount = 0
    private var escTapResetTimer: DispatchSourceTimer?

    func start(
        allowedProcessID: pid_t,
        onEscTapProgress: ((Double) -> Void)?,
        onEscTapTriggered: (() -> Void)?,
        onTapInterruption: (() -> Void)?
    ) -> Bool {
        guard !cleanKeyRead(\.isLocked) else { return true }

        cleanKeyWrite(\.allowedPID, allowedProcessID)
        cleanKeyCurrentBlocker = self

        stateLock.lock()
        self.onEscTapProgress = onEscTapProgress
        self.onEscTapTriggered = onEscTapTriggered
        self.onTapInterruption = onTapInterruption
        escTapCount = 0
        stateLock.unlock()

        let semaphore = DispatchSemaphore(value: 0)
        eventQueue.async {
            let runLoop = CFRunLoopGetCurrent()
            cleanKeyWrite(\.tapRunLoop, runLoop)

            guard let tap = Self.createEventTap() else {
                cleanKeyWrite(\.tapRunLoop, nil)
                semaphore.signal()
                return
            }

            let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            CFRunLoopAddSource(runLoop, source, .commonModes)
            cleanKeyEventTap = tap
            cleanKeyRunLoopSource = source
            cleanKeyWrite(\.isLocked, true)
            CGEvent.tapEnable(tap: tap, enable: true)

            semaphore.signal()

            while cleanKeyRead(\.isLocked) {
                CFRunLoopRunInMode(.defaultMode, CleanKeyEventBlockerConstants.runLoopPollInterval, false)
            }

            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
            CFRunLoopRemoveSource(runLoop, source, .commonModes)
            cleanKeyEventTap = nil
            cleanKeyRunLoopSource = nil
            cleanKeyWrite(\.tapRunLoop, nil)
            cleanKeyWrite(\.isLocked, false)
        }

        // 2-second timeout prevents indefinite blocking if the event-tap thread
        // fails to signal (e.g. denied by the system sandbox).
        guard semaphore.wait(timeout: .now() + 2.0) == .success else { return false }
        return cleanKeyRead(\.isLocked)
    }

    func stop() {
        cleanKeyWrite(\.isLocked, false)
        stateLock.lock()
        escTapResetTimer?.cancel()
        escTapResetTimer = nil
        escTapCount = 0
        onEscTapProgress = nil
        onEscTapTriggered = nil
        onTapInterruption = nil
        stateLock.unlock()

        if let runLoop = cleanKeyRead(\.tapRunLoop) {
            CFRunLoopStop(runLoop)
        }
    }

    private static func createEventTap() -> CFMachPort? {
        let types: [CGEventType] = [
            .keyDown, .keyUp, .flagsChanged,
            .leftMouseDown, .leftMouseUp, .leftMouseDragged,
            .rightMouseDown, .rightMouseUp, .rightMouseDragged,
            .otherMouseDown, .otherMouseUp, .otherMouseDragged,
            .scrollWheel, .mouseMoved
        ]
        let sysMask = CGEventMask(1 << CleanKeyEventBlockerConstants.sysDefinedEventType)
        let mask = types.reduce(CGEventMask(0)) { $0 | (1 << $1.rawValue) } | sysMask

        return CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: cleanKeyHandleEventTapCallback,
            userInfo: nil
        )
    }

    func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap = cleanKeyEventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            stateLock.lock()
            let interruption = onTapInterruption
            stateLock.unlock()
            interruption?()
            return Unmanaged.passUnretained(event)

        case .keyDown, .keyUp, .flagsChanged:
            if NSWorkspace.shared.isVoiceOverEnabled {
                let flags = event.flags
                if type == .flagsChanged || flags.contains([.maskControl, .maskAlternate]) {
                    return Unmanaged.passUnretained(event)
                }
            }
            if type == .keyDown {
                let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
                if keyCode == CleanKeyEventBlockerConstants.escKeyCode {
                    handleEscTap()
                } else {
                    resetEscTap()
                }
            }
            return nil

        case .mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged, .scrollWheel:
            return nil

        case .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp, .otherMouseDown, .otherMouseUp:
            let pid = pid_t(event.getIntegerValueField(.eventTargetUnixProcessID))
            return pid == cleanKeyRead(\.allowedPID) ? Unmanaged.passUnretained(event) : nil

        default:
            if type.rawValue == CleanKeyEventBlockerConstants.sysDefinedEventType {
                return nil
            }
            return Unmanaged.passUnretained(event)
        }
    }

    private func resetEscTap() {
        stateLock.lock()
        guard escTapCount > 0 else {
            stateLock.unlock()
            return
        }
        escTapCount = 0
        escTapResetTimer?.cancel()
        escTapResetTimer = nil
        let callback = onEscTapProgress
        stateLock.unlock()
        callback?(0)
    }

    private func handleEscTap() {
        stateLock.lock()
        escTapCount += 1
        let count = escTapCount
        let progressCallback = onEscTapProgress
        let triggeredCallback = onEscTapTriggered

        escTapResetTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: eventQueue)
        timer.schedule(deadline: .now() + CleanKeyEventBlockerConstants.escTapResetDelay)
        timer.setEventHandler { [weak self] in
            self?.resetEscTap()
        }
        timer.resume()
        escTapResetTimer = timer
        stateLock.unlock()

        let progress = Double(count) / Double(CleanKeyEventBlockerConstants.escTapRequired)
        progressCallback?(min(progress, 1))

        if count >= CleanKeyEventBlockerConstants.escTapRequired {
            triggeredCallback?()
        }
    }
}
