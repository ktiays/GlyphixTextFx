//
//  GlyphixText.Blur.swift
//  GlyphixTextFx
//
//  Created by LiYanan2004 on 2025/3/10.
//

import SwiftUI

extension View {
    /// Sets whether label should disable blur effect.
    public func glyphixLabelBlurEffectDisabled(_ disabled: Bool = true) -> some View {
        transformEnvironment(\.blursDuringTransition) { blurEffectEnabled in
            blurEffectEnabled = !disabled
        }
    }
}

struct GlyphixTextBlursDuringTransition: EnvironmentKey {
    static var defaultValue: Bool = true
}

extension EnvironmentValues {
    var blursDuringTransition: Bool {
        get { self[GlyphixTextBlursDuringTransition.self] }
        set { self[GlyphixTextBlursDuringTransition.self] = newValue }
    }
}
