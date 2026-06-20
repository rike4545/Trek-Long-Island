// Copyright Bryan Carroll. All rights reserved.
// PresaleWebView.swift

import SwiftUI

struct PresaleWebView: View {
    @Environment(\.openURL) private var openURL

    let url: URL

    var body: some View {
        ProgressView("Opening in browser...")
            .onAppear {
                openURL(url)
            }
    }
}
