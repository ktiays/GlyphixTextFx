//
//  Created by Lakr233 on 2025/1/6.
//  Copyright (c) 2025 Lakr233. All rights reserved.
//

import NumericLabel
import SwiftUI

struct ContentView: View {
    @State var text = "Hello World"
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var body: some View {
        VStack {
            NumericLabel(text: text, font: .monospacedSystemFont(ofSize: 16, weight: .bold))
                .fixedSize()
        }
        .onReceive(timer) { _ in
            text = Date().formatted(date: .long, time: .complete)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
