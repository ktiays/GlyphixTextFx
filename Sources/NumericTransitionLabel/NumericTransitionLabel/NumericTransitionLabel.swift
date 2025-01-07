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

    public init(font: PlatformFont = .preferredFont(forTextStyle: .body)) {
        super.init(frame: .zero)
        commonInit(font: font)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit(font: PlatformFont = .preferredFont(forTextStyle: .body)) {
        let wantsLayerSelector = NSSelectorFromString("setWantsLayer:")
        if responds(to: wantsLayerSelector) {
            perform(wantsLayerSelector, with: true)
        }

        textLayer.font = font
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
