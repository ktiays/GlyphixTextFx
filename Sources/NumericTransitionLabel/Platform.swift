//
//  Created by ktiays on 2024/11/16.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

#if os(macOS)
import AppKit

public typealias PlatformFont = NSFont
public typealias PlatformColor = NSColor
#else
import UIKit

public typealias PlatformFont = UIFont
public typealias PlatformColor = UIColor
#endif
