//
//  GamePanelView.swift
//  NotchGames
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
        let shape = DropShape(length: length, notchWidth: notchWidth, dropOffset: dropOffset, shape: state.shape)
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
            GameView(state: state)
                .opacity(solidity)
        }
        .frame(
            width: DropGeometry.frameWidth(
                forLength: length, notchWidth: notchWidth, dropOffset: dropOffset, shape: state.shape
            ),
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

#Preview {
    let state = {
        let state = PanelState()
        state.phase = .open
        state.hangingLength = 300
        state.notchWidth = 200
        state.hasNotch = true
        return state
    }()
    GamePanelView(state: state, onClose: {})
        .frame(width: 560, height: 340)
        .background(.gray)
}
