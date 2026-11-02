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
        switch game {
        case .pong: PongView(state: state)
        case .airHockey: AirHockeyView(state: state)
        }
    }
}
