//
//  TearView.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// The black drop under the notch that reaches toward the pointer.
struct TearView: View {
    let state: PanelState

    var body: some View {
        UnevenRoundedRectangle(
            bottomLeadingRadius: DropGeometry.cornerRadius,
            bottomTrailingRadius: DropGeometry.cornerRadius
        )
        .fill(Palette.background)
        .frame(width: DropGeometry.dripWidth, height: state.tear.length)
        .offset(x: state.tear.offsetX)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.interpolatingSpring(stiffness: 300, damping: 18), value: state.tear)
        .accessibilityHidden(true)
    }
}
