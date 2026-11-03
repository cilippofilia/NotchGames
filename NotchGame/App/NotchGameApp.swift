//
//  NotchGameApp.swift
//  NotchGame
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

@main
struct NotchGameApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("notchgame", systemImage: "arcade.stick.console.fill") {
            Button("play") { appDelegate.controller?.playFromMenu() }
            SettingsMenuButton()
            Divider()
            Button("quit notchgame") { NSApplication.shared.terminate(nil) }
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
