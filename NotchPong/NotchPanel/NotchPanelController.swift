//
//  NotchPanelController.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import AppKit
import SwiftUI

/// Owns the invisible trigger over the notch and the game panel that grows out of it.
final class NotchPanelController {
    private let state: PanelState
    private var triggerPanel: NotchPanel?
    private var gamePanel: NotchPanel?
    /// The notch (real, or a virtual one on screens without a notch) the game panel hangs from.
    private var anchor: NotchGeometry?
    private var wasOpenBeforeDrag = false
    private var screenObserver: Task<Void, Never>?

    /// Width of the virtual neck on Macs without a notch.
    private static let virtualNeckWidth: CGFloat = 190
    private static let snapDuration: TimeInterval = 0.2

    init(state: PanelState) {
        self.state = state
    }

    func start() {
        placeTrigger()
        screenObserver = Task { [weak self] in
            let changes = NotificationCenter.default.notifications(
                named: NSApplication.didChangeScreenParametersNotification
            )
            for await _ in changes {
                self?.placeTrigger()
            }
        }
    }

    /// "Play Pong" from the menu bar: works with or without a notch, opens straight to the largest size.
    func playFromMenu() {
        guard state.phase == .closed else { return }
        guard let geometry = notchedScreenGeometry() ?? virtualGeometry() else { return }
        anchor = geometry
        wasOpenBeforeDrag = false
        showGamePanel(bodySize: .zero)
        settle(.open(PullSizing.bodySize(forPull: PullSizing.maxBodyHeight)))
    }

    func updatePull(_ pull: CGFloat) {
        if state.phase != .dragging {
            wasOpenBeforeDrag = state.phase == .open
            if state.phase == .closed { anchor = notchedScreenGeometry() }
        }
        guard anchor != nil else { return }
        state.phase = .dragging
        let size = PullSizing.bodySize(forPull: pull)
        state.bodySize = size
        showGamePanel(bodySize: size)
    }

    func endPull(pull: CGFloat, upwardVelocity: CGFloat) {
        guard anchor != nil, state.phase != .closed else { return }
        settle(PullSizing.releaseOutcome(pull: pull, upwardVelocity: upwardVelocity))
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

    private func placeTrigger() {
        if state.phase != .closed { closeImmediately() }
        guard let geometry = notchedScreenGeometry() else {
            triggerPanel?.orderOut(nil)
            return
        }
        let panel = triggerPanel ?? makeTriggerPanel()
        panel.setFrame(geometry.notchRect, display: true)
        panel.orderFrontRegardless()
    }

    private func makeTriggerPanel() -> NotchPanel {
        let panel = NotchPanel(contentRect: .zero)
        let view = TriggerView(
            onPull: { [weak self] in self?.updatePull($0) },
            onRelease: { [weak self] in self?.endPull(pull: $0, upwardVelocity: $1) }
        )
        panel.contentView = FirstMouseHostingView(rootView: view)
        triggerPanel = panel
        return panel
    }

    private func makeGamePanel() -> NotchPanel {
        let panel = NotchPanel(contentRect: .zero)
        let view = GamePanelView(
            state: state,
            onPull: { [weak self] in self?.updatePull($0) },
            onRelease: { [weak self] in self?.endPull(pull: $0, upwardVelocity: $1) }
        )
        let hostingView = FirstMouseHostingView(rootView: view)
        // The controller sets the frame; don't let SwiftUI's ideal size fight it.
        hostingView.sizingOptions = []
        panel.contentView = hostingView
        gamePanel = panel
        return panel
    }

    private func frame(for bodySize: CGSize, in geometry: NotchGeometry) -> CGRect {
        let width = max(bodySize.width, geometry.notchRect.width)
        let height = geometry.menuBarHeight + bodySize.height
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
        state.neckHeight = anchor.menuBarHeight
        let panel = gamePanel ?? makeGamePanel()
        panel.setFrame(frame(for: bodySize, in: anchor), display: true)
        if !panel.isVisible {
            panel.orderFrontRegardless()
            triggerPanel?.orderOut(nil)
        }
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
        gamePanel?.orderOut(nil)
        if let geometry = notchedScreenGeometry() {
            triggerPanel?.setFrame(geometry.notchRect, display: true)
            triggerPanel?.orderFrontRegardless()
        }
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
