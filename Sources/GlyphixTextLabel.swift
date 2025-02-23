//
//  Created by ktiays on 2024/11/16.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import Foundation

@MainActor
open class GlyphixTextLabel: PlatformView {

    public typealias TextAlignment = GlyphixTextLayer.TextAlignment

    #if os(macOS)
    override public var isFlipped: Bool { true }
    #endif

    public var text: String {
        set { textLayer.text = newValue }
        get { textLayer.text }
    }

    public var textColor: PlatformColor {
        set { textLayer.textColor = newValue }
        get { textLayer.textColor }
    }

    public var countsDown: Bool {
        set { textLayer.countsDown = newValue }
        get { textLayer.countsDown }
    }

    public var textAlignment: TextAlignment {
        set { textLayer.alignment = newValue }
        get { textLayer.alignment }
    }

    override public var intrinsicContentSize: CGSize {
        textLayer.textBounds.size
    }

    private var textLayer: GlyphixTextLayer {
        layer as! GlyphixTextLayer
    }

    public init(font: PlatformFont = .preferredFont(forTextStyle: .body)) {
        super.init(frame: .zero)
        commonInit(font: font)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit(font: PlatformFont = .preferredFont(forTextStyle: .body)) {
        #if os(macOS)
        self.wantsLayer = true
        #endif

        textLayer.font = font
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
