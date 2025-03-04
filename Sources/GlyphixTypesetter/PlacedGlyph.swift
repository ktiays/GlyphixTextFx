//
//  Created by Cyandev on 2025/3/4.
//  Copyright (c) 2025 ktiays. All rights reserved.
//

import CoreGraphics
import CoreText

/// A placed glyphs in a text layout (or a text run).
public struct PlacedGlyph {

    /// The actual font used by this glyph.
    public let font: CTFont

    /// The glyph index.
    public let glyph: CGGlyph

    /// The glyph name.
    public let glyphName: String?

    /// The bounds of the glyph.
    public let boundingRect: CGRect

    /// The frame of the glyph in the layout.
    public let layoutRect: CGRect

    public let ascent: CGFloat
    public let descent: CGFloat

    init(
        font: CTFont,
        glyph: CGGlyph,
        glyphName: String?,
        boundingRect: CGRect,
        layoutRect: CGRect,
        ascent: CGFloat,
        descent: CGFloat
    ) {
        self.font = font
        self.glyph = glyph
        self.glyphName = glyphName
        self.boundingRect = boundingRect
        self.layoutRect = layoutRect
        self.ascent = ascent
        self.descent = descent
    }
}
