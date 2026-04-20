// Copyright Bryan Carroll. All rights reserved.
//  PresaleView.swift
//  Trek Long Island
//
//  Tickets info screen (no in-app purchase actions):
//  • Promo image only
//  • Uses your themed background color
//
//  NOTE: Ensure an asset named "unnamed" exists in Assets.xcassets.

import SwiftUI

struct PresaleView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Ticket purchase buttons are not available in the app.")
                    .font(.headline)
                    .padding(.top)

                Image("Trek Long Island Black")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 340)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(radius: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(.separator.opacity(0.2))
                    )
            }
            .frame(maxWidth: 560)
            .padding()
        }
        .background(Color("PrimaryBackground").ignoresSafeArea())
        .navigationTitle("Tickets")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { PresaleView() }
}
