// Copyright Bryan Carroll. All rights reserved.
import Foundation
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

enum NotificationPermissionCoordinator {
    static func requestAuthorizationIfNeeded() async -> UNAuthorizationStatus {
        do {
            _ = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            // Intentionally ignored; status check below reflects current state.
        }
        return await refreshRemoteNotificationRegistration()
    }

    static func refreshRemoteNotificationRegistration() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        if isAuthorizedLike(settings.authorizationStatus), hasAPNsEntitlement() {
            #if canImport(UIKit) && !targetEnvironment(simulator)
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
            #endif
        }
        return settings.authorizationStatus
    }

    static func isAuthorizedLike(_ status: UNAuthorizationStatus) -> Bool {
        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }

    private static func hasAPNsEntitlement() -> Bool {
        #if canImport(UIKit) && !targetEnvironment(simulator)
        // Entitlement introspection APIs are not universally available across Apple SDKs.
        // On real iOS devices, allow APNs registration and let the OS enforce entitlements.
        return true
        #else
        return false
        #endif
    }
}
