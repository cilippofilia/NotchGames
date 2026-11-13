//
//  PanelShape.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

import CoreGraphics

/// How a game's panel is sized: its width : height, and the range of heights it opens at.
nonisolated struct PanelShape: Equatable {
    var aspect: CGFloat
    var maxHeight: CGFloat
    /// The shortest it opens; a smaller pull that still opens the panel opens it this tall.
    var minOpenHeight: CGFloat

    /// Pong and air hockey: wide, any size between the small and large settings.
    static let wide = PanelShape(
        aspect: 1.6,
        maxHeight: PullSizing.maxBodyHeight,
        minOpenHeight: PullSizing.minBodyHeight
    )
    /// Brick breaker: upright and always full size, so the wall has room to fall.
    static let tall = PanelShape(aspect: 0.8, maxHeight: 600, minOpenHeight: 600)
    /// The title screen: one fixed size, whichever game is picked and however far the panel is pulled.
    static let title = PanelShape(aspect: 1.6, maxHeight: 300, minOpenHeight: 300)

    func openHeight(for requested: CGFloat) -> CGFloat {
        min(max(requested, minOpenHeight), maxHeight)
    }
}
