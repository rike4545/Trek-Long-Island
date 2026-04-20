// Copyright Bryan Carroll. All rights reserved.
//
//  QRCodeView.swift
//  Trek Long Island
//
//  QR tools + operator ticket workflow
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

@MainActor
struct QRCodeView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.openURL) private var openURL
    @ObservedObject private var notifications = NotificationManager.shared
    @ObservedObject private var ticketStore = TicketOpsStore.shared

    private let qrPayload = "https://www.treklongisland.com"

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    @State private var didCopy = false
    @State private var operatorName: String = ""
    @State private var operatorOrderNumber: String = ""
    @State private var operatorTicketCount: Int = 1
    @State private var selectedOrderForQR: String = ""
    @State private var manualScanPayload: String = ""
    @State private var scanResultMessage: String?
    @State private var scanResultPass: Bool = false
    @State private var showScanner: Bool = false
    @State private var didCopyTicketPayload: Bool = false

    private var isOperator: Bool {
        notifications.isStaffUnlocked
    }

    private var generatedTicketPayload: String? {
        guard ticketStore.isTicketGenerationEnabled else { return nil }
        return ticketStore.payloadString(forOrderNumber: selectedOrderForQR)
    }

    private var selectedOrderRecord: TicketOrderRecord? {
        let selectedKey = selectedOrderForQR.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !selectedKey.isEmpty else { return nil }
        return ticketStore.orders.first(where: { $0.orderNumber.uppercased() == selectedKey })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                TLITheme.backgroundGradient(scheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        header
                        publicShareCard

                        if isOperator {
                            operatorDashboardCard
                            operatorControlsCard
                            tallyCard
                            ordersCard
                        } else {
                            operatorAccessHintCard
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .frame(maxWidth: 780)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("QR Tools")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showScanner) {
                TicketQRScannerSheet { payload in
                    handleScannedPayload(payload)
                }
            }
            .onAppear {
                seedOrderSelection()
            }
            .onChange(of: ticketStore.orders) { _, _ in
                seedOrderSelection()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("QR Tools")
                .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                .foregroundStyle(RisaTheme.textPrimary(scheme))

            Text("Public sharing and operator ticket validation in one place.")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(RisaTheme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var publicShareCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Public Share")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(RisaTheme.textPrimary(scheme))

            HStack(alignment: .top, spacing: 16) {
                qrImageForString(qrPayload)
                    .interpolation(.none)
                    .antialiased(false)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white)
                    )

                VStack(alignment: .leading, spacing: 10) {
                    Text("Scan to open treklongisland.com")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RisaTheme.textPrimary(scheme))

                    HStack(spacing: 10) {
                        Button {
                            openURL(URL(string: qrPayload)!)
                        } label: {
                            Label("Open", systemImage: "safari.fill")
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            copyToClipboard()
                        } label: {
                            Label(didCopy ? "Copied" : "Copy", systemImage: didCopy ? "checkmark.circle.fill" : "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                    }

                    Text(qrPayload)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .background(glassCardBackground)
    }

    private var operatorControlsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Operator Ticket Controls")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(RisaTheme.textPrimary(scheme))

            Toggle("Enable ticket QR generation", isOn: Binding(
                get: { ticketStore.isTicketGenerationEnabled },
                set: { ticketStore.setTicketGenerationEnabled($0) }
            ))

            Toggle("Enable ticket scanning", isOn: Binding(
                get: { ticketStore.isTicketScanningEnabled },
                set: { ticketStore.setTicketScanningEnabled($0) }
            ))

            Divider()

            Text("Order Information")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RisaTheme.textPrimary(scheme))

            TextField("Name", text: $operatorName)
                .textInputAutocapitalization(.words)
                .textFieldStyle(.roundedBorder)

            TextField("Order Number", text: $operatorOrderNumber)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled(true)
                .textFieldStyle(.roundedBorder)

            Stepper("Number of Tickets: \(operatorTicketCount)", value: $operatorTicketCount, in: 1...20)

            Button {
                ticketStore.upsertOrder(
                    name: operatorName,
                    ticketCount: operatorTicketCount,
                    orderNumber: operatorOrderNumber
                )
                if !operatorOrderNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    selectedOrderForQR = operatorOrderNumber.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                }
                operatorName = ""
                operatorOrderNumber = ""
                operatorTicketCount = 1
            } label: {
                Label("Save Order", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            if !ticketStore.orders.isEmpty {
                Picker("Generate QR for", selection: $selectedOrderForQR) {
                    ForEach(ticketStore.orders) { order in
                        Text("\(order.orderNumber) • \(order.name)")
                            .tag(order.orderNumber)
                    }
                }
            }

            if let payload = generatedTicketPayload, let order = selectedOrderRecord {
                generatedTicketQRCodeCard(payload: payload, order: order)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            Text("Ticket Scanning")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RisaTheme.textPrimary(scheme))

            HStack(spacing: 10) {
                Button {
                    showScanner = true
                } label: {
                    Label("Scan with Camera", systemImage: "qrcode.viewfinder")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!ticketStore.isTicketScanningEnabled)

                Button {
                    if !manualScanPayload.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        handleScannedPayload(manualScanPayload)
                        manualScanPayload = ""
                    }
                } label: {
                    Label("Validate Manual", systemImage: "checkmark.seal")
                }
                .buttonStyle(.bordered)
                .disabled(!ticketStore.isTicketScanningEnabled)
            }

            TextField("Paste scanned QR payload", text: $manualScanPayload, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)

            if let scanResultMessage {
                Label(scanResultMessage, systemImage: scanResultPass ? "checkmark.circle.fill" : "xmark.octagon.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(scanResultPass ? .green : .red)
            } else {
                Text("Accepted scans increment tally by order. Over-scans fail once purchased count is reached.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(glassCardBackground)
    }

    private var operatorDashboardCard: some View {
        let summary = ticketStore.tally
        let hasOrders = summary.orderCount > 0
        let scanProgress = summary.totalPurchased == 0
            ? "0%"
            : "\(Int((Double(summary.totalScanned) / Double(max(1, summary.totalPurchased))) * 100.0))%"

        return VStack(alignment: .leading, spacing: 12) {
            Text("Operator Dashboard")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(RisaTheme.textPrimary(scheme))

            HStack(spacing: 12) {
                tallyPill(title: "Generation", value: ticketStore.isTicketGenerationEnabled ? "On" : "Off")
                tallyPill(title: "Scanning", value: ticketStore.isTicketScanningEnabled ? "On" : "Off")
                tallyPill(title: "Coverage", value: scanProgress)
            }

            if !hasOrders {
                Text("No orders loaded. Add at least one order to start generating and validating ticket QR codes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if !ticketStore.isTicketScanningEnabled || !ticketStore.isTicketGenerationEnabled {
                Text("Attention: one or more ticket operator controls are disabled.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
            } else if summary.totalRemaining == 0 {
                Text("All loaded tickets are fully scanned.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            } else {
                Text("\(summary.totalRemaining) ticket(s) remaining to scan.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if let lastSquareImportMessage = ticketStore.lastSquareImportMessage {
                Text(lastSquareImportMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(glassCardBackground)
    }

    private var tallyCard: some View {
        let summary = ticketStore.tally
        return VStack(alignment: .leading, spacing: 10) {
            Text("Ticket Tallies")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(RisaTheme.textPrimary(scheme))

            HStack(spacing: 12) {
                tallyPill(title: "Orders", value: "\(summary.orderCount)")
                tallyPill(title: "Purchased", value: "\(summary.totalPurchased)")
                tallyPill(title: "Scanned", value: "\(summary.totalScanned)")
                tallyPill(title: "Remaining", value: "\(summary.totalRemaining)")
            }
        }
        .padding(16)
        .background(glassCardBackground)
    }

    private var ordersCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Order Records")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(RisaTheme.textPrimary(scheme))

            if ticketStore.orders.isEmpty {
                Text("No order records yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(ticketStore.orders) { order in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(order.name)
                                .font(.subheadline.weight(.semibold))
                            Spacer(minLength: 8)
                            HStack(spacing: 8) {
                                if order.source.lowercased() == "square" {
                                    Text("Square")
                                        .font(.caption2.weight(.bold))
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(TLITheme.accentSoft(scheme)))
                                }
                                Text(order.orderNumber)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text("Tickets: \(order.ticketCount) • Scanned: \(order.scannedCount) • Remaining: \(max(0, order.ticketCount - order.scannedCount))")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            Text(order.lastScannedAt == nil
                                 ? "No scans yet"
                                 : "Last scanned \(order.lastScannedAt!, style: .relative)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer(minLength: 8)
                            Button("Delete", role: .destructive) {
                                ticketStore.removeOrder(id: order.id)
                            }
                            .font(.caption.weight(.semibold))
                        }
                    }
                    .padding(.vertical, 6)
                    if order.id != ticketStore.orders.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .background(glassCardBackground)
    }

    private var operatorAccessHintCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Operator Ticket Mode")
                .font(.headline)
                .foregroundStyle(RisaTheme.textPrimary(scheme))
            Text("Unlock a staff/operator role to enable ticket QR generation and ticket scanning.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(glassCardBackground)
    }

    private var glassCardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(RisaTheme.cardBorder(scheme), lineWidth: 1)
            )
    }

    private func generatedTicketQRCodeCard(payload: String, order: TicketOrderRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Ticket QR Ready", systemImage: "checkmark.seal.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                    Text(order.name)
                        .font(.headline)
                        .foregroundStyle(RisaTheme.textPrimary(scheme))
                    Text("Order \(order.orderNumber) • \(order.ticketCount) ticket(s)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Text(TicketQRPayload.issuerName)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            HStack(alignment: .center, spacing: 14) {
                qrImageForString(payload)
                    .interpolation(.none)
                    .antialiased(false)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 216, height: 216)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white, Color.white.opacity(0.94)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(scheme == .dark ? 0.34 : 0.16), radius: 14, y: 8)

                VStack(alignment: .leading, spacing: 10) {
                    Label("Present at check-in", systemImage: "person.crop.rectangle.badge.checkmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Button {
                        #if canImport(UIKit)
                        UIPasteboard.general.string = payload
                        #endif
                        withAnimation(.easeInOut(duration: 0.16)) {
                            didCopyTicketPayload = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            withAnimation(.easeInOut(duration: 0.16)) {
                                didCopyTicketPayload = false
                            }
                        }
                    } label: {
                        Label(didCopyTicketPayload ? "Payload Copied" : "Copy Ticket Payload", systemImage: didCopyTicketPayload ? "checkmark.circle.fill" : "doc.on.doc.fill")
                    }
                    .buttonStyle(.borderedProminent)

                    Text("Payload is issuer-locked to Trek Long Island Corp.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.cyan.opacity(scheme == .dark ? 0.22 : 0.11),
                            Color.blue.opacity(scheme == .dark ? 0.16 : 0.07)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.cyan.opacity(0.35), lineWidth: 1)
        )
    }

    private func tallyPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RisaTheme.textPrimary(scheme))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(RisaTheme.cardBackground(scheme))
        )
    }

    private func handleScannedPayload(_ payload: String) {
        let outcome = ticketStore.scan(payloadString: payload)
        switch outcome {
        case .accepted(let record):
            scanResultPass = true
            scanResultMessage = "PASS • \(record.name) (\(record.orderNumber)) scanned \(record.scannedCount)/\(record.ticketCount)."
        case .noRemaining(let record):
            scanResultPass = false
            scanResultMessage = "FAIL • No remaining tickets for \(record.orderNumber)."
        case .orderNotFound(let orderNumber):
            scanResultPass = false
            scanResultMessage = "FAIL • Order \(orderNumber) not found."
        case .invalidPayload:
            scanResultPass = false
            scanResultMessage = "FAIL • Invalid QR payload or issuer mismatch."
        case .operatorDisabled:
            scanResultPass = false
            scanResultMessage = "FAIL • Ticket scanning is disabled by operator."
        }
    }

    private func seedOrderSelection() {
        if selectedOrderForQR.isEmpty, let first = ticketStore.orders.first {
            selectedOrderForQR = first.orderNumber
        } else if !selectedOrderForQR.isEmpty,
                  !ticketStore.orders.contains(where: { $0.orderNumber == selectedOrderForQR }),
                  let first = ticketStore.orders.first {
            selectedOrderForQR = first.orderNumber
        }
    }

    private func qrImageForString(_ string: String) -> Image {
        let data = Data(string.utf8)
        filter.message = data
        filter.correctionLevel = "M"

        if let output = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaled = output.transformed(by: transform)

            if let cgImage = context.createCGImage(scaled, from: scaled.extent) {
                #if canImport(UIKit)
                return Image(uiImage: UIImage(cgImage: cgImage))
                #else
                return Image(systemName: "qrcode")
                #endif
            }
        }

        return Image(systemName: "qrcode")
    }

    private func copyToClipboard() {
        #if canImport(UIKit)
        UIPasteboard.general.string = qrPayload
        #endif
        withAnimation(.easeInOut(duration: 0.16)) {
            didCopy = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.easeInOut(duration: 0.16)) {
                didCopy = false
            }
        }
    }
}

private struct TicketQRScannerSheet: View {
    let onScanned: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                CameraQRCodeScannerView { payload in
                    onScanned(payload)
                    dismiss()
                }
                .ignoresSafeArea()
            }
            .navigationTitle("Scan Ticket QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct CameraQRCodeScannerView: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> TicketScannerViewController {
        let controller = TicketScannerViewController()
        controller.onCodeDetected = onCodeScanned
        return controller
    }

    func updateUIViewController(_ uiViewController: TicketScannerViewController, context: Context) {}
}

private final class TicketScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeDetected: ((String) -> Void)?

    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasDetectedCode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureCamera()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    private func configureCamera() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              captureSession.canAddInput(videoInput) else { return }

        captureSession.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()
        guard captureSession.canAddOutput(metadataOutput) else { return }
        captureSession.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: captureSession)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.layer.bounds
        view.layer.addSublayer(preview)
        previewLayer = preview
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !hasDetectedCode,
              let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              metadataObject.type == .qr,
              let value = metadataObject.stringValue else { return }

        hasDetectedCode = true
        captureSession.stopRunning()
        onCodeDetected?(value)
    }
}

#Preview("QR Tools") {
    QRCodeView()
}
