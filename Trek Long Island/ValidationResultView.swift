// Copyright Bryan Carroll. All rights reserved.
//
//  ValidationResultView.swift
//  Trek Long Island
//
//  Created by Bryan on 6/23/25.
//


import SwiftUI

struct ValidationResultView: View {
    let scannedText: String
    let isPass: Bool

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: isPass ? "checkmark.seal.fill" : "xmark.octagon.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(isPass ? .green : .red)

            Text(isPass ? "PASS" : "FAIL")
                .font(.largeTitle.bold())
                .foregroundColor(isPass ? .green : .red)

            VStack(alignment: .leading, spacing: 8) {
                Text("Scanned:")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(scannedText)
                    .font(.body.monospaced())
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding()
    }
}
