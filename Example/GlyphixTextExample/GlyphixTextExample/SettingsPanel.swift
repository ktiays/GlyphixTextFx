//
//  Created by ktiays on 2025/3/7.
//  Copyright (c) 2025 ktiays. All rights reserved.
//

import GlyphixTextFx
import SwiftUI

final class LabelConfiguration: ObservableObject {

    @Published var fontSize: Int = 36
    @Published var textColor: UIColor = .label
    @Published var numberOfLines: Int = 1
    @Published var countsDown: Bool = false
    @Published var alignment: GlyphixTextFx.TextAlignment = .leading
    @Published var lineBreakMode: NSLineBreakMode = .byTruncatingTail

    @Published var isAnimationEnabled: Bool = true
    @Published var isBlurEffectEnabled: Bool = true
    @Published var isSmoothRenderingEnabled: Bool = false
}

extension GlyphixTextFx.TextAlignment: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .center:
            "Center"
        case .leading:
            "Leading"
        case .trailing:
            "Trailing"
        }
    }
}

extension NSLineBreakMode: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .byWordWrapping:
            ".byWordWrapping"
        case .byCharWrapping:
            ".byCharWrapping"
        case .byClipping:
            ".byClipping"
        case .byTruncatingHead:
            ".byTruncatingHead"
        case .byTruncatingTail:
            ".byTruncatingTail"
        case .byTruncatingMiddle:
            ".byTruncatingMiddle"
        @unknown default:
            fatalError()
        }
    }
}

struct SettingsPanel: View {

    @StateObject var configuration: LabelConfiguration
    
    private let textColors: [UIColor] = [
        .label,
        .systemRed,
        .systemOrange,
        .systemYellow,
        .systemGreen,
        .systemBlue,
        .systemCyan,
        .systemPurple,
    ]

    var body: some View {
        List {
            Section {
                Stepper(value: $configuration.fontSize, in: 12...48) {
                    HStack {
                        Text("Font Size")
                        Spacer()
                        Text("\(configuration.fontSize)")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("Text Color")
                        .padding(.horizontal, 20)
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 14) {
                            Color.clear
                                .frame(width: 10, height: 30)
                            ForEach(textColors, id: \.self) { color in
                                let isSelected = color == configuration.textColor
                                Button {
                                    withAnimation(.spring(duration: 0.24)) {
                                        configuration.textColor = color
                                    }
                                } label: {
                                    Circle()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(Color(color))
                                        .overlay {
                                            if isSelected {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(color == .label ? Color(UIColor.systemBackground) : .white)
                                                    .clipShape(Circle())
                                                    .transition(.scale)
                                            }
                                        }
                                }
                            }
                            Color.clear
                                .frame(width: 10, height: 30)
                        }
                    }
                }
                .listRowInsets(.init())
                .padding(.vertical, 12)

                Stepper(value: $configuration.numberOfLines, in: 0...50) {
                    let numberOfLines = configuration.numberOfLines
                    if numberOfLines > 0 {
                        HStack {
                            Text("Max Lines")
                            Spacer()
                            Text("\(numberOfLines)")
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Unlimited Lines")
                    }
                }
                HStack {
                    Text("Transition Direction")
                    Spacer()
                    Menu {
                        Button("Upward") {
                            configuration.countsDown = false
                        }
                        Button("Downward") {
                            configuration.countsDown = true
                        }
                    } label: {
                        Text(configuration.countsDown ? "Downward" : "Upward")
                    }
                }
                HStack {
                    Text("Text Alignment")
                    Spacer()
                    Menu {
                        ForEach(GlyphixTextFx.TextAlignment.allCases, id: \.self) { alignment in
                            Button(alignment.description) {
                                configuration.alignment = alignment
                            }
                        }
                    } label: {
                        Text(configuration.alignment.description)
                    }
                }
                HStack {
                    Text("Line Break Mode")
                    Spacer()
                    Menu {
                        Button("Word Wrap") {
                            configuration.lineBreakMode = .byWordWrapping
                        }
                        Button("Character Wrap") {
                            configuration.lineBreakMode = .byCharWrapping
                        }
                        Button("Clipping") {
                            configuration.lineBreakMode = .byClipping
                        }
                        Button("Truncate Head") {
                            configuration.lineBreakMode = .byTruncatingHead
                        }
                        Button("Truncate Middle") {
                            configuration.lineBreakMode = .byTruncatingMiddle
                        }
                        Button("Truncate Tail") {
                            configuration.lineBreakMode = .byTruncatingTail
                        }
                    } label: {
                        Text(configuration.lineBreakMode.description)
                    }
                }
            } header: {
                Text("General")
            }
            Section {
                Toggle("Blur", isOn: $configuration.isBlurEffectEnabled)
                Toggle("Animations", isOn: $configuration.isAnimationEnabled)
                Toggle("Smooth Rendering", isOn: $configuration.isSmoothRenderingEnabled)
            } header: {
                Text("Effects")
            }
        }
    }
}

#Preview {
    SettingsPanel(configuration: .init())
}
