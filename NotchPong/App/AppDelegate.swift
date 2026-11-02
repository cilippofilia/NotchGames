//
//  AppDelegate.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    let panelState = PanelState()
    private(set) var controller: NotchPanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = NotchPanelController(state: panelState)
        controller.start()
        self.controller = controller
    }
}
