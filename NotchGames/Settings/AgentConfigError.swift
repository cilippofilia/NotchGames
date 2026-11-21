//
//  AgentConfigError.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/21/26.
//

import Foundation

/// Why an agent's config was left untouched.
nonisolated enum AgentConfigError: Error, Equatable {
    /// The file isn't a JSON object, so rewriting it could lose the user's settings.
    case notASettingsObject
    /// The file isn't UTF-8 text.
    case unreadable
    /// Codex runs a single `notify` command and it already runs someone else's.
    case notifySlotTaken
}
