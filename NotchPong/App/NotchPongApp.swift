//
//  NotchPongApp.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

@main
struct NotchPongApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("notchpong", systemImage: "arcade.stick.console.fill") {
            Button("play") { appDelegate.controller?.playFromMenu() }
            SettingsMenuButton()
            Divider()
            Button("quit notchpong") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }

        Settings {
            SettingsView()
        }
        // The window takes its size limits from the content, so it grows and shrinks with it.
        .windowResizability(.contentSize)
    }
}
