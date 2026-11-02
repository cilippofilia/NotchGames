//
//  NotchPanelController.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import AppKit
import SwiftUI

/// Owns the drop under the notch and the game panel that grows out of it.
///
/// The pointer is polled with `NSEvent.mouseLocation` and `NSEvent.pressedMouseButtons`, which need no permissions
/// and work in the sandbox. Polling is slow while the pointer is far from the notch and fast while it's close.
final class NotchPanelController {
    /// The grab area around the handle at the bottom of the open panel.
    static let handleSize = CGSize(width: 90, height: 24)

    private let state: PanelState
    private var tearPanel: NotchPanel?
    private var gamePanel: NotchPanel?
    /// The notch on the built-in screen, if there is one.
    private var notch: NotchGeometry?
    /// The notch (real, or a virtual one on screens without a notch) the open game panel hangs from.
    private var anchor: NotchGeometry?
    private var tracker = PullTracker()
    private var wasOpenBeforeDrag = false
    /// Drives the panel's body height so it trails the pointer, overshoots when it opens and springs back shut.
    private var heightSpring = Spring(stiffness: 260, dampingRatio: 0.55)
    private var lastSpringTime: TimeInterval?
    private var pointerLoop: Task<Void, Never>?
    private var screenObserver: Task<Void, Never>?

    /// Width of the virtual neck on Macs without a notch.
    private static let virtualNeckWidth: CGFloat = 190
    private static let tearPanelHeight: CGFloat = 60
    /// The drop has to be at least this long before it can be grabbed.
    private static let minGrabLength: CGFloat = 10
    private static let fastPoll = Duration.milliseconds(16)
    private static let slowPoll = Duration.milliseconds(100)

    init(state: PanelState) {
        self.state = state
    }

    func start() {
        placeTear()
        screenObserver = Task { [weak self] in
            let changes = NotificationCenter.default.notifications(
                named: NSApplication.didChangeScreenParametersNotification
            )
            for await _ in changes {
                self?.placeTear()
            }
        }
        pointerLoop = Task { [weak self] in
            while !Task.isCancelled {
                guard let interval = self?.pollPointer() else { return }
                try? await Task.sleep(for: interval)
            }
        }
    }

    /// "Play Pong" from the menu bar: works with or without a notch, opens straight to the largest size.
    func playFromMenu() {
        guard state.phase == .closed else { return }
        guard let geometry = notch ?? virtualGeometry() else { return }
        anchor = geometry
        wasOpenBeforeDrag = false
        showGamePanel()
        settle(.open(PullSizing.bodySize(forPull: PullSizing.maxBodyHeight)))
    }

    func updatePull(_ pull: CGFloat) {
        if state.phase != .dragging {
            wasOpenBeforeDrag = state.phase == .open
            if state.phase == .closed { anchor = notch }
        }
        guard anchor != nil else { return }
        state.phase = .dragging
        state.tear = TearPose(length: 0, offsetX: 0)
        state.bodySize = PullSizing.bodySize(forPull: pull)
        // Stiff and well damped: trails the pointer slightly without wobbling.
        heightSpring.stiffness = 900
        heightSpring.dampingRatio = 0.85
        heightSpring.target = PullSizing.rubberBandedHeight(forPull: pull)
        showGamePanel()
    }

    func endPull(pull: CGFloat, upwardVelocity: CGFloat) {
        guard anchor != nil, state.phase != .closed else { return }
        settle(PullSizing.releaseOutcome(pull: pull, upwardVelocity: upwardVelocity))
    }

    // MARK: - Pointer

    /// Reads the pointer once, updates the drop and any pull, and returns how long to wait before the next read.
    private func pollPointer() -> Duration {
        guard let geometry = anchor ?? notch else { return .milliseconds(250) }
        let location = NSEvent.mouseLocation
        let sample = PointerSample(
            location: location,
            time: ProcessInfo.processInfo.systemUptime,
            isPressed: NSEvent.pressedMouseButtons & 1 != 0
        )
        let notchBottom = CGPoint(x: geometry.notchRect.midX, y: geometry.notchRect.minY)

        if state.phase == .closed, notch != nil {
            state.tear = Magnet.tear(
                pointer: location,
                notchBottomCenter: notchBottom,
                maxShift: geometry.notchRect.width / 2 - TearShape.topWidth / 2
            )
        }

        let zone = grabZone(in: geometry)
        // Only catch clicks while the pointer is on the drop, so the drop never blocks the app underneath.
        tearPanel?.ignoresMouseEvents = !(state.phase == .closed && zone?.contains(location) == true)

        let action = tracker.handle(
            sample,
            grabZone: zone,
            startPull: state.phase == .open ? state.bodySize.height : 0,
            anchorY: geometry.notchRect.minY - NotchShape.neckSlack
        )
        switch action {
        case .none: break
        case .pull(let pull): updatePull(pull)
        case .release(let pull, let velocity): endPull(pull: pull, upwardVelocity: velocity)
        }
        advanceSpring(now: sample.time)

        let isActive = state.phase != .closed || state.tear.length > 0 || sample.isPressed || !heightSpring.isSettled
        return isActive ? Self.fastPoll : Self.slowPoll
    }

    /// Where pressing starts a pull: the notch and the drop while closed, the handle while open.
    private func grabZone(in geometry: NotchGeometry) -> CGRect? {
        switch state.phase {
        case .closed:
            guard notch != nil, state.tear.length >= Self.minGrabLength else { return nil }
            let tearRect = CGRect(
                x: geometry.notchRect.midX + state.tear.offsetX - 24,
                y: geometry.notchRect.minY - state.tear.length - 8,
                width: 48,
                height: state.tear.length + 8
            )
            return tearRect.union(geometry.notchRect)
        case .open:
            guard let frame = gamePanel?.frame else { return nil }
            return CGRect(
                x: frame.midX - Self.handleSize.width / 2,
                y: frame.minY,
                width: Self.handleSize.width,
                height: Self.handleSize.height
            )
        case .dragging:
            return nil
        }
    }

    // MARK: - Placement

    private func notchedScreenGeometry() -> NotchGeometry? {
        NSScreen.screens.lazy.compactMap(NotchGeometry.forScreen).first
    }

    private func virtualGeometry() -> NotchGeometry? {
        guard let screen = NSScreen.main else { return nil }
        let menuBarHeight = screen.frame.maxY - screen.visibleFrame.maxY
        let rect = CGRect(
            x: screen.frame.midX - Self.virtualNeckWidth / 2,
            y: screen.frame.maxY - menuBarHeight,
            width: Self.virtualNeckWidth,
            height: menuBarHeight
        )
        return NotchGeometry(notchRect: rect, menuBarHeight: menuBarHeight)
    }

    private func placeTear() {
        if state.phase != .closed { closeImmediately() }
        notch = notchedScreenGeometry()
        guard let notch else {
            tearPanel?.orderOut(nil)
            return
        }
        let panel = tearPanel ?? makeTearPanel()
        panel.setFrame(
            CGRect(
                x: notch.notchRect.minX,
                y: notch.notchRect.minY - Self.tearPanelHeight,
                width: notch.notchRect.width,
                height: Self.tearPanelHeight
            ),
            display: true
        )
        panel.orderFrontRegardless()
    }

    private func makeTearPanel() -> NotchPanel {
        let panel = NotchPanel(contentRect: .zero)
        panel.ignoresMouseEvents = true
        panel.contentView = NSHostingView(rootView: TearView(state: state))
        tearPanel = panel
        return panel
    }

    private func makeGamePanel() -> NotchPanel {
        let panel = NotchPanel(contentRect: .zero)
        let view = GamePanelView(state: state) { [weak self] in
            self?.endPull(pull: 0, upwardVelocity: 0)
        }
        let hostingView = FirstMouseHostingView(rootView: view)
        // The controller sets the frame; don't let SwiftUI's ideal size fight it.
        hostingView.sizingOptions = []
        panel.contentView = hostingView
        gamePanel = panel
        return panel
    }

    private func frame(forBodyHeight bodyHeight: CGFloat, in geometry: NotchGeometry) -> CGRect {
        let bodyHeight = max(bodyHeight, 0)
        let width = max(bodyHeight * PullSizing.aspect, geometry.notchRect.width)
        let height = geometry.menuBarHeight + NotchShape.neckSlack + bodyHeight
        return CGRect(
            x: geometry.notchRect.midX - width / 2,
            y: geometry.notchRect.maxY - height,
            width: width,
            height: height
        )
    }

    // MARK: - Showing and hiding

    private func showGamePanel() {
        guard let anchor else { return }
        state.neckWidth = anchor.notchRect.width
        state.neckHeight = anchor.menuBarHeight + NotchShape.neckSlack
        let panel = gamePanel ?? makeGamePanel()
        guard !panel.isVisible else { return }
        panel.setFrame(frame(forBodyHeight: heightSpring.value, in: anchor), display: true)
        panel.orderFrontRegardless()
    }

    private func settle(_ outcome: ReleaseOutcome) {
        guard let panel = gamePanel else { return }
        switch outcome {
        case .open(let size):
            if !wasOpenBeforeDrag { state.startNewMatch() }
            state.bodySize = size
            state.phase = .open
            // Loose enough to overshoot and bounce once before settling.
            heightSpring.stiffness = 260
            heightSpring.dampingRatio = 0.55
            heightSpring.target = size.height
            panel.makeKey()
        case .close:
            state.phase = .closed
            heightSpring.stiffness = 320
            heightSpring.dampingRatio = 0.8
            heightSpring.target = 0
        }
    }

    /// Steps the spring and resizes the panel; hides the panel once it has sprung shut.
    private func advanceSpring(now: TimeInterval) {
        guard let anchor, let panel = gamePanel, panel.isVisible else {
            lastSpringTime = nil
            return
        }
        let elapsed = lastSpringTime.map { min(now - $0, 0.05) } ?? 0
        lastSpringTime = now
        heightSpring.step(by: elapsed)
        panel.setFrame(frame(forBodyHeight: heightSpring.value, in: anchor), display: true)
        if state.phase == .closed, heightSpring.value < 1 { finishClosing() }
    }

    private func closeImmediately() {
        state.phase = .closed
        finishClosing()
    }

    private func finishClosing() {
        // A new pull may have started during the close animation.
        guard state.phase == .closed else { return }
        state.bodySize = .zero
        heightSpring.value = 0
        heightSpring.velocity = 0
        heightSpring.target = 0
        anchor = nil
        gamePanel?.orderOut(nil)
    }
}
