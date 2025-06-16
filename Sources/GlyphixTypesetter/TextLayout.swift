//
//  Created by Cyandev on 2025/3/4.
//  Copyright (c) 2025 ktiays. All rights reserved.
//

import CoreText
import With

#if os(iOS)
import UIKit
#else
import AppKit
#endif

/// An alignment position for text along the horizontal axis.
public enum TextAlignment: CaseIterable {
    /// Text is center-aligned.
    case center
    /// Text is left-aligned.
    case leading
    /// Text is right-aligned.
    case trailing
}

public class TextLayout {

    /// A type for generating the text layout.
    public struct Builder {

        /// The text.
        public var text: String

        /// The font for the text.
        public var font: PlatformFont

        /// The bounding rectangle of the text container.
        public var containerBounds: CGRect

        /// The technique for aligning the text.
        ///
        /// The default value for this property is `.left`.
        public var alignment: TextAlignment

        /// The technique for wrapping and truncating the text.
        ///
        /// The default value for this property is `.byTruncatingTail`.
        public var lineBreakMode: NSLineBreakMode

        /// The maximum number of lines for the text.
        ///
        /// A value of 0 indicates that the number of lines is limitless.
        /// The default value for this property is `1`.
        public var numberOfLines: Int

        public init(
            text: String,
            font: PlatformFont,
            containerBounds: CGRect,
            alignment: TextAlignment = .leading,
            lineBreakMode: NSLineBreakMode = .byTruncatingTail,
            numberOfLines: Int = 1
        ) {
            self.text = text
            self.font = font
            self.containerBounds = containerBounds
            self.alignment = alignment
            self.lineBreakMode = lineBreakMode
            self.numberOfLines = numberOfLines
        }
    }

    @usableFromInline
    var framesetter: CTFramesetter

    /// The placed glyphs.
    public private(set) var placedGlyphs: [PlacedGlyph]

    /// The size of the bounding box that contains all the glyphs.
    public private(set) var size: CGSize

    fileprivate init(framesetter: CTFramesetter, placedGlyphs: [PlacedGlyph], size: CGSize) {
        self.framesetter = framesetter
        self.placedGlyphs = placedGlyphs
        self.size = size
    }

    @inlinable
    public func size(fitting constrainedSize: CGSize) -> CGSize {
        return CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            .zero,
            nil,
            constrainedSize,
            nil
        )
    }
}

extension TextLayout.Builder {

    private var needsLastLineTruncation: Bool {
        switch lineBreakMode {
        case .byTruncatingTail, .byTruncatingHead, .byTruncatingMiddle, .byClipping:
            true
        default:
            false
        }
    }

    /// Creates an immutable text layout.
    public func build() -> TextLayout {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = needsLastLineTruncation ? .byWordWrapping : lineBreakMode
        let attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .paragraphStyle: paragraphStyle,
            ]
        )

        let framesetter = CTFramesetterCreateWithAttributedString(attributedText)
        let containerPath = CGPath(rect: .init(origin: .zero, size: containerBounds.size), transform: nil)

        let ctFrame = CTFramesetterCreateFrame(framesetter, .zero, containerPath, nil)
        var lines = CTFrameGetLines(ctFrame) as! [CTLine]
        var isLastLineTruncated: Bool = false
        if numberOfLines > 0 && lines.count > numberOfLines {
            lines.removeSubrange(numberOfLines...)
            isLastLineTruncated = true
        }
        if needsLastLineTruncation && !isLastLineTruncated {
            let visibleRange = CTFrameGetVisibleStringRange(ctFrame)
            isLastLineTruncated = (visibleRange.length != attributedText.length && !lines.isEmpty)
        }

        if needsLastLineTruncation && isLastLineTruncated {
            performLineTruncation(lines: &lines, attributedText: attributedText)
        }

        struct LineTraits {
            var ascent: CGFloat
            var descent: CGFloat
            var bounds: CGRect
        }

        var lineTraits: [LineTraits] = []
        var textBounds: CGRect = .zero
        for line in lines {
            var ascent: CGFloat = 0
            var descent: CGFloat = 0
            let width = min(containerBounds.width, CTLineGetTypographicBounds(line, &ascent, &descent, nil))
            let height = ascent + descent
            textBounds.size.width = max(textBounds.width, width)
            textBounds.size.height += height
            lineTraits.append(
                .init(
                    ascent: ascent,
                    descent: descent,
                    bounds: .init(x: 0, y: textBounds.height - height, width: width, height: height)
                )
            )
        }

        // Place glyphs.
        var placedGlyphs = [PlacedGlyph]()
        for (lineIndex, line) in lines.enumerated() {
            let (lineAscent, lineDescent, lineBounds) = with(lineTraits[lineIndex]) {
                ($0.ascent, $0.descent, $0.bounds)
            }
            let alignmentHorizontalOffset: CGFloat =
                switch alignment {
                case .leading:
                    0
                case .center:
                    (containerBounds.width - lineBounds.width) / 2
                case .trailing:
                    containerBounds.width - lineBounds.width
                }
            let alignmentVerticalOffset = (containerBounds.height - textBounds.height) / 2
            let lineOrigin = lineBounds.origin + CGPoint(x: alignmentHorizontalOffset, y: alignmentVerticalOffset)

            let runs = CTLineGetGlyphRuns(line) as! [CTRun]
            for run in runs {
                let attributes = CTRunGetAttributes(run) as! [NSAttributedString.Key: Any]
                // When the specified font is unable to render the text correctly, `CoreText` will automatically
                // match an appropriate system font based on the characters for display.
                // As a result, the font used to render this text may not be unique.
                let runFont = (attributes[.font] as? PlatformFont ?? font) as CTFont
                let cgFont = CTFontCopyGraphicsFont(runFont, nil)
                let glyphCount = CTRunGetGlyphCount(run)
                var positions: [CGPoint] = .init(repeating: .zero, count: glyphCount)
                positions.withUnsafeMutableBufferPointer { ptr in
                    CTRunGetPositions(run, .zero, ptr.baseAddress!)
                }
                // Stores the glyph advances (widths), representing the horizontal distance to
                // the next character for precise text layout and width calculation.
                var advances: [CGSize] = .init(repeating: .zero, count: glyphCount)
                advances.withUnsafeMutableBufferPointer { ptr in
                    CTRunGetAdvances(run, .zero, ptr.baseAddress!)
                }

                // Optimization - batch allocate the space for the run.
                placedGlyphs.reserveCapacity(placedGlyphs.count + glyphCount)

                var glyphs = [CGGlyph](repeating: 0, count: glyphCount)
                glyphs.withUnsafeMutableBufferPointer { ptr in
                    CTRunGetGlyphs(run, .zero, ptr.baseAddress!)
                }
                var boundingRects: [CGRect] = .init(repeating: .zero, count: glyphCount)
                glyphs.withUnsafeBufferPointer { glyph in
                    boundingRects.withUnsafeMutableBufferPointer { rects in
                        CTFontGetBoundingRectsForGlyphs(runFont, .default, glyph.baseAddress!, rects.baseAddress!, glyphCount)
                    }
                }
                for (glyphIndex, glyph) in glyphs.enumerated() {
                    let glyphName = cgFont.name(for: glyph) as? String
                    let position = positions[glyphIndex]
                    let advance = advances[glyphIndex]
                    let boundingRect = boundingRects[glyphIndex]
                    // Correction value in the x-axis direction, as character rendering may exceed the grid area,
                    // requiring the left-side x to store a value indicating the necessary offset.
                    let xCompensation = min(0, boundingRect.minX)
                    let bottomExtends = min(0, boundingRect.minY + lineDescent)
                    let topExtends = max(0, boundingRect.maxY + lineDescent - lineBounds.height)
                    var rect = CGRect(
                        x: lineOrigin.x + position.x + xCompensation,
                        y: lineOrigin.y + position.y - topExtends,
                        width: ceil(max(advance.width, boundingRect.maxX)),
                        height: lineBounds.height - bottomExtends + topExtends
                    )
                    if rect.minX > containerBounds.width {
                        break
                    }
                    if rect.maxX > containerBounds.width {
                        rect.size.width = containerBounds.width - rect.minX
                    }

                    placedGlyphs.append(
                        .init(
                            font: runFont,
                            glyph: glyph,
                            glyphName: glyphName,
                            boundingRect: boundingRect,
                            layoutRect: rect,
                            ascent: lineAscent,
                            descent: lineDescent
                        )
                    )
                }
            }
        }

        return .init(
            framesetter: framesetter,
            placedGlyphs: placedGlyphs,
            size: textBounds.size
        )
    }

    @inline(__always)
    private func makeAttributedString(_ text: String) -> NSAttributedString {
        .init(string: text, attributes: [.font: font])
    }

    @inline(__always)
    private func performLineTruncation(lines: inout [CTLine], attributedText: NSAttributedString) {
        guard let lastLine = lines.last else {
            return
        }

        // Truncation processing is required for the last line.
        let lineCFRange = CTLineGetStringRange(lastLine)
        var lineRange = NSRange(location: lineCFRange.location, length: lineCFRange.length)
        let needsAdditionalTruncation = (lineBreakMode == .byTruncatingTail)
        if !needsAdditionalTruncation {
            lineRange.length = attributedText.length - lineRange.location
        }
        let lastLineString: NSMutableAttributedString = .init(attributedString: attributedText.attributedSubstring(from: lineRange))
        let truncationTokenString = makeAttributedString("\u{2026}")
        if needsAdditionalTruncation {
            lastLineString.append(truncationTokenString)
        }
        let line = CTLineCreateWithAttributedString(lastLineString)

        if lineBreakMode == .byClipping {
            lines[lines.count - 1] = line
            return
        }

        let truncationLine = CTLineCreateWithAttributedString(truncationTokenString)
        let truncationType: CTLineTruncationType =
            switch lineBreakMode {
            case .byTruncatingHead:
                .start
            case .byTruncatingMiddle:
                .middle
            default:
                .end
            }
        if let truncatedLine = CTLineCreateTruncatedLine(
            line,
            containerBounds.width,
            truncationType,
            truncationLine
        ) {
            lines[lines.count - 1] = truncatedLine
        }
    }
}
