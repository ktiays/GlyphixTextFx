//
//  Created by ktiays on 2025/2/24.
//  Copyright (c) 2025 ktiays. All rights reserved.
//

import SwiftUI

/// A view that displays one or more lines of read-only text with built-in glyph-level animations.
@MainActor
public struct GlyphixText {

    public var text: String
    public var font: PlatformFont
    public var textColor: PlatformColor

    /// Creates a text view that displays a stored string without localization.
    public init<S>(_ text: S) where S: StringProtocol {
        self.init(text: .init(text))
    }
    
    /// Creates a text view that displays a localized string resource.
    @available(iOS 16.0, macOS 13.0, *)
    public init(_ resource: LocalizedStringResource) {
        self.init(text: .init(localized: resource))
    }

    private init(
        text: String,
        font: PlatformFont = .glyphixDefaultFont,
        textColor: PlatformColor = .glyphixDefaultColor
    ) {
        self.text = text
        self.font = font
        self.textColor = textColor
    }

    /// Sets the font for text in the view.
    public func font(_ font: PlatformFont) -> GlyphixText {
        var copy = self
        copy.font = font
        return copy
    }

    /// Sets the color of the text displayed by this view.
    public func textColor(_ color: PlatformColor) -> GlyphixText {
        var copy = self
        copy.textColor = color
        return copy
    }

    private func updateView(_ view: GlyphixTextLabel) {
        view.font = font
        view.text = text
        view.textColor = textColor
    }

    @available(iOS 16.0, macOS 13.0, *)
    private func sizeThatFits(_ proposal: ProposedViewSize, view: GlyphixTextLabel) -> CGSize {
        switch proposal {
        case .zero:
            return .zero
        case .infinity, .unspecified:
            return view.sizeThatFits(
                .init(
                    width: CGFloat.greatestFiniteMagnitude,
                    height: CGFloat.greatestFiniteMagnitude
                )
            )
        default:
            var size = proposal.replacingUnspecifiedDimensions(by: .greatestFiniteMagnitude)
            if size.width == 0 {
                size.width = CGFloat.greatestFiniteMagnitude
            }
            if size.height == 0 {
                size.height = CGFloat.greatestFiniteMagnitude
            }
            let result = view.sizeThatFits(size)
            return result
        }
    }
}

#if os(iOS)
import UIKit

extension GlyphixText: UIViewRepresentable {

    public func makeUIView(context: Context) -> GlyphixTextLabel {
        .init()
    }

    public func updateUIView(_ uiView: GlyphixTextLabel, context _: Context) {
        updateView(uiView)
    }

    @available(iOS 16.0, *)
    public func sizeThatFits(_ proposal: ProposedViewSize, uiView: GlyphixTextLabel, context: Context) -> CGSize? {
        sizeThatFits(proposal, view: uiView)
    }
}
#elseif os(macOS)
import AppKit

extension GlyphixText: NSViewRepresentable {

    public func makeNSView(context: Context) -> GlyphixTextLabel {
        .init()
    }

    public func updateNSView(_ nsView: GlyphixTextLabel, context: Context) {
        updateView(nsView)
    }

    @available(macOS 13.0, *)
    public func sizeThatFits(_ proposal: ProposedViewSize, nsView: GlyphixTextLabel, context: Context) -> CGSize? {
        sizeThatFits(proposal, view: nsView)
    }
}
#endif
