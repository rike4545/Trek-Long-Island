// Copyright Bryan Carroll. All rights reserved.

import Foundation
import FirebaseFirestore
import UserNotifications

@MainActor
final class AppUpdateMonitor: ObservableObject {
    static let shared = AppUpdateMonitor()

    private struct LookupResponse: Decodable {
        let resultCount: Int
        let results: [LookupResult]
    }

    private struct LookupResult: Decodable {
        let version: String?
        let trackViewUrl: String?
    }

    private struct HostedUpdateConfig {
        let latestVersion: String
        let latestBuild: String?
        let storeURL: URL?
        let message: String?

        func isNewerThanCurrentVersionOrBuild(currentVersion: String, currentBuild: String) -> Bool {
            if latestVersion.isNewerVersion(than: currentVersion) {
                return true
            }

            guard latestVersion.versionMatches(currentVersion),
                  let latestBuild,
                  latestBuild.isNewerBuild(than: currentBuild) else {
                return false
            }

            return true
        }
    }

    private let lastCheckKey = "TLI.AppUpdate.lastCheckAt"
    private let lastNotifiedVersionKey = "TLI.AppUpdate.lastNotifiedVersion"
    private let minimumCheckInterval: TimeInterval = 6 * 60 * 60

    private var isChecking = false

    private init() {}

    func checkForAvailableUpdate(force: Bool = false) async {
        guard !isChecking else { return }
        guard force || shouldCheckNow else { return }
        guard let bundleID = Bundle.main.bundleIdentifier, !bundleID.isEmpty else { return }

        isChecking = true
        defer { isChecking = false }

        UserDefaults.standard.set(Date(), forKey: lastCheckKey)

        if let hosted = await fetchHostedUpdateConfig(),
           hosted.isNewerThanCurrentVersionOrBuild(
            currentVersion: Self.currentVersion,
            currentBuild: Self.currentBuild
           ) {
            let versionKey = "hosted-\(hosted.latestVersion)-\(hosted.latestBuild ?? "0")"
            guard UserDefaults.standard.string(forKey: lastNotifiedVersionKey) != versionKey else { return }

            NotificationManager.shared.showSoftwareUpdateNotification(
                latestVersion: hosted.latestVersion,
                latestBuild: hosted.latestBuild,
                currentVersion: Self.currentVersion,
                currentBuild: Self.currentBuild,
                storeURL: hosted.storeURL,
                customMessage: hosted.message
            )
            await scheduleLocalNotificationIfAllowed(latestVersion: hosted.latestVersion)
            UserDefaults.standard.set(versionKey, forKey: lastNotifiedVersionKey)
            return
        }

        var components = URLComponents(string: "https://itunes.apple.com/lookup")
        components?.queryItems = [
            URLQueryItem(name: "bundleId", value: bundleID),
            URLQueryItem(name: "country", value: Locale.current.region?.identifier ?? "US")
        ]

        guard let url = components?.url else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(LookupResponse.self, from: data)
            guard response.resultCount > 0, let result = response.results.first else { return }
            guard let latestVersion = result.version?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !latestVersion.isEmpty,
                  latestVersion.isNewerVersion(than: Self.currentVersion) else {
                return
            }

            let versionKey = "app-store-\(latestVersion)"
            guard UserDefaults.standard.string(forKey: lastNotifiedVersionKey) != versionKey else { return }

            let storeURL = result.trackViewUrl.flatMap(URL.init(string:))
            NotificationManager.shared.showSoftwareUpdateNotification(
                latestVersion: latestVersion,
                latestBuild: nil,
                currentVersion: Self.currentVersion,
                currentBuild: Self.currentBuild,
                storeURL: storeURL,
                customMessage: nil
            )
            await scheduleLocalNotificationIfAllowed(latestVersion: latestVersion)
            UserDefaults.standard.set(versionKey, forKey: lastNotifiedVersionKey)
        } catch {
            // Update checks should never block the attendee experience.
        }
    }

    private var shouldCheckNow: Bool {
        guard let lastCheck = UserDefaults.standard.object(forKey: lastCheckKey) as? Date else {
            return true
        }
        return Date().timeIntervalSince(lastCheck) >= minimumCheckInterval
    }

    private func fetchHostedUpdateConfig() async -> HostedUpdateConfig? {
        await withCheckedContinuation { continuation in
            Firestore.firestore()
                .collection("conventions")
                .document(NotificationManager.shared.conventionID)
                .collection("app_config")
                .document("software_update")
                .getDocument { snapshot, _ in
                    guard let data = snapshot?.data() else {
                        continuation.resume(returning: nil)
                        return
                    }

                    if let isEnabled = data["isEnabled"] as? Bool, !isEnabled {
                        continuation.resume(returning: nil)
                        return
                    }

                    guard let latestVersion = Self.trimmed(data["latestVersion"] as? String) else {
                        continuation.resume(returning: nil)
                        return
                    }

                    let latestBuild =
                        Self.trimmed(data["latestBuild"] as? String) ??
                        (data["latestBuild"] as? Int).map(String.init)

                    let storeURL =
                        Self.trimmed(data["appStoreURL"] as? String).flatMap(URL.init(string:)) ??
                        Self.trimmed(data["storeURL"] as? String).flatMap(URL.init(string:))

                    continuation.resume(
                        returning: HostedUpdateConfig(
                            latestVersion: latestVersion,
                            latestBuild: latestBuild,
                            storeURL: storeURL,
                            message: Self.trimmed(data["message"] as? String)
                        )
                    )
                }
        }
    }

    private func scheduleLocalNotificationIfAllowed(latestVersion: String) async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard NotificationPermissionCoordinator.isAuthorizedLike(settings.authorizationStatus) else { return }

        let content = UNMutableNotificationContent()
        content.title = "App Update Available"
        content.body = "A newer Trek Long Island app version is available."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "tli-software-update-\(latestVersion)",
            content: content,
            trigger: nil
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    private static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    private static var currentBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }

    private nonisolated static func trimmed(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}

private extension String {
    func isNewerVersion(than other: String) -> Bool {
        let lhs = versionComponents
        let rhs = other.versionComponents
        let count = max(lhs.count, rhs.count)

        for index in 0..<count {
            let left = index < lhs.count ? lhs[index] : 0
            let right = index < rhs.count ? rhs[index] : 0
            if left != right {
                return left > right
            }
        }

        return false
    }

    func versionMatches(_ other: String) -> Bool {
        versionComponents == other.versionComponents
    }

    func isNewerBuild(than other: String) -> Bool {
        let lhs = Int(trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let rhs = Int(other.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        return lhs > rhs
    }

    private var versionComponents: [Int] {
        split { !$0.isNumber }
            .map { Int($0) ?? 0 }
    }
}
