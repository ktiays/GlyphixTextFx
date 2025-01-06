//
//  Created by Lakr233 on 2025/1/6.
//  Copyright (c) 2025 Lakr233. All rights reserved.
//

import NumericTransitionLabel
import SwiftUI

public struct NumericLabel {
    public let font: PlatformFont
    public var text: String
    public var textColor: PlatformColor = .numericLabelColor

    public init(text: String, font: PlatformFont = .preferredFont(forTextStyle: .body)) {
        self.text = text
        self.font = font
    }

    @MainActor public func createView() -> NumericTransitionLabel {
        NumericTransitionLabel(font: font)
    }

    @MainActor public func updatePropertys(forView label: NumericTransitionLabel) {
        label.text = text
        label.textColor = textColor
    }
}

#if canImport(UIKit)
    import UIKit

    extension NumericLabel: UIViewRepresentable {
        public func makeUIView(context _: Context) -> NumericTransitionLabel {
            createView()
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
                createView()
            }

            public func updateNSView(_ nsView: NumericTransitionLabel, context _: Context) {
                updatePropertys(forView: nsView)
            }
        }

    #endif

#endif
