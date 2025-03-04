//
//  Created by ktiays on 2024/11/16.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

#if os(iOS)
@_exported import UIKit

public typealias PlatformColor = UIColor
public typealias PlatformView = UIView
typealias Appearance = UITraitCollection

extension PlatformColor {
    public static var glyphixDefaultColor: PlatformColor {
        .label
    }
}

extension Appearance {
    static var initialValue = Appearance.current
}

extension PlatformColor {
    func resolvedRgbColor(with traitCollection: UITraitCollection) -> RGBColor {
        let cgColor = resolvedColor(with: traitCollection).cgColor.converted(
            to: CGColorSpaceCreateDeviceRGB(),
            intent: .defaultIntent,
            options: nil
        )!
        let components = cgColor.components!
        return .init(
            red: Double(components[0]),
            green: Double(components[1]),
            blue: Double(components[2]),
            alpha: Double(cgColor.alpha)
        )
    }
}

#elseif os(macOS)

@_exported import AppKit

public typealias PlatformColor = NSColor
public typealias PlatformView = NSView

typealias Appearance = NSAppearance

extension PlatformColor {
    public static var glyphixDefaultColor: PlatformColor {
        .labelColor
    }
}

extension Appearance {
    static var initialValue = Appearance.currentDrawing()
}

extension PlatformColor {
    func resolvedRgbColor(with appearance: NSAppearance) -> RGBColor {
        var color: RGBColor!
        appearance.performAsCurrentDrawingAppearance {
            let deviceColor = self.usingColorSpace(.genericRGB)!
            color = .init(
                red: Double(deviceColor.redComponent),
                green: Double(deviceColor.greenComponent),
                blue: Double(deviceColor.blueComponent),
                alpha: Double(deviceColor.alphaComponent)
            )
        }
        return color
    }
}
#endif

extension CFRange {
    static var zero: Self {
        .init(location: 0, length: 0)
    }
}

extension CGSize {
    
    static var greatestFiniteMagnitude: Self {
        .init(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    }
}

func ceil(_ size: CGSize) -> CGSize {
    .init(width: ceil(size.width), height: ceil(size.height))
}

#if DEBUG && os(iOS)
@_silgen_name("UIAnimationDragCoefficient") func UIAnimationDragCoefficient() -> Float
#endif
