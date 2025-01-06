//
//  Created by ktiays on 2024/11/16.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import MSDisplayLink
import Respring

public final class NumericTransitionTextLayer: CALayer {
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

    private lazy var textContainer: NSTextContainer = .init(size: .init(
        width: CGFloat.greatestFiniteMagnitude,
        height: CGFloat.greatestFiniteMagnitude
    ))
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

    private var layerStates: [CALayer: State] = [:]
    private var characterStates: [Character: ArrayContainer<State>] = [:]
    private let smoothSpring: Spring = .smooth
    private let snappySpring: Spring = .init(duration: 0.3)
    private let phoneSpring: Spring = .smooth(duration: 0.42)
    private let bouncySpring: Spring = .init(response: 0.4, dampingRatio: 0.66)
    private var effectiveAppearance: Appearance = .initialValue

    private let displayLink = DisplayLink()

    override init() {
        super.init()
        commitInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commitInit()
    }

    private func commitInit() {
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

extension NumericTransitionTextLayer {
    func makeLayerState() -> State {
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

        let state = State(layer: layer)
        state.delegate = self
        return state
    }

    func stateContainer(for character: Character) -> ArrayContainer<State> {
        if let container = characterStates[character] {
            return container
        }

        let container = ArrayContainer<State>()
        characterStates[character] = container
        return container
    }

    func updateText() {
        let attributedText = NSAttributedString(
            string: text,
            attributes: [.font: font]
        )
        textStorage.setAttributedString(attributedText)

        let length = TimeInterval(attributedText.length)
        let delayInterval: TimeInterval = (length == 0 ? 0 : 0.18 / length)
        textBounds = .zero
        layerStates.forEach { $1.invalid = true }

        var needsAppearCount = 0
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
            state.delay = TimeInterval(needsAppearCount) * delayInterval
            state.configureAnimation(with: .appear, countsDown: countsDown)
            needsAppearCount += 1
            layerStates[layer] = state

            let container = stateContainer(for: character)
            container.append(state)

            layer.setNeedsDisplay()
        }

        layerStates.filter {
            $1.invalid
        }
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

        var removeStates: [State] = .init()
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

    func updateLayerState(_ state: State, deltaTime: TimeInterval) {
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
            bouncySpring.update(
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

extension NumericTransitionTextLayer: CALayerDelegate {
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

        let contentsScale: CGFloat = (delegate as? PlatformView)?
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
            let anchor: CGFloat = switch alignment {
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
            ctx.restoreGState()
        }
    }
}

extension NumericTransitionTextLayer: DisplayLinkDelegate {
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
