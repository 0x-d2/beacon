// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// The first screen: the paired Macs, each a card with its live CPU and
/// memory, or, with none yet, how to pair one and a way to look around with
/// the demo Mac first.
struct MacsView: View {
    @Environment(AppModel.self) private var model
    @State private var pairing = false
    @State private var settings = false

    var body: some View {
        @Bindable var model = model
        NavigationStack(path: $model.path) {
            Group {
                if model.macs.isEmpty {
                    EmptyState(symbol: "macbook.and.iphone", title: "No Macs yet",
                               message: "On your Mac, open Vorssaint's Settings › Monitor, turn on Watch from iPhone and add a phone. Then scan the code here.") {
                        Button("Add a Mac") { pairing = true }
                            .buttonStyle(.borderedProminent)
                        Button("Try with sample data") { model.path = [.mac(model.demo.id)] }
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: BeaconMetrics.spacing4) {
                            ForEach(model.macs) { mac in
                                NavigationLink(value: Route.mac(mac.id)) {
                                    if let session = model.session(for: mac.id) { MacCard(session: session) }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(BeaconMetrics.margin)
                    }
                    .background(BeaconColor.canvas)
                }
            }
            .navigationTitle("Macs")
            .navigationDestination(for: Route.self) { route in
                switch route {
                case let .mac(id):
                    if let session = model.session(for: id) { DashboardView(session: session) }
                case let .metric(id, kind):
                    if let session = model.session(for: id) { MetricDetailView(session: session, kind: kind) }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Settings", systemImage: "gearshape") { settings = true }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add a Mac", systemImage: "plus") { pairing = true }
                }
            }
            .sheet(isPresented: $pairing) { PairingView() }
            .sheet(isPresented: $settings) { SettingsView() }
            .alert("Pair with this Mac?", isPresented: Binding(get: { model.proposedPairing != nil }, set: { if !$0 { model.proposedPairing = nil } }),
                   presenting: model.proposedPairing) { _ in
                Button("Pair") { model.confirmProposedPairing() }
                Button("Cancel", role: .cancel) { model.proposedPairing = nil }
            } message: { pairing in
                Text("Pair only with a Mac of your own: it will see this phone's name.\n\(Self.details(pairing))")
            }
            .alert("Couldn't pair", isPresented: Binding(get: { model.pairingError != nil && !pairing }, set: { if !$0 { model.pairingError = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(model.pairingError ?? "")
            }
        }
    }
}

extension MacsView {
    /// The name and every address a pairing would connect to, for the owner to recognise.
    static func details(_ pairing: RemotePairing) -> String {
        ([pairing.name, pairing.host] + (pairing.alternateHost.map { [$0] } ?? []) + ["\(pairing.port)"]).joined(separator: " · ")
    }
}

/// A paired Mac on the list: its name and model, whether it's live, and its
/// CPU and memory while the list is on screen.
struct MacCard: View {
    let session: MacSession

    var body: some View {
        let snapshot = session.snapshot
        VStack(alignment: .leading, spacing: BeaconMetrics.spacing4) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.info?.name ?? session.mac.name).font(.headline)
                    Text(session.info?.model ?? session.mac.host).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                StatusPill(kind: session.statusKind)
            }
            HStack(spacing: BeaconMetrics.spacing5) {
                mini(title: "CPU", value: snapshot?.cpuUsage, tint: BeaconColor.cpu)
                mini(title: "Memory", value: snapshot?.memoryFraction, tint: BeaconColor.memory)
                mini(title: "GPU", value: snapshot?.gpuUsage, tint: BeaconColor.gpu)
            }
        }
        .padding(BeaconMetrics.tilePadding)
        .background(BeaconColor.tile, in: RoundedRectangle(cornerRadius: BeaconMetrics.tileRadius, style: .continuous))
        .contentShape(.rect)
        .onAppear { session.watch() }
        .onDisappear { session.unwatch() }
    }

    private func mini(title: LocalizedStringKey, value: Double?, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(Format.percent(value)).font(.caption.monospacedDigit().weight(.semibold))
                    .contentTransition(.numericText())
                    .animation(BeaconMotion.reading, value: value)
            }
            LevelBar(fraction: value ?? 0, tint: tint)
        }
        .frame(maxWidth: .infinity)
    }
}

extension MacSession {
    var statusKind: StatusPill.Kind {
        if isDemo { return .demo }
        switch status {
        case .live: return .live
        case .connecting: return .connecting
        case .idle, .offline, .refused: return .offline
        }
    }
}

extension RemoteSnapshot {
    var memoryFraction: Double? {
        guard let used = memoryUsed, let total = memoryTotal, total > 0 else { return nil }
        return Double(used) / Double(total)
    }
}

#Preview("Empty") {
    MacsView().environment(AppModel(demoOnly: true))
}
