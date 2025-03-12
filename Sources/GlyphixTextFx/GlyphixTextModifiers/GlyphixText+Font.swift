//
//  GlyphixText+Font.swift
//  GlyphixTextFx
//
//  Created by LiYanan2004 on 2025/3/10.
//

import SwiftUI
import GlyphixTypesetter

extension View {
    /// Sets the font of the label.
    public func glyphixTextFont(_ font: PlatformFont?) -> some View {
        transformEnvironment(\.glyphixTextFont) { glyphixLabelFont in
            glyphixLabelFont = font
        }
    }
}

struct GlyphixTextFont: EnvironmentKey {
    static var defaultValue: PlatformFont? = nil
}

extension EnvironmentValues {
    var glyphixTextFont: PlatformFont? {
        get { self[GlyphixTextFont.self] }
        set { self[GlyphixTextFont.self] = newValue }
    }
}

