//
//  GamePanelView.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// The drop hanging from the notch, which grows into the neon panel with a handle to push it back up.
struct GamePanelView: View {
    let state: PanelState
    let onClose: () -> Void

    var body: some View {
        let length = state.hangingLength
        let shape = RoundedRectangle(cornerRadius: DropGeometry.cornerRadius, style: .continuous)
        // Neon and controls fade in as the drip turns into the panel.
        let solidity = DropGeometry.solidity(forLength: length)

        VStack(spacing: 0) {
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
        .frame(width: DropGeometry.width(forLength: length), height: length)
        .background(shape.fill(Palette.background))
        .overlay {
            // Inner glow fading out toward the top, so the edge against the notch stays dark.
            Group {
                shape.stroke(Palette.paddle.opacity(0.6), lineWidth: 3).blur(radius: 4)
                shape.stroke(Palette.paddle.opacity(0.33), lineWidth: 1)
            }
            .mask(LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.1)))
            .opacity(solidity)
        }
        .clipShape(shape)
        .offset(x: DropGeometry.offset(forLength: length, dropOffset: state.dropOffset))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
