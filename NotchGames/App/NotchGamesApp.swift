//
//  NotchGamesApp.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

@main
struct NotchGamesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("notchgames", systemImage: "arcade.stick.console.fill") {
            Button("play") { appDelegate.controller?.playFromMenu() }
            SettingsMenuButton()
            Divider()
            Button("quit notchgames") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }

        Settings {
            SettingsView()
                .environment(appDelegate.panelState)
        }
        // The window takes its size limits from the content, so it grows and shrinks with it.
        .windowResizability(.contentSize)
    }
}
