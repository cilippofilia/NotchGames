//
//  TriggerView.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// Invisible strip over the notch. Dragging down from it pulls the game panel out.
struct TriggerView: View {
    let onPull: (CGFloat) -> Void
    let onRelease: (_ pull: CGFloat, _ upwardVelocity: CGFloat) -> Void

    var body: some View {
        Color.clear
            .contentShape(.rect)
            .gesture(
                DragGesture(minimumDistance: 2, coordinateSpace: .global)
                    .onChanged { onPull($0.translation.height) }
                    .onEnded { onRelease($0.translation.height, -$0.velocity.height) }
            )
            .accessibilityLabel("Pull down to play Pong")
    }
}
