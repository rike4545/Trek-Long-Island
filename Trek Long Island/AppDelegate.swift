// Copyright Bryan Carroll. All rights reserved.
// AppDelegate.swift
import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseMessaging
import UserNotifications

final class TLIAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    private let pushTopic = TLIPushTopicManager.broadcastTopic
    private func trackAnalytics(
        name: String,
        domain: String,
        actor: String = "system",
        metadata: [String: String] = [:]
    ) {
        Task { @MainActor in
            TLIAnalyticsStore.shared.track(
                name: name,
                domain: domain,
                actor: actor,
                metadata: metadata
            )
        }
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        AppSecurity.enforceIfNeeded()
        TLIAdDefaults.register()
#if !targetEnvironment(simulator)
        ScreenProtectionManager.shared.start()
#endif
        verifyAdMobConfig()
        FirebaseApp.configure() // Ensure GoogleService-Info.plist is in the target
        configureFirestore()
        TLINetworkMonitor.shared.start()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            try? await Messaging.messaging().subscribe(toTopic: pushTopic)
            await TLIPushTopicManager.syncTopicsFromStoredAdminState()
            _ = await NotificationPermissionCoordinator.refreshRemoteNotificationRegistration()
        }
        trackAnalytics(name: "app_launch_completed", domain: "app")
        return true
    }

    private func configureFirestore() {
        let firestore = Firestore.firestore()
        let settings = firestore.settings
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: FirestoreCacheSizeUnlimited as NSNumber)
        firestore.settings = settings
    }

    private func verifyAdMobConfig() {
        guard !TLIAdAvailability.areAdsDisabledForCurrentTarget else { return }
        #if DEBUG
        let key = "GADApplicationIdentifier"
        let appID = Bundle.main.object(forInfoDictionaryKey: key) as? String
        if appID == nil || appID!.isEmpty {
            assertionFailure("Missing \(key) in Info.plist. AdMob will not initialize correctly.")
            print("Missing \(key) in Info.plist. AdMob will not initialize correctly.")
        }
        #endif
    }

    // APNs -> FCM
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        guard FirebaseApp.app() != nil else { return }
        Messaging.messaging().apnsToken = deviceToken
        trackAnalytics(name: "apns_registered", domain: "push")
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("APNs registration failed:", error)
        trackAnalytics(name: "apns_registration_failed", domain: "push", metadata: ["status": "failed"])
    }

    // Foreground notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        Messaging.messaging().appDidReceiveMessage(userInfo)
        Task { @MainActor in
            NotificationManager.shared.handleRemoteNotificationPayload(userInfo)
        }
        completionHandler([.banner, .sound, .badge])
    }

    // Notification tap handling
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        Messaging.messaging().appDidReceiveMessage(userInfo)
        Task { @MainActor in
            NotificationManager.shared.handleRemoteNotificationPayload(userInfo)
        }
        completionHandler()
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Messaging.messaging().appDidReceiveMessage(userInfo)
        Task { @MainActor in
            NotificationManager.shared.handleRemoteNotificationPayload(userInfo)
        }
        completionHandler(.newData)
    }

    // FCM token
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        #if DEBUG
        print("FCM token present:", fcmToken?.isEmpty == false)
        #endif
        Task {
            try? await Messaging.messaging().subscribe(toTopic: pushTopic)
            await TLIPushTopicManager.syncTopicsFromStoredAdminState()
        }
        trackAnalytics(
            name: "fcm_token_updated",
            domain: "push",
            metadata: ["token_present": (fcmToken?.isEmpty == false) ? "true" : "false"]
        )
    }

    // Keep the app full-screen across portrait/landscape on iPhone to prevent
    // compatibility-style letterboxing when device orientation changes.
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .all
        }
        return .allButUpsideDown
    }
}
