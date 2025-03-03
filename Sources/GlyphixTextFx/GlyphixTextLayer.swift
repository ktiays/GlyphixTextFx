//
//  Created by ktiays on 2024/11/16.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import CoreText
import MSDisplayLink
import Respring
import GTFHook
import With

#if os(iOS)
import UIKit
#else
import AppKit
#endif

open class GlyphixTextLayer: CALayer {

    public var text: String? {
        didSet {
            if text == attributedText?.string {
                return
            }
            updateAttributedText()
        }
    }
    private var attributedText: NSAttributedString?
    
    public var font: PlatformFont? {
        didSet {
            if font == oldValue {
                return
            }
            updateAttributedText()
        }
    }
    private let defaultFont: PlatformFont = .systemFont(ofSize: PlatformFont.labelFontSize)

    private var effectiveFont: PlatformFont {
        font ?? defaultFont
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

    /// Constants that specify text alignment.
    public enum TextAlignment {
        /// Text is left-aligned.
        case left
        /// Text is center-aligned.
        case center
        /// Text is right-aligned.
        case right
    }

    public var alignment: TextAlignment = .center {
        didSet {
            if oldValue == alignment {
                return
            }
            updateTextLayout()
        }
    }

    /// The maximum number of lines for rendering text.
    public var numberOfLines: Int = 1 {
        didSet {
            if oldValue == numberOfLines {
                return
            }
            updateTextLayout()
        }
    }
    
    /// A Boolean value that specifies whether to enable font smoothing.
    public var isSmoothRenderingEnabled: Bool = false

    /// A Boolean value that indicates whether views should disable animations.
    public var disablesAnimations: Bool = false

    private var containerBounds: CGRect = .zero

    private var ctFrame: CTFrame?
    private var ctFramesetter: CTFramesetter?
    private var lines: [CTLine] = []
    
    private var layerStates: [CALayer: LayerState] = [:]
    private var glyphStates: [String: ArrayContainer<LayerState>] = [:]
    
    private let smoothSpring: Spring = .smooth
    private let snappySpring: Spring = .init(duration: 0.3)
    private let phoneSpring: Spring = .smooth(duration: 0.42)
    private let bouncySpring: Spring = .init(response: 0.42, dampingRatio: 0.8)
    private var effectiveAppearance: Appearance = .initialValue

    private let displayLink = DisplayLink()

    override init() {
        super.init()
        configureDisplayLink()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureDisplayLink()
    }

    public override init(layer: Any) {
        super.init(layer: layer)
        configureDisplayLink()
    }
    
    private func configureDisplayLink() {
        displayLink.delegatingObject(self)
    }

    override public func action(forKey key: String) -> (any CAAction)? {
        NSNull()
    }
    
    override public func layoutSublayers() {
        super.layoutSublayers()

        if containerBounds != bounds {
            containerBounds = bounds
            updateTextLayout()
            setNeedsLayout()
            return
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
    
    public func intrinsicSize(within size: CGSize) -> CGSize {
        guard let ctFramesetter else {
            return .zero
        }
        
        return CTFramesetterSuggestFrameSizeWithConstraints(ctFramesetter, .zero, nil, size, nil)
    }

    private func makeAttributedString(_ text: String) -> NSAttributedString {
        .init(string: text, attributes: [.font: effectiveFont])
    }
    
    private func updateAttributedText() {
        if let text {
            let attributedText = NSAttributedString(
                string: text ?? .init(),
                attributes: [.font: effectiveFont]
            )
            ctFramesetter = CTFramesetterCreateWithAttributedString(attributedText)
            self.attributedText = attributedText
        } else {
            attributedText = nil
            ctFramesetter = nil
        }
        updateTextLayout()
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

        var key: String?
        var font: CTFont?
        var glyph: CGGlyph?
        var boundingRect: CGRect = .zero
        var descent: CGFloat = 0
        var textBounds: CGRect = .zero

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
        let layer = state.layer
        let frame = state.presentationFrame
        let transform = layer.transform
        layer.transform = CATransform3DIdentity
        let textBounds = state.textBounds

        let offsetX: CGFloat =
            switch alignment {
            case .left:
                0
            case .center:
                (bounds.width - textBounds.width) / 2
            case .right:
                bounds.width - textBounds.width
            }
        let targetFrame = frame.offsetBy(dx: max(0, offsetX), dy: (bounds.height - textBounds.height) / 2)

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

    private func makeLayerState() -> LayerState {
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

    private func stateContainer(for glyph: String) -> ArrayContainer<LayerState> {
        if let container = glyphStates[glyph] {
            return container
        }

        let container = ArrayContainer<LayerState>()
        glyphStates[glyph] = container
        return container
    }

    private func updateTextLayout() {
        ctFrame = nil
        lines.removeAll()
        let containerPath = CGPath(rect: containerBounds, transform: nil)
        if let ctFramesetter {
            let ctFrame = CTFramesetterCreateFrame(ctFramesetter, .zero, containerPath, nil)
            self.ctFrame = ctFrame
            lines = CTFrameGetLines(ctFrame) as! [CTLine]
            var isLastLineTruncated: Bool = false
            if numberOfLines > 0 && lines.count > numberOfLines {
                lines.removeSubrange(numberOfLines...)
                isLastLineTruncated = true
            }
            if !isLastLineTruncated {
                let visibleRange = CTFrameGetVisibleStringRange(ctFrame)
                isLastLineTruncated = (visibleRange.length != attributedText?.length && !lines.isEmpty)
            }

            if let attributedText, isLastLineTruncated, let lastLine = lines.last {
                // Truncation processing is required for the last line.
                let lineCFRange = CTLineGetStringRange(lastLine)
                let lineRange = NSRange(location: lineCFRange.location, length: lineCFRange.length)
                let lastLineString: NSMutableAttributedString = .init(attributedString: attributedText.attributedSubstring(from: lineRange))
                let truncationTokenString = makeAttributedString("\u{2026}")
                lastLineString.append(truncationTokenString)
                let line = CTLineCreateWithAttributedString(lastLineString)
                let truncationLine = CTLineCreateWithAttributedString(truncationTokenString)
                if let truncatedLine = CTLineCreateTruncatedLine(line, containerBounds.width, .end, truncationLine) {
                    lines[lines.count - 1] = truncatedLine
                }
            }
        }
        layerStates.forEach { $1.invalid = true }

        var stateNeedsAppearAnimation: [LayerState] = []
        if let text, let ctFrame {
            var lineBoundsList: [CGRect] = []
            var descents: [CGFloat] = []
            var textBounds: CGRect = .zero
            for (index, line) in lines.enumerated() {
                var ascent: CGFloat = 0
                var descent: CGFloat = 0
                let width = CTLineGetTypographicBounds(line, &ascent, &descent, nil)
                let height = ascent + descent
                textBounds.size.width = max(textBounds.width, width)
                textBounds.size.height += height
                lineBoundsList.append(.init(x: 0, y: textBounds.height - height, width: width, height: height))
                descents.append(descent)
            }

            for (lineIndex, line) in lines.enumerated() {
                let lineBounds = lineBoundsList[lineIndex]
                let lineOrigin = lineBounds.origin
                let descent = descents[lineIndex]
                let runs = CTLineGetGlyphRuns(line) as! [CTRun]
                for run in runs {
                    let attributes = CTRunGetAttributes(run) as! [NSAttributedString.Key: Any]
                    let platformFont = attributes[.font] as? PlatformFont
                    let font = (platformFont ?? effectiveFont) as CTFont
                    let cgFont = CTFontCopyGraphicsFont(font, nil)
                    let glyphCount = CTRunGetGlyphCount(run)
                    var positions: [CGPoint] = .init(repeating: .zero, count: glyphCount)
                    CTRunGetPositions(run, .zero, &positions)
                    // Stores the glyph advances (widths), representing the horizontal distance to
                    // the next character for precise text layout and width calculation.
                    var advances: [CGSize] = .init(repeating: .zero, count: glyphCount)
                    CTRunGetAdvances(run, .zero, &advances)
                    
                    var glyphs = [CGGlyph](repeating: 0, count: glyphCount)
                    CTRunGetGlyphs(run, .zero, &glyphs)
                    var boundingRects: [CGRect] = .init(repeating: .zero, count: glyphCount)
                    CTFontGetBoundingRectsForGlyphs(font, .default, &glyphs, &boundingRects, glyphCount)
                    nextGlyph: for (glyphIndex, var glyph) in glyphs.enumerated() {
                        var stateKey: String = .init()
                        if let glyphName = cgFont.name(for: glyph) as? String, !glyphName.isEmpty {
                            stateKey = glyphName
                        }

                        let position = positions[glyphIndex]
                        let advance = advances[glyphIndex]
                        let boundingRect = boundingRects[glyphIndex]
                        // Correction value in the x-axis direction, as character rendering may exceed the grid area,
                        // requiring the left-side x to store a value indicating the necessary offset.
                        let xCompensation = min(0, boundingRect.minX)
                        let bottomExtends = min(0, boundingRect.minY + descent)
                        let topExtends = max(0, boundingRect.maxY + descent - lineBounds.height)
                        let rect = CGRect(
                            x: lineOrigin.x + position.x + xCompensation,
                            y: lineOrigin.y + position.y - topExtends,
                            width: ceil(max(advance.width, boundingRect.maxX)),
                            height: lineBounds.height - bottomExtends
                        )

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
                                    state.textBounds = textBounds
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
                                    continue nextGlyph
                                }
                            }
                        }

                        let state = makeLayerState()
                        state.font = font
                        state.glyph = glyph
                        state.descent = descent
                        state.boundingRect = boundingRect
                        state.textBounds = textBounds
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
            }
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

    func animateTransition(with context: DisplayLinkCallbackContext) {
        #if DEBUG && os(iOS)
        let animationFactor: TimeInterval = 1 / TimeInterval(UIAnimationDragCoefficient())
        #else
        let animationFactor: TimeInterval = 1
        #endif
        let duration = max(0, min(context.duration, context.targetTimestamp - context.timestamp) * animationFactor)
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
        for state in removeStates {
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

    public func action(for layer: CALayer, forKey key: String) -> (any CAAction)? {
        NSNull()
    }

    public func draw(_ layer: CALayer, in ctx: CGContext) {
        guard let state = layerStates[layer],
              let font = state.font,
              var glyph = state.glyph
        else { return }
        
        #if os(iOS)
        let contentsScale: CGFloat = (delegate as? PlatformView)?.window?.screen.scale ?? 2
        #elseif os(macOS)
        let contentsScale: CGFloat = (delegate as? PlatformView)?.window?.screen?.backingScaleFactor ?? 1
        #endif

        if layer.contentsScale != contentsScale {
            layer.contentsScale = contentsScale
            DispatchQueue.main.async {
                layer.setNeedsDisplay()
            }
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
        
        let boundingRect = state.boundingRect
        let descent = state.descent
        var position: CGPoint = .init(x: -min(0, boundingRect.minX), y: descent - min(0, boundingRect.minY + descent))
        CTFontDrawGlyphs(font, &glyph, &position, 1, ctx)
        
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
