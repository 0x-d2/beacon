// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// The app's settings: units, the paired Macs, the design catalog, and what
/// Beacon does with the network.
struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            Form {
                Section("Readings") {
                    Picker("Temperature", selection: $model.temperatureUnit) {
                        Text("Celsius").tag(TemperatureUnit.celsius)
                        Text("Fahrenheit").tag(TemperatureUnit.fahrenheit)
                    }
                }
                Section("Macs") {
                    if model.macs.isEmpty {
                        Text("No Macs yet").foregroundStyle(.secondary)
                    }
                    ForEach(model.macs) { mac in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mac.name)
                            Text(mac.hosts.joined(separator: " · ")).font(.caption.monospaced()).foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { offsets in offsets.map { model.macs[$0].id }.forEach(model.remove) }
                }
                Section {
                    NavigationLink("Design catalog") { KitGalleryView() }
                } footer: {
                    Text("Every component of the app in every variant, as the BeaconKit™ catalog shows them.")
                }
                Section {
                    Text("Beacon talks only to the Macs you pair, directly, on your network or over Tailscale. Each Mac gives this phone its own key, kept in the phone's keychain; nothing is sent anywhere else.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Privacy")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

/// One Mac's own page: where the phone reaches it, and forgetting it.
struct MacSettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let session: MacSession
    @State private var confirming = false

    var body: some View {
        NavigationStack {
            Form {
                if let info = session.info {
                    Section("This Mac") {
                        StatRow(title: "Model", value: info.model)
                        StatRow(title: "System", value: info.osVersion)
                        StatRow(title: "Vorssaint", value: info.appVersion)
                        StatRow(title: "Readings every", value: Duration.seconds(info.interval).formatted(.units(allowed: [.seconds], width: .abbreviated)))
                    }
                }
                Section {
                    StatRow(title: "On this network", value: session.mac.host)
                    StatRow(title: "Away from home", value: session.mac.alternateHost ?? "–")
                    StatRow(title: "Port", value: "\(session.mac.port)")
                    if let host = session.connectedHost { StatRow(title: "Connected through", value: host, tint: BeaconColor.positive) }
                } header: {
                    Text("Connection")
                } footer: {
                    Text("Away from home, Beacon reaches the Mac at the second address, such as its Tailscale name, with Tailscale on in both.")
                }
                Section {
                    Button("Forget this Mac", role: .destructive) { confirming = true }
                } footer: {
                    Text("The phone forgets the Mac's key. Remove the phone on the Mac too, under Settings › Monitor › Watch from iPhone.")
                }
            }
            .navigationTitle(session.info?.name ?? session.mac.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .confirmationDialog("Forget this Mac?", isPresented: $confirming, titleVisibility: .visible) {
                Button("Forget", role: .destructive) {
                    model.remove(session.id)
                    dismiss()
                }
            }
        }
    }
}

#Preview { SettingsView().environment(AppModel(demoOnly: true)) }
