//
//  StatsStore.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import Foundation
import Observation

/// Keeps the player's record between launches, in user defaults.
@MainActor
@Observable
final class StatsStore {
    static let shared = StatsStore(defaults: .standard)

    private(set) var stats: PlayerStats
    @ObservationIgnored private let defaults: UserDefaults
    private static let key = "stats"

    init(defaults: UserDefaults) {
        self.defaults = defaults
        stats = defaults.data(forKey: Self.key)
            .flatMap { try? JSONDecoder().decode(PlayerStats.self, from: $0) } ?? PlayerStats()
    }

    func record(winner: PongSide) {
        stats.record(winner: winner)
        save()
    }

    func reset() {
        stats = PlayerStats()
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(stats) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
