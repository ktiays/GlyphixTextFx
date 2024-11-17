//
//  Created by ktiays on 2024/11/17.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

import Foundation
import QuartzCore

struct ColorAddFilter {
    
    static let inputColorKeyPath = "filters.colorAdd.inputColor"
    
    let effect: NSObject

    var inputColor: CGColor? {
        get {
            if let color = effect.value(forKey: "inputColor") {
                return (color as! CGColor)
            }
            return nil
        }
        set { effect.setValue(newValue, forKey: "inputColor") }
    }

    init?() {
        guard let effect = makeCAFilter(with: "colorAdd") else {
            return nil
        }
        self.effect = effect
    }
}
