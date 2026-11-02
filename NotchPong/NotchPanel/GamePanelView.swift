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
        let notchWidth = state.notchWidth
        let dropOffset = state.dropOffset
        let shape = DropShape(length: length, notchWidth: notchWidth, dropOffset: dropOffset)
        let attachWidth = DropGeometry.attachWidth(forLength: length, notchWidth: notchWidth, dropOffset: dropOffset)
        // Neon and controls fade in as the drip turns into the panel.
        let solidity = DropGeometry.solidity(forLength: length)

        VStack(spacing: 0) {
            Color.clear

            Capsule()
                .fill(Palette.paddle.opacity(0.4))
                .frame(width: 30, height: 4)
                .frame(width: NotchPanelController.handleSize.width, height: NotchPanelController.handleSize.height)
                .opacity(solidity)
                .accessibilityLabel("close")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { onClose() }
        }
        .background {
            PongView(state: state)
                .opacity(solidity)
        }
        .frame(
            width: DropGeometry.frameWidth(forLength: length, notchWidth: notchWidth, dropOffset: dropOffset),
            height: length
        )
        .background(shape.fill(Palette.background))
        .overlay {
            // Inner glow fading out toward the top, so the edge against the notch stays dark.
            Group {
                shape.stroke(Palette.paddle.opacity(0.6), lineWidth: 2).blur(radius: 1.5)
                shape.stroke(Palette.paddle.opacity(0.33), lineWidth: 1)
            }
            .mask(LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.1)))
            .opacity(solidity)
        }
        .clipShape(shape)
        .background {
            // The faint outline of the gutter, where the pointer can roam without pausing the game.
            UnevenRoundedRectangle(
                bottomLeadingRadius: DropGeometry.cornerRadius + PanelPointer.gutter,
                bottomTrailingRadius: DropGeometry.cornerRadius + PanelPointer.gutter,
                style: .continuous
            )
            .stroke(Palette.paddle.opacity(0.18), style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
            .background(
                UnevenRoundedRectangle(
                    bottomLeadingRadius: DropGeometry.cornerRadius + PanelPointer.gutter,
                    bottomTrailingRadius: DropGeometry.cornerRadius + PanelPointer.gutter,
                    style: .continuous
                )
                .fill(Palette.paddle.opacity(0.03))
            )
            .padding(.horizontal, -PanelPointer.gutter)
            .padding(.bottom, -PanelPointer.gutter)
            .opacity(solidity)
            .allowsHitTesting(false)
        }
        .padding(.top, DropGeometry.notchCapHeight)
        .background(alignment: .top) {
            if state.hasNotch, length > 0 {
                Rectangle()
                    .fill(Palette.background)
                    .frame(width: attachWidth, height: DropGeometry.notchCapHeight)
            }
        }
        .offset(x: DropGeometry.offset(forLength: length, dropOffset: dropOffset))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
