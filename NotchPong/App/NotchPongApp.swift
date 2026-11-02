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
        MenuBarExtra("NotchPong", systemImage: "gamecontroller") {
            Button("Play Pong") { appDelegate.controller?.playFromMenu() }
            Divider()
            Button("Quit NotchPong") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}
