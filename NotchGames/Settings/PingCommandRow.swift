//
//  PingCommandRow.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/21/26.
//

import AppKit
import SwiftUI

/// For agents without one-click setup: copies the ping command to paste into their hook or script.
struct PingCommandRow: View {
    private static let command = "open -g notchgames://attention"
    @State private var copied = false

    var body: some View {
        LabeledContent {
            Button(copied ? "copied" : "copy", systemImage: copied ? "checkmark" : "doc.on.doc") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(Self.command, forType: .string)
                copied = true
            }
        } label: {
            Text("any other agent")
            Text("run \(Text(Self.command).monospaced()) from its hook or script")
        }
    }
}
