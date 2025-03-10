# GlyphixTextFx

A label component that provides content transition animations like SwiftUI's `numericText`.

> [!NOTE]
> The library originally named `NumericTransitionLabel` is now renamed to `GlyphixTextFx`.

## Features

- Per-character smooth animations when text changes
- Customizable transition direction (upward or downward)
- Multiple text alignment options (left, center, right)
- Multi-line text support with configurable line break modes
- Optional blur effects for enhanced visual transitions
- Smooth rendering option for improved text appearance
- Works with both UIKit/AppKit and SwiftUI

## Preview

https://github.com/user-attachments/assets/c180fd39-870b-4d0e-be37-73d9053f125b

You can find the example project in the `Example` directory.

## Supported Platforms

- iOS 13.0+
- macOS 11.0+

## Installation

### Swift Package Manager

Add GlyphixTextFx to your Swift package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/ktiays/GlyphixTextFx.git", from: "2.0.0")
]
```

## Usage

### UIKit/AppKit

```swift
import GlyphixTextFx
import UIKit

let label = GlyphixTextLabel()
label.font = .systemFont(ofSize: 36, weight: .bold)
label.textColor = .systemBlue
label.countsDown = true
label.text = "1234567890"
```

### SwiftUI

```swift
import SwiftUI
import GlyphixTextFx

struct ContentView: View {
    var body: some View {
        GlyphixText("1234567890")
            .font(UIFont.systemFont(ofSize: 36, weight: .bold))
            .textColor(.systemBlue)
    }
}
```

See the component documentation comments for other related usage details.

## Performance Considerations

> [!IMPORTANT]
> The blur effect can significantly impact performance, especially with longer text. It's recommended to disable blur effects for better performance when displaying large amounts of text:

```swift
// Disable blur for better performance with long text.
label.isBlurEffectEnabled = false
```

## License
GlyphixTextFx is available under the MIT license. See the LICENSE file for more info.
