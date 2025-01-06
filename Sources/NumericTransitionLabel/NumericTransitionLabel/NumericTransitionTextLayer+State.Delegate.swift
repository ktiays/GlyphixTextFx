//
//  Created by Lakr233 on 2025/1/6.
//  Copyright (c) 2025 Lakr233. All rights reserved.
//

extension NumericTransitionTextLayer.State {
    protocol Delegate: AnyObject {
        func updateFrame(with state: NumericTransitionTextLayer.State)
    }
}

extension NumericTransitionTextLayer: NumericTransitionTextLayer.State.Delegate {
    func updateFrame(with state: State) {
        guard let textBounds = state.textBounds else {
            return
        }

        let anchor: CGPoint =
            switch alignment {
            case .left:
                .init(x: 0, y: bounds.midY)
            case .center:
                .init(x: bounds.midX, y: bounds.midY)
            case .right:
                .init(x: bounds.maxX, y: bounds.midY)
            }

        let layer = state.layer
        let frame = state.presentationFrame
        let transform = layer.transform
        layer.transform = CATransform3DIdentity
        let targetFrame = frame.offsetBy(dx: anchor.x, dy: anchor.y - textBounds.midY)
        let currentSize = layer.bounds.size
        if currentSize != frame.size {
            layer.frame = targetFrame
        } else {
            layer.position = .init(x: targetFrame.midX, y: targetFrame.midY)
        }
        layer.transform = transform
    }
}
