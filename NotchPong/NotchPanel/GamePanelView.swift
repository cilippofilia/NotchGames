//
//  GamePanelView.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// The neon panel: neck in the menu bar, court below, and a handle to push it back up.
struct GamePanelView: View {
    let state: PanelState
    let onPull: (CGFloat) -> Void
    let onRelease: (_ pull: CGFloat, _ upwardVelocity: CGFloat) -> Void

    /// Body height when the handle drag began; the panel resizes under the pointer, so measure from here.
    @State private var dragStartHeight: CGFloat?

    var body: some View {
        let shape = NotchShape(neckWidth: state.neckWidth, neckHeight: state.neckHeight)

        VStack(spacing: 0) {
            Color.clear
                .frame(height: state.neckHeight)

            Color.clear

            Capsule()
                .fill(Palette.paddle.opacity(0.4))
                .frame(width: 30, height: 4)
                .frame(width: 90, height: 18)
                .contentShape(.rect)
                .gesture(handleDrag)
                .accessibilityLabel("Close")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { onRelease(0, 0) }
        }
        .background(shape.fill(Palette.background))
        .overlay {
            // Inner glow along the edge; the window is exactly the panel's size, so an outer glow would be clipped.
            shape.stroke(Palette.paddle.opacity(0.6), lineWidth: 3).blur(radius: 4)
            shape.stroke(Palette.paddle.opacity(0.33), lineWidth: 1)
        }
        .clipShape(shape)
    }

    private var handleDrag: some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .onChanged { value in
                let start = dragStartHeight ?? state.bodySize.height
                dragStartHeight = start
                onPull(start + value.translation.height)
            }
            .onEnded { value in
                let start = dragStartHeight ?? state.bodySize.height
                dragStartHeight = nil
                onRelease(start + value.translation.height, -value.velocity.height)
            }
    }
}
