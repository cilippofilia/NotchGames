//
//  Palette.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// The neon look from the design: pure black panel to match the notch, blue player, amber computer,
/// pink ball, teal court details.
enum Palette {
    static let background = Color.black
    static let paddle = Color(red: 77 / 255, green: 252 / 255, blue: 196 / 255)
    /// The player's paddle and mallet; teal stays for the court's decoration.
    static let player = Color(red: 64 / 255, green: 156 / 255, blue: 255 / 255)
    /// The computer's paddle and mallet: warm against the player's blue, and clear of the pink ball.
    static let opponent = Color(red: 255 / 255, green: 159 / 255, blue: 28 / 255)
    static let ball = Color(red: 255 / 255, green: 79 / 255, blue: 163 / 255)
    /// Bonus balls and the multi-ball capsule.
    static let extraBall = Color(red: 255 / 255, green: 226 / 255, blue: 64 / 255)
    /// The slowdown capsule.
    static let slowdown = Color(red: 90 / 255, green: 170 / 255, blue: 255 / 255)
    static let neonText = Color(red: 57 / 255, green: 255 / 255, blue: 90 / 255)
    static let bug = Color(red: 255 / 255, green: 85 / 255, blue: 51 / 255)
    static let bugEyes = Color(red: 255 / 255, green: 236 / 255, blue: 224 / 255)
}
