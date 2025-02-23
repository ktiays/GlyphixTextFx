//
//  Created by ktiays on 2024/11/16.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import MSDisplayLink
import Respring

public final class GlyphixTextLayer: CALayer {

    public var text: String = "" {
        didSet { updateText() }
    }

    public var font: PlatformFont = .preferredFont(forTextStyle: .body) {
        didSet { updateText() }
    }

    public var textColor: PlatformColor = .numericLabelColor {
        didSet {
            colorAnimation.target = textColor.resolvedRgbColor(with: effectiveAppearance)
        }
    }

    private lazy var colorAnimation: AnimationState<RGBColor> = .init(
        value: textColor.resolvedRgbColor(with: effectiveAppearance),
        velocity: .zero,
        target: textColor.resolvedRgbColor(with: effectiveAppearance)
    )
    public var countsDown: Bool = false

    public enum TextAlignment {
        case left
        case center
        case right
    }

    public var alignment: TextAlignment = .center {
        didSet { updateText() }
    }

    private(set) var textBounds: CGRect = .zero {
        didSet {
            guard let view = delegate as? PlatformView else { return }
            view.invalidateIntrinsicContentSize()
        }
    }

    private lazy var defaultFont: PlatformFont = .systemFont(ofSize: PlatformFont.labelFontSize)

    private lazy var textContainer: NSTextContainer = .init(
        size: .init(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
    )
    private lazy var textStorage: NSTextStorage = .init()
    private lazy var textLayoutManager: NSLayoutManager = {
        let manager = NSLayoutManager()
        manager.addTextContainer(textContainer)
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = 0
        textContainer.lineBreakMode = .byWordWrapping
        textStorage.addLayoutManager(manager)
        return manager
    }()

    private var layerStates: [CALayer: LayerState] = [:]
    private var characterStates: [Character: ArrayContainer<LayerState>] = [:]
    private let smoothSpring: Spring = .smooth
    private let snappySpring: Spring = .init(duration: 0.3)
    private let phoneSpring: Spring = .smooth(duration: 0.42)
    private let bouncySpring: Spring = .init(response: 0.42, dampingRatio: 0.8)
    private var effectiveAppearance: Appearance = .initialValue

    private let displayLink = DisplayLink()

    override init() {
        super.init()
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    public override init(layer: Any) {
        super.init(layer: layer)
        commonInit()
    }

    private func commonInit() {
        displayLink.delegatingObject(self)
    }

    override public func action(forKey _: String) -> (any CAAction)? {
        NSNull()
    }

    override public func layoutSublayers() {
        super.layoutSublayers()

        for (_, state) in layerStates {
            updateFrame(with: state)
        }
    }

    func effectiveAppearanceDidChange(_ appearance: Appearance) {
        effectiveAppearance = appearance
        let color = textColor
        textColor = color
    }
}

extension GlyphixTextLayer {

    final class LayerState {

        protocol Delegate: AnyObject {
            func updateFrame(with state: GlyphixTextLayer.LayerState)
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
                layer.setValue(blurRadius, forKeyPath: GaussianBlurFilter.inputRadiusKeyPath)
            }
        }

        var blurRadiusAnimation: AnimationState<CGFloat>?

        var delay: TimeInterval = 0
        var invalid: Bool = false
        var isDirty: Bool = true

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

        var range: NSRange = .init()
        var character: Character?
        var textBounds: CGRect?

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
                blurRadiusAnimation = .init(value: appearBlurRadius, velocity: 0, target: 0)
                blurRadius = appearBlurRadius
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

                var blurRadiusAnimation = blurRadiusAnimation ?? .init(value: blurRadius, velocity: 0, target: disappearBlurRadius)
                blurRadiusAnimation.target = disappearBlurRadius
                self.blurRadiusAnimation = blurRadiusAnimation
            }
        }
    }
}

extension GlyphixTextLayer: GlyphixTextLayer.LayerState.Delegate {

    func updateFrame(with state: LayerState) {
        guard let textBounds = state.textBounds else {
            return
        }

        let anchor: CGPoint =
            switch alignment {
            case .left:
                .init(x: 0, y: bounds.midY)
            case .center:
                .init(x: bounds.midX, y: bounds.midY)
            case .right:
                .init(x: bounds.maxX, y: bounds.midY)
            }

        let layer = state.layer
        let frame = state.presentationFrame
        let transform = layer.transform
        layer.transform = CATransform3DIdentity
        let targetFrame = frame.offsetBy(dx: anchor.x, dy: anchor.y - textBounds.midY)
        let currentSize = layer.bounds.size
        if currentSize != frame.size {
            layer.frame = targetFrame
        } else {
            layer.position = .init(x: targetFrame.midX, y: targetFrame.midY)
        }
        layer.transform = transform
    }
}

extension GlyphixTextLayer {

    func makeLayerState() -> LayerState {
        let layer = CALayer()
        layer.delegate = self
        layer.allowsEdgeAntialiasing = true

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

    func stateContainer(for character: Character) -> ArrayContainer<LayerState> {
        if let container = characterStates[character] {
            return container
        }

        let container = ArrayContainer<LayerState>()
        characterStates[character] = container
        return container
    }

    func updateText() {
        let attributedText = NSAttributedString(
            string: text,
            attributes: [.font: font]
        )
        textStorage.setAttributedString(attributedText)
        textBounds = .zero
        layerStates.forEach { $1.invalid = true }

        var stateNeedsAppearAnimation: [LayerState] = []
        let boundingRect = textLayoutManager.boundingRect(
            forGlyphRange: NSRange(text.startIndex..., in: text),
            in: textContainer
        )
        textBounds = boundingRect
        nextCharacter: for (index, character) in text.enumerated() {
            let range = NSRange(location: index, length: 1)
            let anchor: CGFloat =
                switch alignment {
                case .left:
                    0
                case .center:
                    boundingRect.midX
                case .right:
                    boundingRect.maxX
                }
            let rect = textLayoutManager.boundingRect(forGlyphRange: range, in: textContainer)
                .offsetBy(dx: -anchor, dy: 0)

            if let states = characterStates[character] {
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
                        state.range = range
                        state.character = character
                        state.textBounds = boundingRect
                        if state.frame.size != rect.size {
                            // A character may have different sizes in different contexts. When reusing a character layer for frame animation,
                            // to ensure the character is drawn correctly at the new size, it is necessary to immediately adjust the layer's
                            // size to the final dimensions and redraw it at that size.
                            state.presentationFrame.size = rect.size
                        }
                        state.frame = rect
                        state.isDirty = true
                        state.invalid = false
                        state.layer.setNeedsDisplay()
                        continue nextCharacter
                    }
                }
            }

            let state = makeLayerState()
            state.range = range
            state.character = character
            let layer = state.layer
            addSublayer(layer)
            state.presentationFrame = rect
            state.textBounds = boundingRect
            state.frame = rect
            stateNeedsAppearAnimation.append(state)
            layerStates[layer] = state

            let container = stateContainer(for: character)
            container.append(state)

            layer.setNeedsDisplay()
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
                $0.1.range.location < $1.1.range.location
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

    func animateTransition(with context: DisplayLinkCallbackContext) {
        #if DEBUG && canImport(UIKit)
        let animationFactor: TimeInterval = 1 / TimeInterval(UIAnimationDragCoefficient())
        #else
        let animationFactor: TimeInterval = 1
        #endif
        let duration = min(context.duration, context.targetTimestamp - context.timestamp) * animationFactor

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
        for state in removeStates {
            let layer = state.layer
            layer.removeFromSuperlayer()
            layerStates.removeValue(forKey: layer)
            guard let character = state.character else {
                continue
            }
            guard let container = characterStates[character] else {
                continue
            }
            container.removeAll { $0 === state }
            if container.isEmpty {
                characterStates.removeValue(forKey: character)
            }
        }
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

        if var blurRadiusAnimation = state.blurRadiusAnimation {
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
}

// MARK: - CALayerDelegate

extension GlyphixTextLayer: CALayerDelegate {

    public func action(for _: CALayer, forKey _: String) -> (any CAAction)? {
        NSNull()
    }

    public func draw(_ layer: CALayer, in ctx: CGContext) {
        guard let state = layerStates[layer],
            let textBounds = state.textBounds,
            state.isDirty
        else { return }

        let range = state.range
        if range.length == 0 { return }

        // state mismatch, delay next drawing
        guard let storage = textLayoutManager.textStorage,
            storage.string.count >= range.upperBound
        else { return }

        let contentsScale: CGFloat =
            (delegate as? PlatformView)?
            .animationScalingFactor ?? 2

        if layer.contentsScale != contentsScale {
            layer.contentsScale = contentsScale
            DispatchQueue.main.async { layer.setNeedsDisplay() }
            return
        }
        defer { state.isDirty = false }

        ctx.saveGState()
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        ctx.setAllowsFontSmoothing(true)
        ctx.setShouldSmoothFonts(true)
        ctx.draw {
            let anchor: CGFloat =
                switch alignment {
                case .left:
                    0
                case .center:
                    textBounds.midX
                case .right:
                    textBounds.maxX
                }
            let origin = state.frame.offsetBy(dx: anchor, dy: 0).origin
            textLayoutManager.drawGlyphs(
                forGlyphRange: range,
                at: .init(x: -origin.x, y: -origin.y)
            )
        }
        ctx.restoreGState()
    }
}

extension GlyphixTextLayer: DisplayLinkDelegate {

    public func synchronization(context: DisplayLinkCallbackContext) {
        if Thread.isMainThread {
            animateTransition(with: context)
        } else {
            DispatchQueue.main.async {
                self.animateTransition(with: context)
            }
        }
    }
}
