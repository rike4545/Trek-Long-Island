// Copyright Bryan Carroll. All rights reserved.
//
//  TappableTabWrapper.swift
//  Trek Long Island
//
//  Created by Bryan on 6/25/25.
//
import SwiftUI

struct TappableTabWrapper<Content: View>: View {
    let content: Content
    let tapHandler: () -> Void

    init(content: Content, tapHandler: @escaping () -> Void) {
        self.content = content
        self.tapHandler = tapHandler
    }

    var body: some View {
        ZStack {
            content
                .contentShape(Rectangle())
                .onTapGesture {
                    tapHandler()
                }
        }
    }
}
