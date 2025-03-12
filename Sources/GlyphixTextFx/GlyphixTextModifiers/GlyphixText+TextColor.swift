//
//  GlyphixText+TextColor.swift
//  GlyphixTextFx
//
//  Created by LiYanan2004 on 2025/3/10.
//

import SwiftUI

extension View {
    /// Sets the color of the label.
    public func glyphixTextColor(_ color: PlatformColor?) -> some View {
        transformEnvironment(\.glyphixTextColor) { glyphixLabelColor in
            glyphixLabelColor = color
        }
    }
}

struct GlyphixTextColor: EnvironmentKey {
    static var defaultValue: PlatformColor? = nil
}

extension EnvironmentValues {
    var glyphixTextColor: PlatformColor? {
        get { self[GlyphixTextColor.self] }
        set { self[GlyphixTextColor.self] = newValue }
    }
}
