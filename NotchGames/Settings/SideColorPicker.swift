//
//  SideColorPicker.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/21/26.
//

import SwiftUI

/// A row of color swatches for one side; picking the other side's color swaps the two.
/// Shared by the title screen and Settings.
struct SideColorPicker: View {
    let title: LocalizedStringKey
    @Binding var selection: SideColor
    @Binding var other: SideColor

    var body: some View {
        LabeledContent(title) {
            HStack {
                ForEach(SideColor.allCases) { side in
                    Button(side.title) {
                        (selection, other) = SideColor.choosing(side, mine: selection, theirs: other)
                    }
                    .buttonStyle(SwatchStyle(color: side.color, isSelected: side == selection))
                    .accessibilityLabel(side.title)
                    .accessibilityAddTraits(side == selection ? .isSelected : [])
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }
}

/// A colored dot, ringed when picked; the picker gives each swatch its name for VoiceOver.
private struct SwatchStyle: ButtonStyle {
    let color: Color
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        Circle()
            .fill(color)
            .frame(width: 14, height: 14)
            .padding(3)
            .overlay {
                Circle().stroke(isSelected ? Color.primary : .clear, lineWidth: 1.5)
            }
            .opacity(configuration.isPressed ? 0.6 : 1)
            .contentShape(.circle)
    }
}

#Preview {
    @Previewable @State var player = SideColor.blue
    @Previewable @State var computer = SideColor.amber
    VStack {
        SideColorPicker(title: "you", selection: $player, other: $computer)
        SideColorPicker(title: "computer", selection: $computer, other: $player)
    }
    .padding()
}
