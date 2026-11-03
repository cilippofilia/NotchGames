//
//  LoginItem.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/2/26.
//

import Foundation
import ServiceManagement

/// Starting the app when the user logs in, through the sandbox-friendly login item API.
enum LoginItem {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Returns false if macOS refused, so the toggle can show the real state.
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            return false
        }
    }
}
