// Copyright Bryan Carroll. All rights reserved.
import Foundation
import Combine

class UserManager: ObservableObject {
    static let shared = UserManager()

    @Published var currentRole: String = "general"

    private init() {}
}
