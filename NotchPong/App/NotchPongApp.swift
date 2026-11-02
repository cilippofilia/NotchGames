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
        MenuBarExtra("notchpong", systemImage: "gamecontroller") {
            Button("play") { appDelegate.controller?.playFromMenu() }
            SettingsMenuButton()
            Divider()
            Button("quit notchpong") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }

        Settings {
            SettingsView()
        }
    }
}
