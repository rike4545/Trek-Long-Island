// Copyright Bryan Carroll. All rights reserved.
import SwiftUI

struct PasswordUnlockView: View {
    @Binding var isUnlocked: Bool
    @Binding var toastMessage: String
    @Binding var showToast: Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var input: String = ""

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark
                    ? [Color.black, Color.gray.opacity(0.8)]
                    : [Color("RisaTopBackground"), Color("RisaBottomBackground")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Admin Access")
                    .font(.largeTitle.bold())
                    .foregroundColor(colorScheme == .dark ? .white : .black)

                SecureField("Enter password", text: $input)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                Button("Unlock") {
                    if input == "1701" {
                        isUnlocked = true
                        toastMessage = "Admin mode unlocked"
                        showToast = true
                        dismiss()
                    } else {
                        toastMessage = "Incorrect password"
                        showToast = true
                        dismiss()
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .padding()
        }
    }
}
