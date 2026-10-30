// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI
import VisionKit

/// Adding a Mac: scan the code it shows (Settings › Monitor › Watch from
/// iPhone › Add a phone), or paste its link. The system Camera app works too:
/// the code is a beacon:// link that opens this app.
struct PairingView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var link = ""
    @State private var scanned = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if QRScanner.isAvailable {
                        QRScanner { code in
                            guard !scanned, code.hasPrefix("\(RemotePairing.scheme)://") else { return }
                            scanned = true
                            if model.pair(link: code) != nil { dismiss() } else { scanned = false }
                        }
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .listRowInsets(EdgeInsets())
                    } else {
                        Label("The camera isn't available here. Paste the link instead: on the Mac, Copy link under the code.", systemImage: "camera")
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("On the Mac: Vorssaint › Settings › Monitor › Watch from iPhone › Add a phone.")
                }
                Section("Or paste the link") {
                    TextField("beacon://pair?…", text: $link, axis: .vertical)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.callout.monospaced())
                    Button("Pair") {
                        if model.pair(link: link) != nil { dismiss() }
                    }
                    .disabled(link.isEmpty)
                }
                if let error = model.pairingError {
                    Section { Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(BeaconColor.caution) }
                }
            }
            .navigationTitle("Add a Mac")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", role: .cancel) { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    PasteButton(payloadType: String.self) { strings in
                        if let first = strings.first { link = first }
                    }
                    .labelStyle(.iconOnly)
                }
            }
        }
    }
}

/// VisionKit's live scanner, reading QR codes only.
struct QRScanner: UIViewControllerRepresentable {
    let found: (String) -> Void

    static var isAvailable: Bool { DataScannerViewController.isSupported && DataScannerViewController.isAvailable }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(recognizedDataTypes: [.barcode(symbologies: [.qr])], qualityLevel: .balanced,
                                                isHighlightingEnabled: true)
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ controller: DataScannerViewController, context: Context) {}

    static func dismantleUIViewController(_ controller: DataScannerViewController, coordinator: Coordinator) {
        controller.stopScanning()
    }

    func makeCoordinator() -> Coordinator { Coordinator(found: found) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let found: (String) -> Void
        init(found: @escaping (String) -> Void) { self.found = found }

        func dataScanner(_ scanner: DataScannerViewController, didAdd items: [RecognizedItem], allItems: [RecognizedItem]) {
            for item in items {
                if case let .barcode(code) = item, let text = code.payloadStringValue { found(text) }
            }
        }
    }
}

#Preview { PairingView().environment(AppModel(demoOnly: true)) }
