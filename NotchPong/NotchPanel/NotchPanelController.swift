//
//  NotchPanelController.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import AppKit
import SwiftUI

/// Owns the overlay under the notch, where the drop hangs and grows into the game panel.
///
/// The overlay is one fixed, transparent window; SwiftUI draws the drop inside it, so nothing is resized per frame.
/// Every display frame the pointer is read with `NSEvent.mouseLocation` and `NSEvent.pressedMouseButtons`
/// (no permissions, sandbox-safe) and a spring moves the drop. The frame rate drops to 10 Hz while idle.
final class NotchPanelController: NSObject {
    /// The grab area around the handle at the bottom of the open panel.
    static let handleSize = CGSize(width: 90, height: 24)

    private let state: PanelState
    private var overlay: NotchPanel?
    private var displayLink: CADisplayLink?
    /// The notch on the built-in screen, if there is one.
    private var notch: NotchGeometry?
    /// The notch (real, or a virtual one on screens without a notch) the overlay hangs from.
    private var anchor: NotchGeometry?
    private var tracker = PullTracker()
    private var wasOpenBeforeDrag = false
    /// How far the drop hangs below the notch.
    private var spring = Spring(stiffness: 400, dampingRatio: 0.45)
    private var lastStepTime: CFTimeInterval?
    private var isActive = false
    private var screenObserver: Task<Void, Never>?

    /// Width of the virtual neck on Macs without a notch.
    private static let virtualNeckWidth: CGFloat = 190
    /// The drop has to be at least this long before it can be grabbed.
    private static let minGrabLength: CGFloat = 10
    /// Tall enough for the panel at full stretch plus spring overshoot.
    private static let overlayHeight: CGFloat = (PullSizing.maxBodyHeight + PullSizing.maxStretch) * 1.2

    init(state: PanelState) {
        self.state = state
    }

    func start() {
        place(under: notchedScreenGeometry())
        screenObserver = Task { [weak self] in
            let changes = NotificationCenter.default.notifications(
                named: NSApplication.didChangeScreenParametersNotification
            )
            for await _ in changes {
                guard let self else { return }
                self.resetToClosed()
                self.place(under: self.notchedScreenGeometry())
            }
        }
    }

    /// "Play Pong" from the menu bar: works with or without a notch, opens straight to the largest size.
    func playFromMenu() {
        guard state.phase == .closed else { return }
        if notch == nil { place(under: virtualGeometry()) }
        guard anchor != nil else { return }
        wasOpenBeforeDrag = false
        state.startNewMatch()
        settle(.open(PullSizing.bodySize(forPull: PullSizing.maxBodyHeight)))
    }

    func close() {
        guard state.phase == .open else { return }
        settle(.close)
    }

    // MARK: - Every frame

    @objc private func step(_ link: CADisplayLink) {
        guard let anchor else { return }
        let elapsed = lastStepTime.map { min(link.timestamp - $0, 0.05) } ?? 0
        lastStepTime = link.timestamp
        let location = NSEvent.mouseLocation
        let sample = PointerSample(
            location: location,
            time: link.timestamp,
            isPressed: NSEvent.pressedMouseButtons & 1 != 0
        )

        if state.phase == .closed {
            let tear = notch == nil ? TearPose(length: 0, offsetX: 0) : Magnet.tear(
                pointer: location,
                notchBottomCenter: CGPoint(x: anchor.notchRect.midX, y: anchor.notchRect.minY),
                maxShift: Magnet.maxShift(notchWidth: anchor.notchRect.width)
            )
            if state.tear != tear { state.tear = tear }
            spring.target = tear.length
            // Once it has sprung back to drip size, let it wobble like a drop again.
            if spring.value < Magnet.maxLength * 1.5 {
                spring.stiffness = 400
                spring.dampingRatio = 0.45
                if state.dropOffset != tear.offsetX { state.dropOffset = tear.offsetX }
            }
        }

        let action = tracker.handle(
            sample,
            grabZone: grabZone(in: anchor),
            startPull: state.phase == .open ? state.bodySize.height : spring.value,
            // Opening from the notch grows faster than the pointer; resizing by the handle stays under it.
            gain: state.phase == .open ? 1 : PullSizing.openingGain,
            anchorY: anchor.notchRect.minY
        )
        switch action {
        case .none: break
        case .pull(let pull): updatePull(pull)
        case .release(let pull, let velocity):
            settle(PullSizing.releaseOutcome(pull: pull, upwardVelocity: velocity))
        }

        spring.step(by: elapsed)
        // Observation fires on every write, so only write real changes to avoid redrawing every frame.
        let length = max(spring.value, 0)
        if state.hangingLength != length { state.hangingLength = length }
        updatePanelPointer(location, in: anchor)

        // Catch clicks only on the drop itself, so the overlay never blocks the apps underneath.
        let ignoresMouse = !OverlayHitTest.catchesClicks(
            at: location,
            phase: state.phase,
            dropRect: dropRect(in: anchor),
            grabZone: grabZone(in: anchor)
        )
        if overlay?.ignoresMouseEvents != ignoresMouse { overlay?.ignoresMouseEvents = ignoresMouse }
        setActive(state.phase != .closed || state.tear.length > 0 || !spring.isSettled || sample.isPressed)
    }

    /// Tells the game where the pointer is inside the open panel, in panel points from its top-left.
    private func updatePanelPointer(_ location: CGPoint, in geometry: NotchGeometry) {
        let pointer = state.phase == .open ? PanelPointer.position(of: location, in: dropRect(in: geometry)) : nil
        if state.panelPointer != pointer { state.panelPointer = pointer }
    }

    private func updatePull(_ pull: CGFloat) {
        if state.phase != .dragging { wasOpenBeforeDrag = state.phase == .open }
        // Reset the game as the pull begins, so the last match never shows while the panel grows.
        if state.phase == .closed { state.startNewMatch() }
        state.phase = .dragging
        state.bodySize = PullSizing.bodySize(forPull: pull)
        // Soft enough to lag and stretch behind the pointer like liquid, damped enough not to wobble.
        spring.stiffness = 500
        spring.dampingRatio = 0.75
        spring.target = PullSizing.rubberBandedHeight(forPull: pull)
    }

    private func settle(_ outcome: ReleaseOutcome) {
        switch outcome {
        case .open(let size):
            state.bodySize = size
            state.phase = .open
            // Loose enough to overshoot and wobble like a drop before settling.
            spring.stiffness = 220
            spring.dampingRatio = 0.5
            spring.target = size.height
            overlay?.acceptsKeyboard = true
            overlay?.makeKey()
        case .close:
            state.phase = .closed
            state.bodySize = .zero
            // Hand the keyboard back, so typing after a game goes where the user expects.
            overlay?.acceptsKeyboard = false
            overlay?.resignKey()
            spring.stiffness = 300
            spring.dampingRatio = 0.75
        }
    }

    /// Drops any pull in progress and shuts the panel without animating, e.g. when the displays change.
    private func resetToClosed() {
        tracker = PullTracker()
        state.phase = .closed
        state.bodySize = .zero
        spring.value = 0
        spring.velocity = 0
        overlay?.acceptsKeyboard = false
        overlay?.resignKey()
    }

    // MARK: - Geometry

    /// The drop as currently drawn, in screen coordinates.
    private func dropRect(in geometry: NotchGeometry) -> CGRect {
        let length = state.hangingLength
        let width = DropGeometry.frameWidth(
            forLength: length,
            notchWidth: geometry.notchRect.width,
            dropOffset: state.dropOffset
        )
        let offset = DropGeometry.offset(forLength: length, dropOffset: state.dropOffset)
        return CGRect(
            x: geometry.notchRect.midX + offset - width / 2,
            y: geometry.notchRect.minY - length,
            width: width,
            height: length
        )
    }

    /// Where pressing starts a pull: the notch and the drop while closed, the handle while open.
    private func grabZone(in geometry: NotchGeometry) -> CGRect? {
        switch state.phase {
        case .closed:
            guard notch != nil, state.tear.length >= Self.minGrabLength else { return nil }
            return dropRect(in: geometry).insetBy(dx: -10, dy: -6).union(geometry.notchRect)
        case .open:
            let drop = dropRect(in: geometry)
            return CGRect(
                x: drop.midX - Self.handleSize.width / 2,
                y: drop.minY,
                width: Self.handleSize.width,
                height: Self.handleSize.height
            )
        case .dragging:
            return nil
        }
    }

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

    // MARK: - Overlay window

    /// Puts the overlay under `geometry`, or hides it when there's nothing to hang from.
    private func place(under geometry: NotchGeometry?) {
        notch = notchedScreenGeometry()
        anchor = geometry
        guard let geometry else {
            overlay?.orderOut(nil)
            displayLink?.isPaused = true
            return
        }
        state.notchWidth = geometry.notchRect.width
        state.hasNotch = notch != nil
        let panel = overlay ?? makeOverlay()
        let width = DropGeometry.width(forLength: Self.overlayHeight)
        panel.setFrame(
            CGRect(
                x: geometry.notchRect.midX - width / 2,
                y: geometry.notchRect.minY - Self.overlayHeight,
                width: width,
                height: Self.overlayHeight + DropGeometry.notchCapHeight
            ),
            display: true
        )
        panel.orderFrontRegardless()
        displayLink?.isPaused = false
    }

    private func makeOverlay() -> NotchPanel {
        let panel = NotchPanel(contentRect: .zero)
        panel.ignoresMouseEvents = true
        let hostingView = FirstMouseHostingView(rootView: GamePanelView(state: state) { [weak self] in
            self?.close()
        })
        hostingView.sizingOptions = []
        panel.contentView = hostingView
        let link = hostingView.displayLink(target: self, selector: #selector(step(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
        overlay = panel
        setActive(false, force: true)
        return panel
    }

    /// Full frame rate while something is moving, a slow 10 Hz check otherwise.
    private func setActive(_ active: Bool, force: Bool = false) {
        guard active != isActive || force else { return }
        isActive = active
        displayLink?.preferredFrameRateRange = active
            ? CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
            : CAFrameRateRange(minimum: 10, maximum: 10, preferred: 10)
    }
}
