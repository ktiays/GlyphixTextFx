//
//  Created by ktiays on 2024/11/16.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

#if canImport(UIKit)
    @_exported import UIKit

    public typealias PlatformFont = UIFont
    public typealias PlatformColor = UIColor
    public typealias PlatformView = UIView
    typealias Appearance = UITraitCollection

    public extension PlatformColor {
        static var numericLabelColor: PlatformColor = .label
    }

    extension Appearance {
        static var initialValue = Appearance.current
    }

    extension PlatformView {
        var animationScalingFactor: CGFloat {
            window?.screen.scale ?? 2
        }
    }

    extension CGContext {
        func draw(_ callback: () -> Void) {
            UIGraphicsPushContext(self)
            callback()
            UIGraphicsPopContext()
        }
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

#else

    #if canImport(AppKit)

        @_exported import AppKit

        public typealias PlatformFont = NSFont
        public typealias PlatformColor = NSColor
        public typealias PlatformView = NSView
        typealias Appearance = NSAppearance
        public extension PlatformColor {
            static var numericLabelColor: PlatformColor = .labelColor
        }

        extension Appearance {
            static var initialValue = Appearance.currentDrawing()
        }

        extension PlatformView {
            var animationScalingFactor: CGFloat {
                window?.screen?.backingScaleFactor ?? 1
            }
        }

        extension CGContext {
            func draw(_ callback: () -> Void) {
                let context = NSGraphicsContext(cgContext: self, flipped: true)
                NSGraphicsContext.current = context
                callback()
                NSGraphicsContext.current = nil
            }
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

    #else
        #error("Unsupported platform")
    #endif
#endif

#if DEBUG && os(iOS)
    @_silgen_name("UIAnimationDragCoefficient") func UIAnimationDragCoefficient() -> Float
#endif
