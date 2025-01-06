//
//  Created by ktiays on 2024/11/16.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import Foundation

@MainActor
open class NumericTransitionLabel: PlatformView {
    public typealias TextAlignment = NumericTransitionTextLayer.TextAlignment

    #if canImport(UIKit)
    #else
        #if canImport(AppKit)
            override public var isFlipped: Bool { true }
        #endif
    #endif

    public var text: String {
        set { textLayer.text = newValue }
        get { textLayer.text }
    }

    public var font: PlatformFont {
        set { textLayer.font = newValue }
        get { textLayer.font }
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

    private var textLayer: NumericTransitionTextLayer {
        layer as! NumericTransitionTextLayer
    }

    public init() {
        super.init(frame: .zero)

        let wantsLayerSelector = NSSelectorFromString("setWantsLayer:")
        if responds(to: wantsLayerSelector) {
            perform(wantsLayerSelector, with: true)
        }

        text = ""
        textColor = .numericLabelColor
        font = .preferredFont(forTextStyle: .body)

        textLayer.updateText()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError()
    }

    #if canImport(UIKit)

        override public class var layerClass: AnyClass {
            NumericTransitionTextLayer.self
        }

        override open func traitCollectionDidChange(_: UITraitCollection?) {
            textLayer.effectiveAppearanceDidChange(traitCollection)
        }
    #else

        #if canImport(AppKit)
            override public func makeBackingLayer() -> CALayer {
                NumericTransitionTextLayer()
            }

            override public func viewDidChangeEffectiveAppearance() {
                super.viewDidChangeEffectiveAppearance()

                textLayer.effectiveAppearanceDidChange(effectiveAppearance)
            }
        #endif
    #endif
}
