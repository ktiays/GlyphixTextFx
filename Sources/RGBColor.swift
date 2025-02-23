//
//  Created by ktiays on 2024/11/17.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import Respring

struct RGBColor: VectorArithmetic {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    var platformColor: PlatformColor {
        .init(red: red, green: green, blue: blue, alpha: alpha)
    }

    static var zero: RGBColor {
        .init(red: 0, green: 0, blue: 0, alpha: 0)
    }

    static func + (_ lhs: Self, _ rhs: Self) -> Self {
        .init(
            red: lhs.red + rhs.red,
            green: lhs.green + rhs.green,
            blue: lhs.blue + rhs.blue,
            alpha: lhs.alpha + rhs.alpha
        )
    }

    static func - (_ lhs: Self, _ rhs: Self) -> Self {
        .init(
            red: lhs.red - rhs.red,
            green: lhs.green - rhs.green,
            blue: lhs.blue - rhs.blue,
            alpha: lhs.alpha - rhs.alpha
        )
    }

    mutating func scale(by rhs: Double) {
        red *= rhs
        green *= rhs
        blue *= rhs
        alpha *= rhs
    }

    var magnitudeSquared: Double {
        red * red + green * green + blue * blue + alpha * alpha
    }

    var cgColor: CGColor {
        .init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension RGBColor: ApproximatelyEqual {
    static func approximatelyEqual(_ lhs: RGBColor, _ rhs: RGBColor) -> Bool {
        CGFloat.approximatelyEqual(lhs.red, rhs.red)
            && CGFloat.approximatelyEqual(lhs.green, rhs.green)
            && CGFloat.approximatelyEqual(lhs.blue, rhs.blue)
            && CGFloat.approximatelyEqual(lhs.alpha, rhs.alpha)
    }
}
