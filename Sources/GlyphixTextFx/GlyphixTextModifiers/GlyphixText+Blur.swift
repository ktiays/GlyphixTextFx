//
//  Created by LiYanan2004 on 2025/3/10.
//  Copyright (c) 2025 ktiays. All rights reserved.
//

import SwiftUI

extension View {
    /// Sets whether label should disable blur effect.
    public func glyphixTextBlurEffectDisabled(_ disabled: Bool = true) -> some View {
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
