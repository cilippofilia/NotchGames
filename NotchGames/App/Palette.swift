//
//  Palette.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// The neon look from the design: pure black panel to match the notch, teal paddles, pink ball.
enum Palette {
    static let background = Color.black
    static let paddle = Color(red: 77 / 255, green: 252 / 255, blue: 196 / 255)
    static let ball = Color(red: 255 / 255, green: 79 / 255, blue: 163 / 255)
    static let neonText = Color(red: 57 / 255, green: 255 / 255, blue: 90 / 255)
    static let bug = Color(red: 255 / 255, green: 85 / 255, blue: 51 / 255)
    static let bugEyes = Color(red: 255 / 255, green: 236 / 255, blue: 224 / 255)
}
