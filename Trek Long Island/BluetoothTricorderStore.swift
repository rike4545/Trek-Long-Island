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
        let cutoff = Date().addingTimeInterval(-staleInterval)
        let freshDevices = devices.filter { $0.lastSeen >= cutoff }
        guard freshDevices.count != devices.count else { return }
        devices = freshDevices.sorted(by: deviceSort)
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
        let reading = BluetoothTricorderDevice(
            id: peripheral.identifier,
            name: displayName,
            rssi: rssi.intValue,
            lastSeen: .now,
            serviceCount: serviceUUIDs.count,
            isConnectable: isConnectable
        )

        if let index = devices.firstIndex(where: { $0.id == reading.id }) {
            devices[index] = reading
        } else {
            devices.append(reading)
        }

        pruneStaleDevices()
        devices.sort(by: deviceSort)
        statusMessage = "Tracking \(devices.count) Bluetooth signal\(devices.count == 1 ? "" : "s")."
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
