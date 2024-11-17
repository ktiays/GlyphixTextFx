//
//  Created by ktiays on 2024/11/14.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import QuartzCore

#if os(macOS)
import AppKit
#endif

public final class SharedDisplayLink: NSObject {

    public struct Context {
        /// The time interval between screen refresh updates.
        let duration: TimeInterval

        /// The time interval that represents when the last frame displayed.
        let timestamp: TimeInterval

        /// The time interval that represents when the next frame displays.
        let targetTimestamp: TimeInterval
    }

    public final class Target {

        fileprivate var isPaused: Bool = false
        fileprivate let handler: (Context) -> Void

        deinit {
            invalidate()
        }

        fileprivate init(handler: @escaping (Context) -> Void) {
            self.handler = handler
        }

        public func invalidate() {
            isPaused = true
        }
    }

    public static let shared = SharedDisplayLink()

    private var displayLink: CADisplayLink?
    fileprivate var targets: [Target] = []

    public func add(_ update: @escaping (Context) -> Void) -> Target {
        let target = Target(handler: update)
        targets.append(target)
        if displayLink == nil {
            #if os(macOS)
            guard
                let link = NSScreen.main?.displayLink(
                    target: self,
                    selector: #selector(handleDisplayLink(_:))
                )
            else {
                fatalError()
            }
            #else
            let link = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
            #endif
            link.preferredFrameRateRange = .init(minimum: 80, maximum: 120, preferred: 120)
            link.add(to: .current, forMode: .common)
            displayLink = link
        }
        return target
    }

    @objc
    private func handleDisplayLink(_ displayLink: CADisplayLink) {
        let context = Context(
            duration: displayLink.duration,
            timestamp: displayLink.timestamp,
            targetTimestamp: displayLink.targetTimestamp
        )

        var removeIndices: [Int] = []
        for (index, target) in targets.enumerated() {
            guard !target.isPaused else {
                removeIndices.append(index)
                continue
            }
            target.handler(context)
        }
        for index in removeIndices.reversed() {
            targets.remove(at: index)
        }

        if targets.isEmpty {
            displayLink.invalidate()
            self.displayLink = nil
        }
    }
}
