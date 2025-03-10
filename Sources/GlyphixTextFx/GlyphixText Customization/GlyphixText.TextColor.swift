//
//  GlyphixText.TextColor.swift
//  GlyphixTextFx
//
//  Created by LiYanan2004 on 2025/3/10.
//

import SwiftUI

extension View {
    /// Sets the color of the label.
    public func glyphixLabelColor(_ color: PlatformColor?) -> some View {
        transformEnvironment(\.glyphixLabelColor) { glyphixLabelColor in
            glyphixLabelColor = color
        }
    }
}

struct GlyphixLabelColor: EnvironmentKey {
    static var defaultValue: PlatformColor? = nil
}

extension EnvironmentValues {
    var glyphixLabelColor: PlatformColor? {
        get { self[GlyphixLabelColor.self] }
        set { self[GlyphixLabelColor.self] = newValue }
    }
}
