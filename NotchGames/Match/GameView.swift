//
//  GameView.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// Shows whichever game is picked in Settings, after the title screen on a fresh install.
struct GameView: View {
    let state: PanelState

    @AppStorage(GameKind.storageKey) private var game = GameKind.standard
    @AppStorage(TitleView.seenKey) private var hasSeenTitle = false

    var body: some View {
        Group {
            if !hasSeenTitle {
                TitleView()
            } else {
                switch game {
                case .pong: PongView(state: state)
                case .airHockey: AirHockeyView(state: state)
                case .brickBreaker: BrickBreakerView(state: state)
                case .snake: SnakeView(state: state)
                case .runner: RunnerView(state: state)
                case .shootingGallery: GalleryView(state: state)
                }
            }
        }
        // The panel takes the game's shape, or the title's; the controller resizes an open panel to match.
        .onChange(of: hasSeenTitle ? game.panelShape : .title, initial: true) { _, shape in
            state.shape = shape
        }
    }
}

#Preview {
    GameView(state: PanelState())
        .frame(width: 480, height: 300)
        .background(Palette.background)
}
