//
//  Created by ktiays on 2024/11/17.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import QuartzCore
import Respring

struct AnimationState<T>: VectorArithmetic where T: VectorArithmetic {
    var value: T
    var velocity: T
    var target: T

    static var zero: Self {
        .init(value: .zero, velocity: .zero, target: .zero)
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        .init(
            value: lhs.value - rhs.value,
            velocity: lhs.velocity - rhs.velocity,
            target: lhs.target
        )
    }

    static func + (lhs: Self, rhs: Self) -> Self {
        .init(
            value: lhs.value + rhs.value,
            velocity: lhs.velocity + rhs.velocity,
            target: lhs.target
        )
    }

    mutating func scale(by rhs: Double) {
        value.scale(by: rhs)
        velocity.scale(by: rhs)
    }

    var magnitudeSquared: Double {
        value.magnitudeSquared + velocity.magnitudeSquared
    }
}

extension AnimationState where T: ApproximatelyEqual {
    var isCompleted: Bool {
        T.approximatelyEqual(value, target) && T.approximatelyEqual(velocity, .zero)
    }
}

extension CGRect: @retroactive AdditiveArithmetic {}
extension CGRect: @retroactive VectorArithmetic {
    public static func - (lhs: Self, rhs: Self) -> Self {
        .init(
            x: lhs.origin.x - rhs.origin.x,
            y: lhs.origin.y - rhs.origin.y,
            width: lhs.size.width - rhs.size.width,
            height: lhs.size.height - rhs.size.height
        )
    }

    public static func + (lhs: Self, rhs: Self) -> Self {
        .init(
            x: lhs.origin.x + rhs.origin.x,
            y: lhs.origin.y + rhs.origin.y,
            width: lhs.size.width + rhs.size.width,
            height: lhs.size.height + rhs.size.height
        )
    }

    public mutating func scale(by rhs: Double) {
        origin.x *= CGFloat(rhs)
        origin.y *= CGFloat(rhs)
        size.width *= CGFloat(rhs)
        size.height *= CGFloat(rhs)
    }

    public var magnitudeSquared: Double {
        origin.x * origin.x + origin.y * origin.y + size.width * size.width + size.height * size.height
    }
}

protocol ApproximatelyEqual {
    static func approximatelyEqual(_ lhs: Self, _ rhs: Self) -> Bool
}

private let threshold: Double = 0.01

extension CGRect: ApproximatelyEqual {
    static func approximatelyEqual(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
        abs(lhs.origin.x - rhs.origin.x) < threshold
            && abs(lhs.origin.y - rhs.origin.y) < threshold
            && abs(lhs.size.width - rhs.size.width) < threshold
            && abs(lhs.size.height - rhs.size.height) < threshold
    }
}

extension CGFloat: ApproximatelyEqual {
    static func approximatelyEqual(_ lhs: CGFloat, _ rhs: CGFloat) -> Bool {
        abs(lhs - rhs) < threshold
    }
}

extension Float: ApproximatelyEqual {
    static func approximatelyEqual(_ lhs: Float, _ rhs: Float) -> Bool {
        abs(lhs - rhs) < Float(threshold)
    }
}
