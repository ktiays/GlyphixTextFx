//
//  NumericLabel.swift
//  NumericTransitionLabel
//
//  Created by 秋星桥 on 2025/1/6.
//

import NumericTransitionLabel
import SwiftUI

public struct NumericLabel {
    public var text: String
    public var font: PlatformFont = .preferredFont(forTextStyle: .body)
    public var textColor: PlatformColor = .numericLabelColor

    public init(text: String) {
        self.text = text
    }

    @MainActor public func updatePropertys(forView label: NumericTransitionLabel) {
        label.text = text
        label.font = font
        label.textColor = textColor
    }
}

#if canImport(UIKit)
    import UIKit

    extension NumericLabel: UIViewRepresentable {
        public func makeUIView(context _: Context) -> NumericTransitionLabel {
            NumericTransitionLabel()
        }

        public func updateUIView(_ uiView: NumericTransitionLabel, context _: Context) {
            updatePropertys(forView: uiView)
        }
    }
#else

    #if canImport(AppKit)

        import AppKit

        extension NumericLabel: NSViewRepresentable {
            public func makeNSView(context _: Context) -> NumericTransitionLabel {
                NumericTransitionLabel()
            }

            public func updateNSView(_ nsView: NumericTransitionLabel, context _: Context) {
                updatePropertys(forView: nsView)
            }
        }

    #endif

#endif
