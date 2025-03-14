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
    
    @Environment(\.glyphixTextFont) private var font
    @Environment(\.glyphixTextColor) private var textColor
    @Environment(\.truncationMode) private var truncationMode
    @Environment(\.multilineTextAlignment) private var textAlignment
    @Environment(\.lineLimit) private var lineLimit
    @Environment(\.blursDuringTransition) private var isBlurEffectEnabled
    @Environment(\.disablesGlyphixTextAnimations) private var disablesAnimations
    
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
        view.font = font ?? .glyphixDefaultFont
        view.textColor = textColor ?? .glyphixDefaultColor
        view.countsDown = countsDown
        view.numberOfLines = lineLimit ?? 1
        view.textAlignment = switch textAlignment {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
        view.lineBreakMode = switch truncationMode {
        case .head: .byTruncatingHead
        case .middle: .byTruncatingMiddle
        case .tail: .byTruncatingTail
        @unknown default: .byWordWrapping
        }
        view.disablesAnimations = disablesAnimations
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

// MARK: - Deprecated

extension GlyphixText {
    /// Sets the font for text in the view.
    @available(*, deprecated, renamed: "glyphixTextFont")
    public func font(_ font: PlatformFont) -> GlyphixText {
        self
    }
    
    /// Sets the technique for aligning the text.
    @available(*, deprecated, message: "Use `View.multilineTextAlignment(_:)` instead.")
    public func textAlignment(_ alignment: TextAlignment) -> GlyphixText {
        self
    }
    
    /// Sets the maximum number of lines that text can occupy in this view.
    @available(*, deprecated, message: "Use `View.lineLimit(_:)` instead.")
    public func lineLimit(_ limit: Int) -> GlyphixText {
        self
    }
    
    /// Sets the color of the text displayed by this view.
    @available(*, deprecated, renamed: "glyphixTextColor")
    public func textColor(_ color: PlatformColor) -> GlyphixText {
        self
    }
    
    /// Sets the direction of the text animation.
    @available(*, deprecated, message: "Use `GlyphixText(_:countsDown:)` instead.")
    public func countsDown(_ countsDown: Bool = false) -> Self {
        self
    }
    
    /// Sets the technique for wrapping and truncating the label's text.
    @available(*, deprecated, renamed: "truncationMode")
    public func lineBreakMode(_ mode: NSLineBreakMode) -> Self {
        self
    }
    
    /// Sets whether label should disable animations.
    @available(*, deprecated, renamed: "glyphixTextAnimationDisabled")
    public func disablesAnimations(_ disables: Bool) -> Self {
        self
    }
    
    /// Sets whether label should disable blur effect.
    @available(*, deprecated, renamed: "glyphixTextBlurEffectDisabled")
    public func disablesBlurEffect(_ disables: Bool) -> Self {
        self
    }
}
