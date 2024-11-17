//
//  Created by ktiays on 2024/11/12.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import Foundation
import QuartzCore

struct GaussianBlurFilter {
    
    static let inputRadiusKeyPath = "filters.gaussianBlur.inputRadius"
    
    let effect: NSObject

    var inputRadius: Double {
        get { effect.value(forKey: "inputRadius") as? Double ?? 0 }
        set { effect.setValue(newValue, forKey: "inputRadius") }
    }

    init?() {
        guard let effect = makeCAFilter(with: "gaussianBlur") else {
            return nil
        }
        self.effect = effect
    }
}
