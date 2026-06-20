// Copyright Bryan Carroll. All rights reserved.
//
//  BadgeView.swift
//  Trek Long Island
//
//  Created by Bryan on 6/23/25.
//
import SwiftUI

struct BadgeView: View {
    var count: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.red)
                .frame(width: 16, height: 16)

            if count < 10 {
                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(.white)
            } else {
                Text("9+")
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
}
