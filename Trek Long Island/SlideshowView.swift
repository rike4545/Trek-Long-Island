// Copyright Bryan Carroll. All rights reserved.
//
//  SlideshowView.swift
//  Trek Long Island
//
//  Created by Bryan on 6/8/25.
//


import SwiftUI

// MARK: - SlideshowView
public struct SlideshowView: View {
    public let images: [String]
    @State private var currentIndex = 0
    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    public init(images: [String]) {
        self.images = images
    }

    public var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(images.indices, id: \.self) { idx in
                Image(images[idx])
                    .resizable()
                    .scaledToFill()
                    .tag(idx)
            }
        }
        .tabViewStyle(PageTabViewStyle())
        .onReceive(timer) { _ in
            withAnimation {
                currentIndex = (currentIndex + 1) % images.count
            }
        }
    }
}

// MARK: - CountdownView
public struct CountdownView: View {
    public let to: Date
    @State private var now: Date = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    public init(to: Date) {
        self.to = to
    }

    public var body: some View {
        let diff = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: now, to: to)
        HStack(spacing: 12) {
            TimeBlock(value: diff.day ?? 0, unit: "D")
            TimeBlock(value: diff.hour ?? 0, unit: "H")
            TimeBlock(value: diff.minute ?? 0, unit: "M")
            TimeBlock(value: diff.second ?? 0, unit: "S")
        }
        .onReceive(timer) { self.now = $0 }
    }
}

// MARK: - TimeBlock
public struct TimeBlock: View {
    public let value: Int
    public let unit: String
    public init(value: Int, unit: String) {
        self.value = value
        self.unit = unit
    }
    public var body: some View {
        VStack {
            Text("\(value)")
                .font(.system(size: 36, weight: .bold))
            Text(unit)
                .font(.caption)
        }
        .frame(minWidth: 50)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).stroke())
    }
}

// MARK: - LCARSButtonStyle
public struct LCARSButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.accentColor.opacity(configuration.isPressed ? 0.6 : 1.0))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .foregroundColor(.white)
    }
}
