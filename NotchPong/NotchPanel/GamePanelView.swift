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
    let onClose: () -> Void

    var body: some View {
        let shape = LiquidShape(
            length: state.hangingLength,
            dropOffset: state.dropOffset,
            notchWidth: state.neckWidth,
            neckHeight: state.neckHeight
        )
        var outline = shape
        outline.isOutline = true
        // Neon and controls fade in as the drip turns into the panel.
        let solidity = LiquidProfile.make(
            length: state.hangingLength,
            notchWidth: state.neckWidth,
            dropOffset: state.dropOffset
        ).solidity

        return VStack(spacing: 0) {
            Color.clear
                .frame(height: state.neckHeight + LiquidProfile.slack)

            Color.clear

            Capsule()
                .fill(Palette.paddle.opacity(0.4))
                .frame(width: 30, height: 4)
                .frame(width: NotchPanelController.handleSize.width, height: NotchPanelController.handleSize.height)
                .opacity(solidity)
                .accessibilityLabel("Close")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { onClose() }
        }
        .background(shape.fill(Palette.background))
        .overlay {
            // Inner glow along the edge; the window is exactly the panel's size, so an outer glow would be clipped.
            Group {
                outline.stroke(Palette.paddle.opacity(0.6), lineWidth: 3).blur(radius: 4)
                outline.stroke(Palette.paddle.opacity(0.33), lineWidth: 1)
            }
            .opacity(solidity)
        }
        .clipShape(shape)
    }
}
