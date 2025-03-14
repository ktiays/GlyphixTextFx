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
    public var countsDown: Bool

    private var font: PlatformFont?
    private var textColor: PlatformColor?
    private var lineBreakMode: NSLineBreakMode?
    private var alignment: TextAlignment?
    private var lineLimit: Int?
    private var isBlurEffectEnabled: Bool?
    private var isAnimationDisabled: Bool?

    @Environment(\.glyphixTextFont) private var environmentFont
    @Environment(\.glyphixTextColor) private var environmentTextColor
    @Environment(\.truncationMode) private var environmentTruncationMode
    @Environment(\.multilineTextAlignment) private var environmentTextAlignment
    @Environment(\.lineLimit) private var environmentLineLimit
    @Environment(\.blursDuringTransition) private var environmentBlursDuringTransition
    @Environment(\.disablesGlyphixTextAnimations) private var environmentDisablesAnimations

    /// Creates a text view that displays a stored string without localization.
    public init<S>(_ text: S, countsDown: Bool = false) where S: StringProtocol {
        self.init(text: .init(text), countsDown: countsDown)
    }

    /// Creates a text view that displays a localized string resource.
    @available(iOS 16.0, macOS 13.0, *)
    public init(_ resource: LocalizedStringResource, countsDown: Bool = false) {
        self.init(text: .init(localized: resource), countsDown: true)
    }

    private init(text: String, countsDown: Bool) {
        self.text = text
        self.countsDown = countsDown
    }

    private func updateView(_ view: GlyphixTextLabel) {
        view.text = text
        view.font = font ?? (environmentFont ?? .glyphixDefaultFont)
        view.textColor = textColor ?? (environmentTextColor ?? .glyphixDefaultColor)
        view.countsDown = countsDown
        view.numberOfLines = lineLimit ?? (environmentLineLimit ?? 0)
        view.textAlignment =
            if let alignment {
                alignment
            } else {
                textAlignment(from: environmentTextAlignment)
            }
        view.lineBreakMode =
            if let lineBreakMode {
                lineBreakMode
            } else {
                lineBreakMode(from: environmentTruncationMode)
            }
        view.disablesAnimations = isAnimationDisabled ?? environmentDisablesAnimations
        view.isBlurEffectEnabled = isBlurEffectEnabled ?? environmentBlursDuringTransition
    }

    private func textAlignment(from alignment: SwiftUI.TextAlignment) -> TextAlignment {
        switch alignment {
        case .leading:
            .leading
        case .center:
            .center
        case .trailing:
            .trailing
        }
    }

    private func lineBreakMode(from truncationMode: Text.TruncationMode) -> NSLineBreakMode {
        switch truncationMode {
        case .head:
            .byTruncatingHead
        case .middle:
            .byTruncatingMiddle
        case .tail:
            .byTruncatingTail
        @unknown default:
            .byWordWrapping
        }
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

    public func updateUIView(_ uiView: GlyphixTextLabel, context: Context) {
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

extension GlyphixText {

    /// Sets the font for text in the view.
    @available(*, deprecated, renamed: "glyphixTextFont")
    public func font(_ font: PlatformFont) -> Self {
        glyphixTextFont(font)
    }

    /// Sets the font for text in the view.
    public func glyphixTextFont(_ font: PlatformFont) -> Self {
        var view = self
        view.font = font
        return view
    }

    /// Sets the technique for aligning the text.
    @available(*, deprecated, message: "Use `View.multilineTextAlignment(_:)` instead.")
    public func textAlignment(_ alignment: TextAlignment) -> Self {
        var view = self
        view.alignment = alignment
        return view
    }

    /// Sets the alignment of a text view that contains multiple lines of text.
    public func multilineTextAlignment(_ alignment: SwiftUI.TextAlignment) -> Self {
        var view = self
        view.alignment = textAlignment(from: alignment)
        return view
    }

    /// Sets the maximum number of lines that text can occupy in this view.
    public func lineLimit(_ limit: Int?) -> Self {
        var view = self
        view.lineLimit = limit
        return view
    }

    /// Sets the color of the text displayed by this view.
    @available(*, deprecated, renamed: "glyphixTextColor")
    public func textColor(_ color: PlatformColor) -> Self {
        glyphixTextColor(color)
    }

    /// Sets the color of the text displayed by this view.
    public func glyphixTextColor(_ color: PlatformColor) -> Self {
        var view = self
        view.textColor = color
        return view
    }

    /// Sets the direction of the text animation.
    @available(*, deprecated, message: "Use `GlyphixText(_:countsDown:)` instead.")
    public func countsDown(_ countsDown: Bool = false) -> Self {
        var view = self
        view.countsDown = countsDown
        return view
    }

    /// Sets the technique for wrapping and truncating the label's text.
    @available(*, deprecated, renamed: "truncationMode")
    public func lineBreakMode(_ mode: NSLineBreakMode) -> Self {
        var view = self
        view.lineBreakMode = mode
        return view
    }

    /// Sets the truncation mode for lines of text that are too long to fit in the available space.
    public func truncationMode(_ mode: Text.TruncationMode) -> Self {
        var view = self
        view.lineBreakMode = lineBreakMode(from: mode)
        return view
    }

    /// Sets whether label should disable animations.
    @available(*, deprecated, renamed: "glyphixTextAnimationDisabled")
    public func disablesAnimations(_ disables: Bool = true) -> Self {
        glyphixTextAnimationDisabled(disables)
    }

    /// Sets whether label should disable animations.
    public func glyphixTextAnimationDisabled(_ disables: Bool = true) -> Self {
        var view = self
        view.isAnimationDisabled = disables
        return view
    }

    /// Sets whether label should disable blur effect.
    @available(*, deprecated, renamed: "glyphixTextBlurEffectDisabled")
    public func disablesBlurEffect(_ disables: Bool = true) -> Self {
        glyphixTextBlurEffectDisabled(disables)
    }

    /// Sets whether label should disable blur effect.
    public func glyphixTextBlurEffectDisabled(_ disables: Bool = true) -> Self {
        var view = self
        view.isBlurEffectEnabled = disables
        return view
    }
}
