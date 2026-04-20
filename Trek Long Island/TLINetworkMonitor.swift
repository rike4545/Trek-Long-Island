import Foundation
import Network
import FirebaseFirestore

@MainActor
final class TLINetworkMonitor: ObservableObject {
    static let shared = TLINetworkMonitor()

    @Published private(set) var isConnected = true
    @Published private(set) var isConstrained = false
    @Published private(set) var isExpensive = false

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "me.treklongisland.network-monitor")
    private var hasStarted = false

    private init() {}

    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        monitor.pathUpdateHandler = { path in
            Task { @MainActor in
                self.isConnected = path.status == .satisfied
                self.isConstrained = path.isConstrained
                self.isExpensive = path.isExpensive
                self.applyFirestoreTransportPolicy(isConnected: self.isConnected)
            }
        }

        monitor.start(queue: queue)
    }

    private func applyFirestoreTransportPolicy(isConnected: Bool) {
        let firestore = Firestore.firestore()
        if isConnected {
            firestore.enableNetwork { error in
                if let error {
                    print("❌ Firestore enable network error: \(error.localizedDescription)")
                }
            }
        } else {
            firestore.disableNetwork { error in
                if let error {
                    print("❌ Firestore disable network error: \(error.localizedDescription)")
                }
            }
        }
    }
}
