//
//  GlyphixText.Font.swift
//  GlyphixTextFx
//
//  Created by LiYanan2004 on 2025/3/10.
//

import SwiftUI
import GlyphixTypesetter

extension View {
    /// Sets the font of the label.
    public func glyphixLabelFont(_ font: PlatformFont?) -> some View {
        transformEnvironment(\.glyphixLabelFont) { glyphixLabelFont in
            glyphixLabelFont = font
        }
    }
}

struct GlyphixLabelFont: EnvironmentKey {
    static var defaultValue: PlatformFont? = nil
}

extension EnvironmentValues {
    var glyphixLabelFont: PlatformFont? {
        get { self[GlyphixLabelFont.self] }
        set { self[GlyphixLabelFont.self] = newValue }
    }
}

