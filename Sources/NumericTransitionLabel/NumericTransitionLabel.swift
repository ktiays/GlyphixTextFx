//
//  Created by ktiays on 2024/11/16.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

#if os(macOS)
import AppKit

public typealias PlatformView = NSView
#else
import UIKit

public typealias PlatformView = UIView
#endif

@MainActor
open class NumericTransitionLabel: PlatformView {

    public typealias TextAlignment = NumericTransitionTextLayer.TextAlignment

    #if os(macOS)
    public override var isFlipped: Bool { true }
    #endif

    public var text: String? {
        set { textLayer.text = newValue }
        get { textLayer.text }
    }
    public var font: PlatformFont? {
        set { textLayer.font = newValue }
        get { textLayer.font }
    }
    public var textColor: PlatformColor? {
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

    private var textLayer: NumericTransitionTextLayer {
        layer as! NumericTransitionTextLayer
    }

    #if os(macOS)
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        self.wantsLayer = true
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func makeBackingLayer() -> CALayer {
        NumericTransitionTextLayer()
    }

    public override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()

        self.textLayer.effectiveAppearanceDidChange(self.effectiveAppearance)
    }
    #else
    
    public override class var layerClass: AnyClass {
        NumericTransitionTextLayer.self
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        textLayer.effectiveAppearanceDidChange(self.traitCollection)
    }
    #endif
    
    public override var intrinsicContentSize: CGSize {
        textLayer.textBounds.size
    }
}
