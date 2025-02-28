//
//  Created by ktiays on 2024/11/16.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import Foundation

/// A view with smooth per-character animation, like `UILabel`.
@MainActor
open class GlyphixTextLabel: PlatformView {

    public typealias TextAlignment = GlyphixTextLayer.TextAlignment

    /// The text that the label displays.
    ///
    /// This property is animatable.
    public var text: String? {
        set { textLayer.text = newValue }
        get { textLayer.text }
    }

    /// The font of the text.
    ///
    /// The default value for this property is the system font at a size of 17 points.
    public var font: PlatformFont? {
        set { textLayer.font = newValue }
        get { textLayer.font }
    }

    /// The color of the text.
    ///
    /// The default value for this property is the system's label color.
    /// This property is animatable.
    public var textColor: PlatformColor {
        set { textLayer.textColor = newValue }
        get { textLayer.textColor }
    }

    public var countsDown: Bool {
        set { textLayer.countsDown = newValue }
        get { textLayer.countsDown }
    }

    /// The technique for aligning the text.
    ///
    /// The default value of this property is `center`.
    public var textAlignment: TextAlignment {
        set { textLayer.alignment = newValue }
        get { textLayer.alignment }
    }
    
    /// The maximum number of lines for rendering text.
    ///
    /// This property controls the maximum number of lines to use in order to fit the label's text into
    /// its bounding rectangle. The default value for this property is `1`. To remove any maximum limit,
    /// and use as many lines as needed, set the value of this property to `0`.
    public var numberOfLines: Int {
        set { textLayer.numberOfLines = newValue }
        get { textLayer.numberOfLines }
    }
    
    /// A Boolean value that indicates whether views should disable animations.
    public var disablesAnimations: Bool {
        set { textLayer.disablesAnimations = newValue }
        get { textLayer.disablesAnimations }
    }
    
    /// The preferred maximum width, in points, for a multiline label.
    public var preferredMaxLayoutWidth: CGFloat {
        set { textLayer.preferredMaxLayoutWidth = newValue }
        get { textLayer.preferredMaxLayoutWidth }
    }
    
    /// A Boolean value that specifies whether to enable font smoothing.
    public var isSmoothRenderingEnabled: Bool {
        set { textLayer.isSmoothRenderingEnabled = newValue }
        get { textLayer.isSmoothRenderingEnabled }
    }

//    override public var intrinsicContentSize: CGSize {
//        textLayer.textBounds.size
//    }

    private var textLayer: GlyphixTextLayer {
        layer as! GlyphixTextLayer
    }

    #if os(iOS)
    override public class var layerClass: AnyClass {
        GlyphixTextLayer.self
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        textLayer.effectiveAppearanceDidChange(traitCollection)
    }

    open override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)

        if let newSuperview {
            textLayer.effectiveAppearanceDidChange(newSuperview.traitCollection)
        }
    }
    #elseif os(macOS)
    override public var isFlipped: Bool { true }

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        wantsLayer = true
    }

    override public func makeBackingLayer() -> CALayer {
        GlyphixTextLayer()
    }

    override public func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()

        textLayer.effectiveAppearanceDidChange(effectiveAppearance)
    }

    open override func viewWillMove(toSuperview newSuperview: NSView?) {
        super.viewWillMove(toSuperview: newSuperview)

        if let newSuperview {
            textLayer.effectiveAppearanceDidChange(newSuperview.effectiveAppearance)
        }
    }
    #endif
}
