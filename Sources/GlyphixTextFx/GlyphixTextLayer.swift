//
//  Created by ktiays on 2024/11/16.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import Choreographer
import GlyphixTypesetter
import Respring

#if os(iOS)
import UIKit
#else
import AppKit
#endif

open class GlyphixTextLayer: CALayer {

    /// The text that the label displays.
    public var text: String? {
        didSet {
            if text == attributedText?.string {
                return
            }
            setNeedsUpdateTextLayout()
        }
    }
    private var attributedText: NSAttributedString?

    public var font: PlatformFont? {
        didSet {
            if font == oldValue {
                return
            }
            setNeedsUpdateTextLayout()
        }
    }
    private let defaultFont: PlatformFont = .glyphixDefaultFont

    private var effectiveFont: PlatformFont {
        font ?? defaultFont
    }

    /// The color of the text.
    public var textColor: PlatformColor = .glyphixDefaultColor {
        didSet {
            if textColor == oldValue {
                return
            }
            colorAnimation.target = textColor.resolvedRgbColor(with: effectiveAppearance)
            if disablesAnimations {
                colorAnimation.velocity = .zero
                colorAnimation.value = colorAnimation.target
                for (layer, _) in layerStates {
                    updateLayerColor(layer)
                }
            }
        }
    }

    private lazy var colorAnimation: AnimationState<RGBColor> = .init(
        value: textColor.resolvedRgbColor(with: effectiveAppearance),
        velocity: .zero,
        target: textColor.resolvedRgbColor(with: effectiveAppearance)
    )

    /// A Boolean value that indicates the direction of the text animation.
    public var countsDown: Bool = false

    /// The technique for aligning the text.
    ///
    /// The default value for this property is `left`.
    public var alignment: TextAlignment = .leading {
        didSet {
            if oldValue == alignment {
                return
            }
            setNeedsUpdateTextLayout()
        }
    }

    /// The technique for wrapping and truncating the layer's text.
    public var lineBreakMode: NSLineBreakMode = .byTruncatingTail {
        didSet {
            if oldValue == lineBreakMode {
                return
            }
            setNeedsUpdateTextLayout()
        }
    }

    private var needsLastLineTruncation: Bool {
        switch lineBreakMode {
        case .byTruncatingTail, .byTruncatingHead, .byTruncatingMiddle, .byClipping:
            true
        default:
            false
        }
    }

    /// The maximum number of lines for rendering text.
    public var numberOfLines: Int = 1 {
        didSet {
            if oldValue == numberOfLines {
                return
            }
            setNeedsUpdateTextLayout()
        }
    }

    /// A Boolean value that specifies whether to enable font smoothing.
    public var isSmoothRenderingEnabled: Bool = false {
        didSet {
            if isSmoothRenderingEnabled == oldValue {
                return
            }
            layerStates.forEach {
                $0.0.setNeedsDisplay()
            }
        }
    }

    /// A Boolean value that indicates whether views should disable animations.
    public var disablesAnimations: Bool = false {
        didSet {
            if oldValue == disablesAnimations || !disablesAnimations {
                return
            }
            updateLayersToTarget()
        }
    }

    /// A Boolean value that indicates whether blur effect is enabled when transitioning text.
    public var isBlurEffectEnabled: Bool = true {
        didSet {
            if oldValue == isBlurEffectEnabled || isBlurEffectEnabled {
                return
            }

            for (_, state) in layerStates {
                state.blurRadiusAnimation = nil
                state.blurRadius = 0
            }
        }
    }

    private var containerBounds: CGRect = .zero

    private var textLayout: TextLayout?
    private var layerStates: [CALayer: LayerState] = [:]
    private var glyphStates: [String: ArrayContainer<LayerState>] = [:]
    private var isLayoutDirty: Bool = false

    private let smoothSpring: Spring = .smooth
    private let snappySpring: Spring = .init(duration: 0.3)
    private let phoneSpring: Spring = .smooth(duration: 0.42)
    private let bouncySpring: Spring = .init(response: 0.42, dampingRatio: 0.8)
    private var effectiveAppearance: Appearance = .initialValue

    /// The display sync observer that drives animations of this layer.
    ///
    /// Clients must invalidate the observer when tearing down, and the
    /// layer will only set `frameUpdateHandler` of the observer.
    @MainActor
    var displaySyncObserver: VSyncObserver? {
        didSet {
            configureDisplaySyncObserver()
        }
    }
    private var lastFrameTimestamp: CFTimeInterval?

    @MainActor
    private func configureDisplaySyncObserver() {
        guard let displaySyncObserver else {
            return
        }
        lastFrameTimestamp = nil
        displaySyncObserver.frameUpdateHandler = { [weak self] context in
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self?.animateTransition(with: context)
            CATransaction.commit()
        }
    }

    override public func action(forKey key: String) -> (any CAAction)? {
        NSNull()
    }

    override public func layoutSublayers() {
        super.layoutSublayers()

        if containerBounds != bounds {
            containerBounds = bounds
            setNeedsUpdateTextLayout()
            return
        }
        
        if isLayoutDirty {
            updateTextLayout()
        }

        for (_, state) in layerStates {
            updateFrame(with: state)
        }
    }

    func effectiveAppearanceDidChange(_ appearance: Appearance) {
        effectiveAppearance = appearance
        let color = textColor
        textColor = color
    }

    public func size(fitting constrainedSize: CGSize) -> CGSize {
        guard let textLayout else {
            return .zero
        }

        return textLayout.size(fitting: constrainedSize)
    }
}

extension GlyphixTextLayer {

    final class LayerState {

        protocol Delegate: AnyObject {
            
            var isBlurEffectEnabled: Bool { get }
            
            func updateFrame(with state: LayerState)
        }

        var frame: CGRect = .zero {
            didSet {
                if frame == presentationFrame {
                    return
                }
                var animation: AnimationState<CGRect> = frameAnimation ?? .init(value: presentationFrame, velocity: .zero, target: frame)
                animation.target = frame
                frameAnimation = animation
            }
        }

        var presentationFrame: CGRect = .zero {
            didSet {
                delegate?.updateFrame(with: self)
            }
        }

        var frameAnimation: AnimationState<CGRect>?

        var scale: CGFloat = 1
        var scaleAnimation: AnimationState<CGFloat>?

        var offset: CGFloat = 0
        var offsetAnimation: AnimationState<CGFloat>?

        var opacity: Float = 1 {
            didSet { layer.opacity = opacity }
        }
        var opacityAnimation: AnimationState<Float>?

        var blurRadius: CGFloat = 0 {
            didSet {
                // Avoid fractional blur radius for performance reasons.
                let targetRadius = round(blurRadius)
                if targetRadius == round(oldValue) {
                    // No need to update the layer if the value is the same.
                    return
                }
                layer.setValue(targetRadius, forKeyPath: GaussianBlurFilter.inputRadiusKeyPath)
            }
        }
        var blurRadiusAnimation: AnimationState<CGFloat>?

        var delay: TimeInterval = 0
        var invalid: Bool = false

        var isAnimating: Bool {
            frameAnimation != nil
                || scaleAnimation != nil
                || offsetAnimation != nil
                || opacityAnimation != nil
                || blurRadiusAnimation != nil
        }

        var isVisible: Bool {
            if let opacityAnimation {
                return opacityAnimation.value >= 0.01
            }
            return opacity >= 0.01
        }

        let layer: CALayer

        var key: String?
        var font: CTFont?
        var glyph: CGGlyph?
        var boundingRect: CGRect = .zero
        var descent: CGFloat = 0

        weak var delegate: (any Delegate)?

        init(layer: CALayer) {
            self.layer = layer
        }

        func updateTransform() {
            let transform = CATransform3DConcat(
                CATransform3DMakeScale(scale, scale, 1),
                CATransform3DMakeTranslation(0, offset * frame.height / 3, 0)
            )
            layer.transform = transform
        }

        enum AnimationType {
            case appear
            case disappear
        }

        private static let smallestScale: CGFloat = 0.4

        private var appearBlurRadius: CGFloat {
            log(frame.height) / log(3)
        }
        private var disappearBlurRadius: CGFloat {
            log(frame.height)
        }

        func configureAnimation(with type: AnimationType, countsDown: Bool = false) {
            switch type {
            case .appear:
                scaleAnimation = .init(value: Self.smallestScale, velocity: .zero, target: 1)
                scale = Self.smallestScale
                let offset: CGFloat = countsDown ? -1 : 1
                offsetAnimation = .init(value: offset, velocity: .zero, target: 0)
                self.offset = offset
                opacityAnimation = .init(value: 0, velocity: .zero, target: 1)
                opacity = 0
                if delegate?.isBlurEffectEnabled == true {
                    blurRadiusAnimation = .init(value: appearBlurRadius, velocity: 0, target: 0)
                    blurRadius = appearBlurRadius
                }
                updateTransform()
            case .disappear:
                var scaleAnimation = scaleAnimation ?? .init(value: scale, velocity: .zero, target: Self.smallestScale)
                scaleAnimation.target = Self.smallestScale
                self.scaleAnimation = scaleAnimation

                let offset: CGFloat = countsDown ? 1 : -1
                var offsetAnimation = offsetAnimation ?? .init(value: self.offset, velocity: .zero, target: offset)
                offsetAnimation.target = offset
                self.offsetAnimation = offsetAnimation

                var opacityAnimation = opacityAnimation ?? .init(value: opacity, velocity: .zero, target: 0)
                opacityAnimation.target = 0
                self.opacityAnimation = opacityAnimation

                if delegate?.isBlurEffectEnabled == true {
                    var blurRadiusAnimation = blurRadiusAnimation ?? .init(value: blurRadius, velocity: 0, target: disappearBlurRadius)
                    blurRadiusAnimation.target = disappearBlurRadius
                    self.blurRadiusAnimation = blurRadiusAnimation
                }
            }
        }
    }
}

extension GlyphixTextLayer: GlyphixTextLayer.LayerState.Delegate {

    func updateFrame(with state: LayerState) {
        let layer = state.layer
        let targetFrame = state.presentationFrame
        let transform = layer.transform
        layer.transform = CATransform3DIdentity

        let currentSize = layer.bounds.size
        if currentSize != targetFrame.size {
            layer.frame = targetFrame
        } else {
            layer.position = .init(x: targetFrame.midX, y: targetFrame.midY)
        }
        layer.transform = transform
    }
}

extension GlyphixTextLayer {

    private func makeLayerState() -> LayerState {
        let layer = CALayer()
        layer.delegate = self
        layer.allowsEdgeAntialiasing = true
        layer.needsDisplayOnBoundsChange = true

        #if os(iOS)
        let contentsScale: CGFloat = (delegate as? PlatformView)?.window?.screen.scale ?? 2
        #elseif os(macOS)
        let contentsScale: CGFloat = (delegate as? PlatformView)?.window?.screen?.backingScaleFactor ?? 2
        #endif
        layer.contentsScale = contentsScale

        var filters: [Any] = []
        if var colorFilter = ColorAddFilter() {
            colorFilter.inputColor = colorAnimation.value.cgColor
            filters.append(colorFilter.effect)
        }
        if let blurFilter = GaussianBlurFilter() {
            filters.append(blurFilter.effect)
        }
        layer.filters = filters

        let state = LayerState(layer: layer)
        state.delegate = self
        return state
    }

    private func stateContainer(for glyph: String) -> ArrayContainer<LayerState> {
        if let container = glyphStates[glyph] {
            return container
        }

        let container = ArrayContainer<LayerState>()
        glyphStates[glyph] = container
        return container
    }

    private func setNeedsUpdateTextLayout() {
        if let text {
            let textLayoutBuilder = TextLayout.Builder(
                text: text,
                font: effectiveFont,
                containerBounds: containerBounds,
                alignment: alignment,
                lineBreakMode: lineBreakMode,
                numberOfLines: numberOfLines
            )
            self.textLayout = textLayoutBuilder.build()
        } else {
            self.textLayout = nil
        }
        
        isLayoutDirty = true
        setNeedsLayout()
    }
    
    private func updateTextLayout() {
        defer { isLayoutDirty = false }
        layerStates.forEach { $1.invalid = true }
        
        var stateNeedsAppearAnimation: [LayerState] = []
        if let textLayout {
            nextGlyph: for placedGlyph in textLayout.placedGlyphs {
                let stateKey = placedGlyph.glyphName ?? ""
                let glyph = placedGlyph.glyph
                let descent = placedGlyph.descent
                let boundingRect = placedGlyph.boundingRect
                let rect = placedGlyph.layoutRect
                let font = placedGlyph.font
                if let states = glyphStates[stateKey], !stateKey.isEmpty {
                    for state in states {
                        if !state.invalid {
                            continue
                        }

                        let isInVisibleAnimation =
                            state.scaleAnimation != nil
                            || state.opacityAnimation != nil
                            || state.blurRadiusAnimation != nil
                            || state.offsetAnimation != nil

                        let isAppearing =
                            state.scaleAnimation?.target == 1
                            || state.opacityAnimation?.target == 1
                            || state.blurRadiusAnimation?.target == 0
                            || state.offsetAnimation?.target == 0
                        if isAppearing || !isInVisibleAnimation {
                            state.font = font
                            state.glyph = glyph
                            state.descent = descent
                            state.boundingRect = boundingRect
                            state.frame = rect
                            state.invalid = false
                            state.layer.setNeedsDisplay()
                            continue nextGlyph
                        }
                    }
                }

                let state = makeLayerState()
                state.font = font
                state.glyph = glyph
                state.descent = descent
                state.boundingRect = boundingRect
                state.key = stateKey
                let layer = state.layer
                addSublayer(layer)
                state.presentationFrame = rect
                state.frame = rect
                stateNeedsAppearAnimation.append(state)
                layerStates[layer] = state

                let container = stateContainer(for: stateKey)
                container.append(state)

                layer.setNeedsDisplay()
            }
        }

        if disablesAnimations {
            updateLayersToTarget()
            return
        }

        let invalidStates = layerStates.filter {
            $1.invalid
        }

        let appearCount = stateNeedsAppearAnimation.count
        let disappearCount = invalidStates.count
        let length = TimeInterval(max(appearCount, disappearCount))
        let delayInterval: TimeInterval = (length == 0 ? 0 : 0.2 / length)
        for (index, state) in stateNeedsAppearAnimation.enumerated() {
            state.delay = TimeInterval(index) * delayInterval
            state.configureAnimation(with: .appear, countsDown: countsDown)
        }

        invalidStates
            .sorted {
                $0.1.frame.minX < $1.1.frame.minX
            }
            .enumerated()
            .forEach {
                let state = $1.1
                if !state.isAnimating {
                    state.delay = TimeInterval($0) * delayInterval
                }
                state.configureAnimation(with: .disappear, countsDown: countsDown)
            }
    }

    func updateLayerColor(_ layer: CALayer) {
        layer.setValue(colorAnimation.value.cgColor, forKeyPath: ColorAddFilter.inputColorKeyPath)
    }

    func animateTransition(with context: VSyncEventContext) {
        if disablesAnimations {
            return
        }

        #if DEBUG && os(iOS)
        let animationFactor: TimeInterval = 1 / TimeInterval(UIAnimationDragCoefficient())
        #else
        let animationFactor: TimeInterval = 1
        #endif
        defer { lastFrameTimestamp = context.targetTimestamp }
        let duration =
            if let lastFrameTimestamp {
                Double(context.targetTimestamp - lastFrameTimestamp) * animationFactor
            } else {
                0.0
            }
        if duration == 0 {
            return
        }

        var needsRedraw = false
        var colorAnimation = colorAnimation
        if !colorAnimation.isCompleted {
            needsRedraw = true
            smoothSpring.update(
                value: &colorAnimation.value,
                velocity: &colorAnimation.velocity,
                target: colorAnimation.target,
                deltaTime: duration
            )
            if colorAnimation.isCompleted {
                colorAnimation.value = colorAnimation.target
            }
            self.colorAnimation = colorAnimation
        }

        var removeStates: [LayerState] = .init()
        for (_, state) in layerStates {
            if needsRedraw {
                updateLayerColor(state.layer)
            }
            updateLayerState(state, deltaTime: duration)
            if !state.isVisible, state.invalid {
                removeStates.append(state)
            }
        }
        cleanUpStates(removeStates)
    }

    func updateLayerState(_ state: LayerState, deltaTime: TimeInterval) {
        state.delay -= deltaTime
        if state.delay > 0 { return }

        if var frameAnimation = state.frameAnimation {
            smoothSpring.update(
                value: &frameAnimation.value,
                velocity: &frameAnimation.velocity,
                target: frameAnimation.target,
                deltaTime: deltaTime
            )
            state.presentationFrame = frameAnimation.value
            if frameAnimation.isCompleted {
                state.frame = frameAnimation.target
                state.frameAnimation = nil
            } else {
                state.frameAnimation = frameAnimation
            }
        }

        if var scaleAnimation = state.scaleAnimation {
            snappySpring.update(
                value: &scaleAnimation.value,
                velocity: &scaleAnimation.velocity,
                target: scaleAnimation.target,
                deltaTime: deltaTime
            )
            state.scale = scaleAnimation.value
            if scaleAnimation.isCompleted {
                state.scale = scaleAnimation.target
                state.scaleAnimation = nil
            } else {
                state.scaleAnimation = scaleAnimation
            }
        }

        if var offsetAnimation = state.offsetAnimation {
            let bouncy = Spring(response: 0.4, dampingRatio: 0.54)
            bouncy.update(
                value: &offsetAnimation.value,
                velocity: &offsetAnimation.velocity,
                target: offsetAnimation.target,
                deltaTime: deltaTime
            )
            state.offset = offsetAnimation.value
            if offsetAnimation.isCompleted {
                state.offset = offsetAnimation.target
                state.offsetAnimation = nil
            } else {
                state.offsetAnimation = offsetAnimation
            }
        }

        state.updateTransform()

        if var opacityAnimation = state.opacityAnimation {
            phoneSpring.update(
                value: &opacityAnimation.value,
                velocity: &opacityAnimation.velocity,
                target: opacityAnimation.target,
                deltaTime: deltaTime
            )
            state.opacity = opacityAnimation.value
            if opacityAnimation.isCompleted {
                state.opacity = opacityAnimation.target
                state.opacityAnimation = nil
            } else {
                state.opacityAnimation = opacityAnimation
            }
        }

        if var blurRadiusAnimation = state.blurRadiusAnimation, isBlurEffectEnabled {
            bouncySpring.update(
                value: &blurRadiusAnimation.value,
                velocity: &blurRadiusAnimation.velocity,
                target: blurRadiusAnimation.target,
                deltaTime: deltaTime
            )
            state.blurRadius = blurRadiusAnimation.value
            if blurRadiusAnimation.isCompleted {
                state.blurRadius = blurRadiusAnimation.target
                state.blurRadiusAnimation = nil
            } else {
                state.blurRadiusAnimation = blurRadiusAnimation
            }
        }
    }

    private func cleanUpStates(_ states: [LayerState]) {
        for state in states {
            let layer = state.layer
            layer.removeFromSuperlayer()
            layerStates.removeValue(forKey: layer)
            guard let key = state.key else {
                continue
            }
            guard let container = glyphStates[key] else {
                continue
            }
            container.removeAll { $0 === state }
            if container.isEmpty {
                glyphStates.removeValue(forKey: key)
            }
        }
    }

    /// Directly update the state of the layer to its final state cancel all animations.
    private func updateLayersToTarget() {
        var needsRemove: [LayerState] = []
        let needsRedraw = !colorAnimation.isCompleted
        colorAnimation.velocity = .zero
        colorAnimation.value = colorAnimation.target
        for (_, state) in layerStates {
            if state.invalid {
                needsRemove.append(state)
                state.layer.removeFromSuperlayer()
                continue
            }
            state.frameAnimation = nil
            state.presentationFrame = state.frame
            state.scaleAnimation = nil
            state.scale = 1
            state.offsetAnimation = nil
            state.offset = 0
            state.opacityAnimation = nil
            state.opacity = 1
            state.blurRadiusAnimation = nil
            state.blurRadius = 0
            state.updateTransform()

            let layer = state.layer

            if needsRedraw {
                updateLayerColor(layer)
            }

            layer.setNeedsDisplay()
            layer.displayIfNeeded()
        }
        cleanUpStates(needsRemove)
    }
}

// MARK: - CALayerDelegate

extension GlyphixTextLayer: CALayerDelegate {

    public func action(for layer: CALayer, forKey key: String) -> (any CAAction)? {
        NSNull()
    }

    public func draw(_ layer: CALayer, in ctx: CGContext) {
        guard let state = layerStates[layer],
            let font = state.font,
            var glyph = state.glyph
        else {
            assertionFailure("invalid layer state")
            return
        }

        ctx.saveGState()
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        if isSmoothRenderingEnabled {
            ctx.setAllowsFontSmoothing(true)
            ctx.setShouldSmoothFonts(true)
        }
        ctx.translateBy(x: 0, y: layer.bounds.height)
        ctx.scaleBy(x: 1, y: -1)

        if state.frameAnimation?.isCompleted == false {
            // Ensure the glyph is drawn correctly in a scaled layer.
            ctx.scaleBy(
                x: layer.bounds.width / state.frame.width,
                y: layer.bounds.height / state.frame.height
            )
        }

        let boundingRect = state.boundingRect
        let descent = state.descent
        var position: CGPoint = .init(x: -min(0, boundingRect.minX), y: descent - min(0, boundingRect.minY + descent))
        CTFontDrawGlyphs(font, &glyph, &position, 1, ctx)

        ctx.restoreGState()
    }
}
