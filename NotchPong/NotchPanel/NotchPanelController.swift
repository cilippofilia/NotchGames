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
    private var pointerLoop: Task<Void, Never>?
    private var screenObserver: Task<Void, Never>?

    /// Width of the virtual neck on Macs without a notch.
    private static let virtualNeckWidth: CGFloat = 190
    private static let snapDuration: TimeInterval = 0.2
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
        showGamePanel(bodySize: .zero)
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
        let size = PullSizing.bodySize(forPull: pull)
        state.bodySize = size
        showGamePanel(bodySize: size)
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
            state.tear = Magnet.tear(pointer: location, notchBottomCenter: notchBottom)
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

        let isActive = state.phase != .closed || state.tear.length > 0 || sample.isPressed
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

    private func frame(for bodySize: CGSize, in geometry: NotchGeometry) -> CGRect {
        let width = max(bodySize.width, geometry.notchRect.width)
        let height = geometry.menuBarHeight + NotchShape.neckSlack + bodySize.height
        return CGRect(
            x: geometry.notchRect.midX - width / 2,
            y: geometry.notchRect.maxY - height,
            width: width,
            height: height
        )
    }

    // MARK: - Showing and hiding

    private func showGamePanel(bodySize: CGSize) {
        guard let anchor else { return }
        state.neckWidth = anchor.notchRect.width
        state.neckHeight = anchor.menuBarHeight + NotchShape.neckSlack
        let panel = gamePanel ?? makeGamePanel()
        panel.setFrame(frame(for: bodySize, in: anchor), display: true)
        if !panel.isVisible { panel.orderFrontRegardless() }
    }

    private func settle(_ outcome: ReleaseOutcome) {
        guard let anchor, let panel = gamePanel else { return }
        switch outcome {
        case .open(let size):
            if !wasOpenBeforeDrag { state.startNewMatch() }
            state.bodySize = size
            state.phase = .open
            animate(panel, to: frame(for: size, in: anchor)) {}
            panel.makeKey()
        case .close:
            state.phase = .closed
            animate(panel, to: frame(for: .zero, in: anchor)) { [weak self] in
                self?.finishClosing()
            }
        }
    }

    private func closeImmediately() {
        state.phase = .closed
        finishClosing()
    }

    private func finishClosing() {
        // A new pull may have started during the close animation.
        guard state.phase == .closed else { return }
        state.bodySize = .zero
        anchor = nil
        gamePanel?.orderOut(nil)
    }

    private func animate(_ panel: NSPanel, to frame: CGRect, completion: @escaping @MainActor () -> Void) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.snapDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(frame, display: true)
        } completionHandler: {
            Task { @MainActor in completion() }
        }
    }
}
