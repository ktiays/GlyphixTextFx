//
//  Created by LiYanan2004 on 2025/3/14.
//  Copyright (c) 2025 ktiays. All rights reserved.
//

import SwiftUI

extension View {
    
    /// Sets whether label should disable animations.
    public func glyphixTextAnimationDisabled(_ disabled: Bool = true) -> some View {
        transformEnvironment(\.disablesGlyphixTextAnimations) { disablesAnimations in
            disablesAnimations = disabled
        }
    }
}

struct GlyphixTextAnimationsDisabled: EnvironmentKey {
    static var defaultValue: Bool = false
}

extension EnvironmentValues {
    var disablesGlyphixTextAnimations: Bool {
        get { self[GlyphixTextAnimationsDisabled.self] }
        set { self[GlyphixTextAnimationsDisabled.self] = newValue }
    }
}
