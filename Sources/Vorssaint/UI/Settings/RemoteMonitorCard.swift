// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import CoreImage
import SwiftUI

/// Settings › Monitor › Watch from iPhone: the switch, the QR code a new phone
/// scans, the phones already paired and the address used away from home.
/// The service (RemoteMonitorService) owns the state; this only shows it.
struct RemoteMonitorCard: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var service = RemoteMonitorService.shared
    @AppStorage(DefaultsKey.remoteMonitorEnabled) private var enabled = false
    @AppStorage(DefaultsKey.remoteMonitorAlternateHost) private var alternateHost = ""

    private var text: RemoteMonitorFeatureStrings { FeatureStrings.remoteMonitor(l10n.language) }

    var body: some View {
        SettingsCard {
            SettingsRow(symbol: "iphone.radiowaves.left.and.right", title: text.title, caption: text.caption) {
                Toggle("", isOn: $enabled).labelsHidden()
            }
            if enabled {
                Text(status)
                    .font(.caption)
                    .foregroundStyle(statusIsError ? Color.orange : Color.secondary)
                    .padding(.leading, settingsRowTextInset)
                if let pairing = service.pendingPairing {
                    pairingPanel(pairing)
                } else {
                    Button(text.addPhone) { service.startPairing() }
                        .padding(.leading, settingsRowTextInset)
                }
                phoneList
                VStack(alignment: .leading, spacing: 4) {
                    Text(text.remoteAddress).font(.callout)
                    TextField(RemoteMonitorService.tailnetAddress() ?? "mac.tailnet.ts.net", text: $alternateHost)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 280)
                    Text(text.remoteAddressHelp)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.leading, settingsRowTextInset)
            }
        }
        .onChange(of: enabled) { _, _ in service.syncWithPreferences() }
    }

    private var status: String {
        switch service.state {
        case .off: return ""
        case .idle: return text.idle
        case let .listening(port): return String(format: text.listeningFormat, Int(port))
        case let .failed(reason): return String(format: text.failedFormat, reason)
        }
    }

    private var statusIsError: Bool {
        if case .failed = service.state { return true }
        return false
    }

    private func pairingPanel(_ pairing: RemotePairing) -> some View {
        HStack(alignment: .top, spacing: 16) {
            if let image = Self.qrCode(pairing.url.absoluteString) {
                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 168, height: 168)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white))
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 10) {
                Text(text.scanHint)
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
                Text(pairing.host + (pairing.alternateHost.map { " · \($0)" } ?? "") + " · \(pairing.port)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                HStack {
                    Button(text.copyLink) {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(pairing.url.absoluteString, forType: .string)
                    }
                    Button(text.cancel) { service.cancelPairing() }
                }
            }
        }
        .padding(.leading, settingsRowTextInset)
    }

    @ViewBuilder
    private var phoneList: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(text.pairedPhones).font(.callout)
            let phones = service.phones.filter { $0.id != service.pendingPairing?.id || $0.lastSeen != nil }
            if phones.isEmpty {
                Text(text.noPhones).font(.caption).foregroundStyle(.secondary)
            }
            ForEach(phones) { phone in
                HStack(spacing: 8) {
                    Image(systemName: "iphone")
                        .foregroundStyle(service.connected.contains(phone.id) ? Color.accentColor : Color.secondary)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(phone.name)
                        Text(seen(phone)).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(text.remove) { service.remove(id: phone.id) }
                }
            }
        }
        .padding(.leading, settingsRowTextInset)
    }

    private func seen(_ phone: RemotePairedPhone) -> String {
        if service.connected.contains(phone.id) { return text.connected }
        guard let date = phone.lastSeen else { return text.neverConnected }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: l10n.language.rawValue)
        return String(format: text.lastSeenFormat, formatter.localizedString(for: date, relativeTo: Date()))
    }

    /// The pairing link as a QR code, scaled up without smoothing so each
    /// module stays a crisp square for the phone's camera.
    static func qrCode(_ text: String) -> NSImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(Data(text.utf8), forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 8, y: 8)),
              let cgImage = CIContext().createCGImage(output, from: output.extent) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: output.extent.width / 2, height: output.extent.height / 2))
    }
}
