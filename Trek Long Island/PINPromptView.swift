// Copyright Bryan Carroll. All rights reserved.
// PINPromptView.swift

import SwiftUI

struct PINPromptView: View {
    var onComplete: (String) -> Void

    @State private var pin: String = ""
    @State private var isProcessing = false
    @State private var showErrorBanner = false
    @FocusState private var pinFieldIsFocused: Bool

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "lock.shield")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .foregroundColor(.accentColor)

                Text("Admin Access")
                    .font(.title2.bold())
                    .foregroundColor(.primary)

                SecureField("Enter PIN", text: $pin)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                    .focused($pinFieldIsFocused)
                    .submitLabel(.go)
                    .onSubmit {
                        attemptUnlock()
                    }

                Button(action: {
                    attemptUnlock()
                }) {
                    Text("Unlock")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .frame(width: 200)
                .disabled(isProcessing)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 8)
            .padding()
            .onAppear {
                pinFieldIsFocused = true
            }

            if showErrorBanner {
                VStack {
                    Spacer()
                    Text("Invalid PIN. Access Denied.")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 40)
                }
            }
        }
    }

    private func attemptUnlock() {
        guard !isProcessing else { return }
        isProcessing = true
        pinFieldIsFocused = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if AdminPinStore.shared.role(for: pin) != .none {
                onComplete(pin)
            } else {
                showErrorBanner = true
                pin = ""
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation {
                        showErrorBanner = false
                    }
                    pinFieldIsFocused = true
                }
            }
            isProcessing = false
        }
    }
}
