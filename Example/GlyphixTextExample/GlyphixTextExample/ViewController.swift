//
//  Created by ktiays on 2025/3/7.
//  Copyright (c) 2025 ktiays. All rights reserved.
//

import Combine
import GlyphixTextFx
import SwiftUI
import UIKit

final class ViewController: UIViewController {

    private let labelFont: UIFont = .systemFont(ofSize: 36, weight: .bold)
    private lazy var glyphixLabel: GlyphixTextLabel = .init()
    private lazy var settingsPanelController: UIHostingController<SettingsPanel> = .init(rootView: SettingsPanel(configuration: self.labelConfiguration))
    private lazy var labelConfiguration: LabelConfiguration = .init()
    private lazy var segmentedControl: UISegmentedControl = .init()

    private var cancellables: Set<AnyCancellable> = .init()
    private var seconds: Int = 0
    private var clockRepresentation: String {
        let minutes = seconds / 60
        let seconds = self.seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        segmentedControl.insertSegment(withTitle: "Seconds", at: 0, animated: true)
        segmentedControl.insertSegment(withTitle: "Multi-lines Text", at: 1, animated: true)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(handleTextTypeChanged(_:)), for: .valueChanged)
        view.addSubview(segmentedControl)

        glyphixLabel.font = labelFont
        glyphixLabel.text = clockRepresentation
        view.addSubview(glyphixLabel)

        addChild(settingsPanelController)
        view.addSubview(settingsPanelController.view)
        settingsPanelController.didMove(toParent: self)
        settingsPanelController.view.layer.cornerRadius = 12
        settingsPanelController.view.layer.cornerCurve = .continuous
        settingsPanelController.view.clipsToBounds = true

        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [unowned self] _ in
                seconds += 1
                if segmentedControl.selectedSegmentIndex == 0 {
                    glyphixLabel.text = clockRepresentation
                }
            }
            .store(in: &cancellables)

        labelConfiguration.$fontSize
            .sink { [unowned self] fontSize in
                glyphixLabel.font = labelFont.withSize(CGFloat(fontSize))
            }
            .store(in: &cancellables)

        labelConfiguration.$textColor
            .sink { [unowned self] textColor in
                glyphixLabel.textColor = textColor
            }
            .store(in: &cancellables)

        labelConfiguration.$numberOfLines
            .sink { [unowned self] numberOfLines in
                glyphixLabel.numberOfLines = numberOfLines
            }
            .store(in: &cancellables)

        labelConfiguration.$countsDown
            .sink { [unowned self] countsDown in
                glyphixLabel.countsDown = countsDown
            }
            .store(in: &cancellables)

        labelConfiguration.$alignment
            .sink { [unowned self] alignment in
                glyphixLabel.textAlignment = alignment
            }
            .store(in: &cancellables)

        labelConfiguration.$isSmoothRenderingEnabled
            .sink { [unowned self] isSmoothRenderingEnabled in
                glyphixLabel.isSmoothRenderingEnabled = isSmoothRenderingEnabled
            }
            .store(in: &cancellables)
        
        labelConfiguration.$lineBreakMode
            .sink { [unowned self] lineBreakMode in
                glyphixLabel.lineBreakMode = lineBreakMode
            }
            .store(in: &cancellables)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let safeAreaInsets = view.safeAreaInsets

        let segmentedControlSize = segmentedControl.intrinsicContentSize
        segmentedControl.frame = .init(
            x: view.bounds.width / 2 - segmentedControlSize.width / 2,
            y: safeAreaInsets.top,
            width: segmentedControlSize.width,
            height: segmentedControlSize.height
        )

        glyphixLabel.frame = .init(
            x: 0,
            y: segmentedControl.frame.maxY + 8,
            width: view.bounds.width,
            height: view.bounds.height / 2 - segmentedControl.frame.maxY - 8
        )
        settingsPanelController.view.frame = .init(
            x: 0,
            y: view.bounds.height / 2,
            width: view.bounds.width,
            height: view.bounds.height / 2
        )
    }

    @objc
    private func handleTextTypeChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            glyphixLabel.text = clockRepresentation
        default:
            glyphixLabel.text = """
                Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.
                """
        }
    }
}
