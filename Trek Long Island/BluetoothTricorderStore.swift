// Copyright Bryan Carroll. All rights reserved.

import CoreBluetooth
import Foundation

struct BluetoothTricorderDevice: Identifiable, Equatable {
    let id: UUID
    var name: String
    var rssi: Int
    var lastSeen: Date
    var serviceCount: Int
    var isConnectable: Bool

    var signalLevel: BluetoothSignalLevel {
        BluetoothSignalLevel(rssi: rssi)
    }

    var contributesToRoomEstimate: Bool {
        signalLevel != .trace
    }
}

enum BluetoothSignalLevel: String {
    case strong = "Strong"
    case moderate = "Moderate"
    case faint = "Faint"
    case trace = "Trace"

    init(rssi: Int) {
        if rssi >= -55 {
            self = .strong
        } else if rssi >= -70 {
            self = .moderate
        } else if rssi >= -85 {
            self = .faint
        } else {
            self = .trace
        }
    }

    var symbolName: String {
        switch self {
        case .strong: return "antenna.radiowaves.left.and.right"
        case .moderate: return "dot.radiowaves.left.and.right"
        case .faint: return "wave.3.right"
        case .trace: return "wave.1.right"
        }
    }

    var sortRank: Int {
        switch self {
        case .strong: return 4
        case .moderate: return 3
        case .faint: return 2
        case .trace: return 1
        }
    }
}

final class BluetoothTricorderStore: NSObject, ObservableObject {
    @Published private(set) var devices: [BluetoothTricorderDevice] = []
    @Published private(set) var isScanning = false
    @Published private(set) var statusMessage = "Bluetooth tricorder standing by."

    private var centralManager: CBCentralManager?
    private var pendingScanStart = false
    private let staleInterval: TimeInterval = 30

    // Authoritative set of recently seen devices, keyed by identifier. The
    // central manager delegate is bound to the main queue, so all access stays
    // on the main thread and needs no extra locking.
    private var tracked: [UUID: BluetoothTricorderDevice] = [:]
    // didDiscover fires once per received advertisement, and duplicate
    // reporting is enabled so RSSI stays fresh. In a crowded hall that is
    // hundreds of callbacks per second; sorting and publishing on each one
    // froze the UI. Instead we record the latest reading cheaply and flush a
    // sorted snapshot at most a few times per second.
    private var isFlushScheduled = false
    private let flushInterval: TimeInterval = 0.5
    // Hard cap on retained devices so memory use and per-flush sort cost stay
    // flat no matter how dense the environment is.
    private let maxTrackedDevices = 120

    var bluetoothStateLabel: String {
        switch centralManager?.state {
        case .unknown, nil: return "Initializing"
        case .resetting: return "Resetting"
        case .unsupported: return "Unsupported"
        case .unauthorized: return "Permission Needed"
        case .poweredOff: return "Bluetooth Off"
        case .poweredOn: return isScanning ? "Scanning" : "Ready"
        @unknown default: return "Unavailable"
        }
    }

    var strongestDevice: BluetoothTricorderDevice? {
        devices.max { $0.rssi < $1.rssi }
    }

    var roomEstimateSignalCount: Int {
        devices.filter(\.contributesToRoomEstimate).count
    }

    var estimatedPeopleInRoom: Int {
        let strongSignals = devices.filter { $0.signalLevel == .strong }.count
        let moderateSignals = devices.filter { $0.signalLevel == .moderate }.count
        let faintSignals = devices.filter { $0.signalLevel == .faint }.count
        let weightedEstimate = Double(strongSignals) + Double(moderateSignals) + (Double(faintSignals) * 0.5)
        return max(0, Int(weightedEstimate.rounded(.toNearestOrAwayFromZero)))
    }

    func startScanning() {
        if centralManager == nil {
            pendingScanStart = true
            centralManager = CBCentralManager(delegate: self, queue: .main)
            statusMessage = "Preparing Bluetooth sensors."
            return
        }

        guard centralManager?.state == .poweredOn else {
            pendingScanStart = true
            updateStatusForCurrentState()
            return
        }

        pendingScanStart = false
        tracked.removeAll()
        devices.removeAll()
        isScanning = true
        statusMessage = "Scanning for nearby Bluetooth signals."
        centralManager?.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
    }

    func stopScanning() {
        pendingScanStart = false
        centralManager?.stopScan()
        isScanning = false
        statusMessage = devices.isEmpty
            ? "Bluetooth tricorder standing by."
            : "Scan paused with \(devices.count) signal\(devices.count == 1 ? "" : "s") logged."
    }

    func pruneStaleDevices() {
        publishSnapshot()
    }

    private func updateStatusForCurrentState() {
        switch centralManager?.state {
        case .unknown, nil:
            statusMessage = "Preparing Bluetooth sensors."
        case .resetting:
            statusMessage = "Bluetooth is resetting. Try again in a moment."
        case .unsupported:
            statusMessage = "This device does not support Bluetooth scanning."
        case .unauthorized:
            statusMessage = "Allow Bluetooth access in Settings to scan nearby signals."
        case .poweredOff:
            statusMessage = "Turn on Bluetooth to use the tricorder scan."
        case .poweredOn:
            statusMessage = isScanning ? "Scanning for nearby Bluetooth signals." : "Bluetooth tricorder ready."
        @unknown default:
            statusMessage = "Bluetooth is unavailable right now."
        }
    }

    private func upsertDevice(
        peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi: NSNumber
    ) {
        let advertisedName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
        let isConnectable = advertisementData[CBAdvertisementDataIsConnectable] as? Bool ?? false
        let displayName = advertisedName ?? peripheral.name ?? "Unnamed Signal"
        // Record the latest reading cheaply (O(1)); the heavy prune/sort/publish
        // work is coalesced into flushTrackedDevices so a flood of advertisement
        // callbacks can't block the main thread.
        tracked[peripheral.identifier] = BluetoothTricorderDevice(
            id: peripheral.identifier,
            name: displayName,
            rssi: rssi.intValue,
            lastSeen: .now,
            serviceCount: serviceUUIDs.count,
            isConnectable: isConnectable
        )
        scheduleFlush()
    }

    private func scheduleFlush() {
        guard !isFlushScheduled else { return }
        isFlushScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + flushInterval) { [weak self] in
            self?.flushTrackedDevices()
        }
    }

    private func flushTrackedDevices() {
        isFlushScheduled = false
        publishSnapshot()
    }

    /// Prunes stale entries, enforces the device cap, sorts, and republishes the
    /// snapshot the UI observes. Safe to call repeatedly and keeps the backing
    /// store bounded so memory stays flat.
    private func publishSnapshot() {
        let cutoff = Date().addingTimeInterval(-staleInterval)
        var fresh = tracked.values
            .filter { $0.lastSeen >= cutoff }
            .sorted(by: deviceSort)
        if fresh.count > maxTrackedDevices {
            fresh = Array(fresh.prefix(maxTrackedDevices))
        }
        tracked = Dictionary(fresh.map { ($0.id, $0) }, uniquingKeysWith: { current, _ in current })
        devices = fresh

        guard isScanning else { return }
        statusMessage = fresh.isEmpty
            ? "Scanning for nearby Bluetooth signals."
            : "Tracking \(fresh.count) Bluetooth signal\(fresh.count == 1 ? "" : "s")."
    }

    private func deviceSort(_ lhs: BluetoothTricorderDevice, _ rhs: BluetoothTricorderDevice) -> Bool {
        if lhs.signalLevel.sortRank != rhs.signalLevel.sortRank {
            return lhs.signalLevel.sortRank > rhs.signalLevel.sortRank
        }
        if lhs.rssi != rhs.rssi {
            return lhs.rssi > rhs.rssi
        }
        return lhs.lastSeen > rhs.lastSeen
    }
}

extension BluetoothTricorderStore: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        updateStatusForCurrentState()
        if central.state == .poweredOn, pendingScanStart {
            startScanning()
        } else if central.state != .poweredOn {
            isScanning = false
            tracked.removeAll()
            devices.removeAll()
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        guard RSSI.intValue != 127 else { return }
        upsertDevice(peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI)
    }
}
