//
//  AppDelegate.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/2/26.
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    let panelState = PanelState()
    private(set) var controller: NotchPanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Before the panel's views read their settings.
        Difficulty.copySharedChoice(in: .standard)
        let controller = NotchPanelController(state: panelState)
        controller.start()
        self.controller = controller
        // A fresh install opens the panel on its own, so the title screen shows where the games live.
        if !UserDefaults.standard.bool(forKey: TitleView.seenKey) { controller.playFromMenu() }
    }
}
