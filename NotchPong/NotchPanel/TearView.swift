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
        TearShape(pose: state.tear)
            .fill(.black)
            .animation(.interpolatingSpring(stiffness: 300, damping: 18), value: state.tear)
            .accessibilityHidden(true)
    }
}
