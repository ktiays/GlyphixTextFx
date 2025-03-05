//
//  Created by ktiays on 2024/11/16.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import Foundation
import GlyphixHook
import GlyphixTypesetter
import With

public typealias TextAlignment = GlyphixTypesetter.TextAlignment

/// A view with smooth per-character animation, like `UILabel`.
@MainActor
open class GlyphixTextLabel: PlatformView {

    /// The text that the label displays.
    ///
    /// This property is animatable.
    public var text: String? {
        set {
            textLayer.text = newValue
            _invalidateIntrinsicContentSize()
        }
        get { textLayer.text }
    }

    /// The font of the text.
    ///
    /// The default value for this property is the system font at a size of 17 points.
    public var font: PlatformFont? {
        set {
            textLayer.font = newValue
            _invalidateIntrinsicContentSize()
        }
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
    /// The default value for this property is `left`.
    public var textAlignment: TextAlignment {
        set { textLayer.alignment = newValue }
        get { textLayer.alignment }
    }

    /// The technique for wrapping and truncating the label's text.
    public var lineBreakMode: NSLineBreakMode {
        set { textLayer.lineBreakMode = newValue }
        get { textLayer.lineBreakMode }
    }

    /// The maximum number of lines for rendering text.
    ///
    /// This property controls the maximum number of lines to use in order to fit the label's text into
    /// its bounding rectangle. The default value for this property is `1`. To remove any maximum limit,
    /// and use as many lines as needed, set the value of this property to `0`.
    public var numberOfLines: Int {
        set {
            textLayer.numberOfLines = newValue
            _invalidateIntrinsicContentSize()
        }
        get { textLayer.numberOfLines }
    }

    /// A Boolean value that indicates whether views should disable animations.
    public var disablesAnimations: Bool {
        set { textLayer.disablesAnimations = newValue }
        get { textLayer.disablesAnimations }
    }

    /// The preferred maximum width, in points, for a multiline label.
    public var preferredMaxLayoutWidth: CGFloat = 0 {
        didSet {
            _invalidateIntrinsicContentSize()
            #if os(iOS)
            let needsDoubleUpdateConstraintsPass = self.gtf_invokeSuper(forSelectorReturnsBoolean: "_needsDoubleUpdateConstraintsPass")
            self.gtf_invokeSuper(
                for: "_needsDoubleUpdateConstraintsPassMayHaveChangedFrom:",
                withBooleanArgReturnsBoolean: needsDoubleUpdateConstraintsPass
            )
            #endif
        }
    }
    private var _preferredMaxLayoutWidth: CGFloat = 0
    private var needsDoubleUpdateConstraintsPass: Bool {
        numberOfLines != 1
    }

    /// A Boolean value that specifies whether to enable font smoothing.
    ///
    /// The default value for this property is `false`.
    public var isSmoothRenderingEnabled: Bool {
        set { textLayer.isSmoothRenderingEnabled = newValue }
        get { textLayer.isSmoothRenderingEnabled }
    }

    private var textLayer: GlyphixTextLayer {
        layer as! GlyphixTextLayer
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)

        #if os(iOS)
        configureAutoLayoutMethods()
        #elseif os(macOS)
        wantsLayer = true
        #endif
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        #if os(iOS)
        configureAutoLayoutMethods()
        #elseif os(macOS)
        wantsLayer = true
        #endif
    }

    override public var intrinsicContentSize: CGSize {
        let layoutWidth = min(_preferredMaxLayoutWidth, preferredMaxLayoutWidth == 0 ? .greatestFiniteMagnitude : preferredMaxLayoutWidth)
        let frame = frame(
            forAlignmentRect: .init(
                x: 0,
                y: 0,
                width: layoutWidth == 0 ? CGFloat.greatestFiniteMagnitude : layoutWidth,
                height: .greatestFiniteMagnitude
            )
        )
        return ceil(textLayer.size(fitting: frame.size))
    }

    private func _invalidateIntrinsicContentSize() {
        _preferredMaxLayoutWidth = .greatestFiniteMagnitude
        invalidateIntrinsicContentSize()
    }

    #if os(iOS)
    override public class var layerClass: AnyClass {
        GlyphixTextLayer.self
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        textLayer.effectiveAppearanceDidChange(traitCollection)
    }

    override open func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)

        if let newSuperview {
            textLayer.effectiveAppearanceDidChange(newSuperview.traitCollection)
        }
    }

    open override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow != nil {
            textLayer.displaySyncObserver = try? .init()
        } else {
            try? textLayer.displaySyncObserver?.invalidate()
            textLayer.displaySyncObserver = nil
        }
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        ceil(textLayer.size(fitting: size))
    }

    private func configureAutoLayoutMethods() {
        with("_prepareForFirstIntrinsicContentSizeCalculation") { sel in
            self.gtf_addInstanceMethod(sel) { this in
                guard let textLabel = this as? GlyphixTextLabel else {
                    return
                }
                textLabel._preferredMaxLayoutWidth = .greatestFiniteMagnitude
                textLabel.gtf_invokeSuper(for: sel)
            }
        }
        with("_prepareForSecondIntrinsicContentSizeCalculationWithLayoutEngineBounds:") { sel in
            self.gtf_addInstanceMethod(sel) { this, bounds in
                guard let textLabel = this as? GlyphixTextLabel else {
                    return
                }
                let frame = textLabel.alignmentRect(forFrame: bounds)
                textLabel._preferredMaxLayoutWidth = frame.width
                textLabel.gtf_invokeSuper(for: sel, with: bounds)
            }
        }
        with("_needsDoubleUpdateConstraintsPass") { sel in
            self.gtf_addInstanceMethod(sel) { this in
                guard let textLabel = this as? GlyphixTextLabel else {
                    return false
                }

                return textLabel.needsDoubleUpdateConstraintsPass
            }
        }
        with("_preferredMaxLayoutWidth") { sel in
            self.gtf_addInstanceMethod(sel) { this in
                guard let textLabel = this as? GlyphixTextLabel else {
                    return 0
                }

                return textLabel._preferredMaxLayoutWidth
            }
        }
    }
    #elseif os(macOS)
    override public var isFlipped: Bool { true }

    private var finishedFirstConstraintsPass: Bool = false

    override public func makeBackingLayer() -> CALayer {
        GlyphixTextLayer()
    }

    override public func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()

        textLayer.effectiveAppearanceDidChange(effectiveAppearance)
    }

    override open func viewWillMove(toSuperview newSuperview: NSView?) {
        super.viewWillMove(toSuperview: newSuperview)

        if let newSuperview {
            textLayer.effectiveAppearanceDidChange(newSuperview.effectiveAppearance)
        }
    }

    override open func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        if let newWindow, let screen = newWindow.screen {
            textLayer.displaySyncObserver = try? .init(screen: screen)
        } else {
            try? textLayer.displaySyncObserver?.invalidate()
            textLayer.displaySyncObserver = nil
        }
    }

    override open func updateConstraints() {
        defer { super.updateConstraints() }
        if !needsDoubleUpdateConstraintsPass {
            return
        }
        if !finishedFirstConstraintsPass {
            DispatchQueue.main.async { [weak self] in
                self?.needsUpdateConstraints = true
            }
            finishedFirstConstraintsPass = true
            _preferredMaxLayoutWidth = .greatestFiniteMagnitude
            return
        }

        guard let engine = self.perform("_layoutEngine").takeUnretainedValue() as? NSObject else {
            return
        }
        engine.perform("optimize")
        guard let imp = self.gtf_getImplementation(for: "nsis_frame") else {
            return
        }
        let fn = unsafeBitCast(imp, to: (@convention(c) (AnyObject, Selector?) -> CGRect).self)
        let frame = fn(self, nil)
        _preferredMaxLayoutWidth = frame.width
        invalidateIntrinsicContentSize()
        finishedFirstConstraintsPass = false
    }

    /// Asks the label to calculate and return the size that best fits the specified size.
    open func sizeThatFits(_ size: CGSize) -> CGSize {
        ceil(textLayer.size(fitting: size))
    }
    #endif
}
