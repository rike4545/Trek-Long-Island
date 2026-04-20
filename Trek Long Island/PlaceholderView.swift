// Copyright Bryan Carroll. All rights reserved.
//
//  PlaceholderView.swift
//  Trek Long Island
//
//  Created by Bryan on 6/16/25.
//


import SwiftUI

struct PlaceholderView: View {
    let title: String

    var body: some View {
        ZStack {
            Color(red: 0.84, green: 1.0, blue: 0.0) // Lime Yellow
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(Color(red: 1.0, green: 0.3, blue: 0.7)) // Hot Pink

                Text("Command Authorization Required.")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)

                Text("\(title) is still with Away Team Leadership. \nThanks for your patience.")
                    .font(.body)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
        }
    }
}
