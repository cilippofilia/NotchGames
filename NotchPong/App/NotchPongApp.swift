import SwiftUI

@main
struct NotchPongApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("NotchPong", systemImage: "gamecontroller") {
            Button("Play Pong") {}
            Divider()
            Button("Quit NotchPong") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}
