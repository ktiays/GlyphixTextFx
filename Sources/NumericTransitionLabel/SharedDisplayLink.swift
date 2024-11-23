//
//  Created by ktiays on 2024/11/14.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import QuartzCore

#if os(macOS)
import AppKit
#endif

#if DEBUG && os(iOS)
@_silgen_name("UIAnimationDragCoefficient")
func UIAnimationDragCoefficient() -> Float
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

    #if os(macOS)
    private var displayLink: CVDisplayLink?
    #else
    private var displayLink: CADisplayLink?
    #endif
    fileprivate var targets: [Target] = []

    public func add(_ update: @escaping (Context) -> Void) -> Target {
        let target = Target(handler: update)
        targets.append(target)
        if displayLink == nil {
            #if os(macOS)
            var link: CVDisplayLink?
            CVDisplayLinkCreateWithActiveCGDisplays(&link)
            let displayLinkContext = Unmanaged.passUnretained(self).toOpaque()
            CVDisplayLinkSetOutputCallback(link!, { displayLink, inNow, inOutputTime, flagsIn, flagsOut, displayLinkContext in
                let clockFrequency = CVGetHostClockFrequency()
                let context = Context(
                    duration: TimeInterval(inNow.pointee.videoRefreshPeriod) / TimeInterval(inNow.pointee.videoTimeScale),
                    timestamp: TimeInterval(inNow.pointee.hostTime) / clockFrequency,
                    targetTimestamp: TimeInterval(inOutputTime.pointee.hostTime) / clockFrequency
                )
                Task { @MainActor in
                    let selfPointer = Unmanaged<SharedDisplayLink>.fromOpaque(displayLinkContext!).takeUnretainedValue()
                    selfPointer.handleDisplayLink(with: context)
                }
                return kCVReturnSuccess
            }, displayLinkContext)
            CVDisplayLinkStart(link!)
            #else
            let link = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
            if #available(iOS 15.0, *) {
                link.preferredFrameRateRange = .init(minimum: 80, maximum: 120, preferred: 120)
            }
            link.add(to: .current, forMode: .common)
            #endif
            displayLink = link
        }
        return target
    }

    private func handleDisplayLink(with context: Context) {
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
            invalidateDisplayLink()
        }
    }

    private func invalidateDisplayLink() {
        #if os(macOS)
        if let displayLink {
            CVDisplayLinkStop(displayLink)
        }
        #else
        displayLink?.invalidate()
        #endif
        self.displayLink = nil
    }

    #if os(iOS)
    @objc private func handleDisplayLink(_ displayLink: CADisplayLink) {
        let context = Context(
            duration: displayLink.duration,
            timestamp: displayLink.timestamp,
            targetTimestamp: displayLink.targetTimestamp
        )
        handleDisplayLink(with: context)
    }
    #endif
}
