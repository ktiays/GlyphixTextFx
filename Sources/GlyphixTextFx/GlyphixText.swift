//
//  Created by ktiays on 2025/2/24.
//  Copyright (c) 2025 ktiays. All rights reserved.
//

import SwiftUI

public struct GlyphixText {

    public let font: PlatformFont
    public var text: String
    public var textColor: PlatformColor = .numericLabelColor

    public init(text: String, font: PlatformFont = .preferredFont(forTextStyle: .body)) {
        self.text = text
        self.font = font
    }

    @MainActor public func createView() -> GlyphixTextLabel {
        .init()
    }

    @MainActor public func updatePropertys(forView label: GlyphixTextLabel) {
        label.text = text
        label.textColor = textColor
    }
}

#if os(iOS)
import UIKit

extension GlyphixText: UIViewRepresentable {

    public func makeUIView(context: Context) -> GlyphixTextLabel {
        createView()
    }

    public func updateUIView(_ uiView: GlyphixTextLabel, context _: Context) {
        updatePropertys(forView: uiView)
    }

    @available(iOS 16.0, *)
    public func sizeThatFits(_ proposal: ProposedViewSize, uiView: GlyphixTextLabel, context: Context) -> CGSize? {
        uiView.intrinsicContentSize
    }
}
#elseif os(macOS)
import AppKit

extension GlyphixText: NSViewRepresentable {

    public func makeNSView(context: Context) -> GlyphixTextLabel {
        createView()
    }

    public func updateNSView(_ nsView: GlyphixTextLabel, context: Context) {
        updatePropertys(forView: nsView)
    }

    @available(macOS 13.0, *)
    public func sizeThatFits(_ proposal: ProposedViewSize, nsView: GlyphixTextLabel, context: Context) -> CGSize? {
        nsView.intrinsicContentSize
    }
}
#endif
