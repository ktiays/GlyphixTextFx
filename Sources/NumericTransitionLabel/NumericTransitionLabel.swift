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
public class NumericTransitionLabel: PlatformView {

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

    public override func makeBackingLayer() -> CALayer {
        NumericTransitionTextLayer()
    }

    public override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()

        self.textLayer.effectiveAppearanceDidChange(self.effectiveAppearance)
    }
    #else
    
    private var traitChangeRegistrations: [any UITraitChangeRegistration] = []
    
    deinit {
        Task { @MainActor in
            for registration in traitChangeRegistrations {
                unregisterForTraitChanges(registration)
            }
        }
    }
    
    public override class var layerClass: AnyClass {
        NumericTransitionTextLayer.self
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        let registration = registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: Self, previousTraitCollection) in
            view.textLayer.effectiveAppearanceDidChange(view.traitCollection)
        }
        traitChangeRegistrations.append(registration)
    }
    #endif
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override var intrinsicContentSize: CGSize {
        textLayer.textBounds.size
    }
}
