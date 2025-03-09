//
//  Created by ktiays on 2025/2/24.
//  Copyright (c) 2025 ktiays. All rights reserved.
//

import GlyphixTypesetter
import SwiftUI

/// A view that displays one or more lines of read-only text with built-in glyph-level animations.
@MainActor
public struct GlyphixText {

    public var text: String
    public var font: PlatformFont
    public var textColor: PlatformColor
    public var countsDown: Bool
    public var textAlignment: TextAlignment
    public var lineBreakMode: NSLineBreakMode
    public var lineLimit: Int
    public var isAnimationEnabled: Bool
    public var isBlurEffectEnabled: Bool

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
        textColor: PlatformColor = .glyphixDefaultColor,
        countsDown: Bool = false,
        textAlignment: TextAlignment = .leading,
        lineLimit: Int = 1,
        lineBreakMode: NSLineBreakMode = .byTruncatingTail,
        isAnimationEnabled: Bool = true,
        isBlurEffectEnabled: Bool = true
    ) {
        self.text = text
        self.font = font
        self.textColor = textColor
        self.countsDown = countsDown
        self.textAlignment = textAlignment
        self.lineLimit = lineLimit
        self.lineBreakMode = lineBreakMode
        self.isAnimationEnabled = isAnimationEnabled
        self.isBlurEffectEnabled = isBlurEffectEnabled
    }

    /// Sets the font for text in the view.
    public func font(_ font: PlatformFont) -> GlyphixText {
        var copy = self
        copy.font = font
        return copy
    }

    /// Sets the technique for aligning the text.
    public func textAlignment(_ alignment: TextAlignment) -> GlyphixText {
        var copy = self
        copy.textAlignment = alignment
        return copy
    }

    /// Sets the maximum number of lines that text can occupy in this view.
    public func lineLimit(_ limit: Int) -> GlyphixText {
        var copy = self
        copy.lineLimit = limit
        return copy
    }

    /// Sets the color of the text displayed by this view.
    public func textColor(_ color: PlatformColor) -> GlyphixText {
        var copy = self
        copy.textColor = color
        return copy
    }

    /// Sets the direction of the text animation.
    public func countsDown(_ countsDown: Bool = false) -> Self {
        var copy = self
        copy.countsDown = countsDown
        return copy
    }
    
    /// Sets the technique for wrapping and truncating the label's text.
    public func lineBreakMode(_ mode: NSLineBreakMode) -> Self {
        var copy = self
        copy.lineBreakMode = mode
        return copy
    }

    /// Sets whether label should disable animations.
    public func disablesAnimations(_ disables: Bool) -> Self {
        var copy = self
        copy.isAnimationEnabled = !disables
        return copy
    }

    /// Sets whether label should disable blur effect.
    public func disablesBlurEffect(_ disables: Bool) -> Self {
        var copy = self
        copy.isBlurEffectEnabled = !disables
        return copy
    }

    private func updateView(_ view: GlyphixTextLabel) {
        view.font = font
        view.text = text
        view.textColor = textColor
        view.countsDown = countsDown
        view.numberOfLines = lineLimit
        view.textAlignment = textAlignment
        view.disablesAnimations = !isAnimationEnabled
        view.isBlurEffectEnabled = isBlurEffectEnabled
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
