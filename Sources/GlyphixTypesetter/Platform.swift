//
//  Created by Cyandev on 2025/3/4.
//  Copyright (c) 2025 ktiays. All rights reserved.
//

#if os(iOS)
import UIKit

public typealias PlatformFont = UIFont
#elseif os(macOS)
import AppKit

public typealias PlatformFont = NSFont
#endif

extension PlatformFont {

    public static var glyphixDefaultFont: PlatformFont {
        .systemFont(ofSize: PlatformFont.labelFontSize)
    }
}

extension CFRange {

    @usableFromInline
    static var zero: Self {
        .init(location: 0, length: 0)
    }
}

func + (_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
    .init(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}
