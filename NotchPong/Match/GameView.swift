//
//  GameView.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// Shows whichever game is picked in Settings.
struct GameView: View {
    let state: PanelState

    @AppStorage(GameKind.storageKey) private var game = GameKind.standard

    var body: some View {
        Group {
            switch game {
            case .pong: PongView(state: state)
            case .airHockey: AirHockeyView(state: state)
            case .brickBreaker: Text("brick breaker")
            }
        }
        // The panel takes the game's shape; the controller resizes an open panel to match.
        .onChange(of: game, initial: true) {
            state.aspect = game.panelAspect
        }
    }
}

#Preview {
    GameView(state: PanelState())
        .frame(width: 480, height: 300)
        .background(Palette.background)
}
