//
//  Created by ktiays on 2024/11/17.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import Foundation

func makeCAFilter(with name: String) -> NSObject? {
    let className = ["Filter", "CA"].reversed().joined()
    guard let caFilterClass = NSClassFromString(className) as? NSObject.Type else { return nil }

    let methodType = (@convention(c) (AnyClass, Selector, String) -> NSObject).self
    let selectorName = ["Name:", "With", "filter"].reversed().joined()
    let selector = NSSelectorFromString(selectorName)

    guard caFilterClass.responds(to: selector) else { return nil }

    let implementation = caFilterClass.method(for: selector)
    let method = unsafeBitCast(implementation, to: methodType)

    return method(caFilterClass, selector, name)
}
