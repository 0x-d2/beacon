// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// One Mac at a glance: a tile per reading, two to a row, each opening its
/// detail. The phone subscribes while this is on screen and stops when it
/// leaves, so the Mac samples for it only then.
struct DashboardView: View {
    @Environment(AppModel.self) private var model
    let session: MacSession
    @State private var showingMacSettings = false

    private let columns = [GridItem(.flexible(), spacing: BeaconMetrics.spacing4), GridItem(.flexible(), spacing: BeaconMetrics.spacing4)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BeaconMetrics.spacing5) {
                header
                if case let .refused(reason) = session.status {
                    refusal(reason)
                }
                LazyVGrid(columns: columns, spacing: BeaconMetrics.spacing4) {
                    ForEach(MetricKind.dashboard) { kind in
                        NavigationLink(value: Route.metric(session.id, kind)) {
                            DashboardTile(session: session, kind: kind, unit: model.temperatureUnit)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(BeaconMetrics.margin)
        }
        .background(BeaconColor.canvas)
        .navigationTitle(session.info?.name ?? session.mac.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !session.isDemo {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("This Mac", systemImage: "info.circle") { showingMacSettings = true }
                }
            }
        }
        .sheet(isPresented: $showingMacSettings) { MacSettingsView(session: session) }
        .onAppear { session.watch() }
        .onDisappear { session.unwatch() }
        .refreshable { session.connect() }
    }

    private var header: some View {
        HStack(spacing: BeaconMetrics.spacing3) {
            StatusPill(kind: session.statusKind)
            if let info = session.info {
                Text("\(info.model) · \(info.osVersion)").font(.caption).foregroundStyle(.secondary).lineLimit(1)
            } else if case let .offline(reason) = session.status {
                Text(reason).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
            Spacer()
            if let host = session.connectedHost, host != session.mac.host {
                Label("Away", systemImage: "globe").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func refusal(_ reason: String) -> some View {
        Label {
            Text(reason == "removed" ? "This phone was removed on the Mac. Pair it again to see its readings." : "The Mac turned this phone away (\(reason)).")
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(BeaconColor.caution)
        }
        .font(.callout)
        .padding(BeaconMetrics.tilePadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BeaconColor.tile, in: RoundedRectangle(cornerRadius: BeaconMetrics.tileRadius, style: .continuous))
    }
}

/// The readings the dashboard shows, in order, and what each tile and detail page are about.
enum MetricKind: String, CaseIterable, Identifiable, Hashable {
    case cpu, memory, gpu, temperature, network, power, disk, fans

    var id: String { rawValue }
    static let dashboard: [MetricKind] = allCases

    var title: LocalizedStringKey {
        switch self {
        case .cpu: return "CPU"
        case .memory: return "Memory"
        case .gpu: return "GPU"
        case .temperature: return "Temperatures"
        case .network: return "Network"
        case .power: return "Power"
        case .disk: return "Disks"
        case .fans: return "Fans"
        }
    }

    var symbol: String {
        switch self {
        case .cpu: return "cpu"
        case .memory: return "memorychip"
        case .gpu: return "square.stack.3d.up"
        case .temperature: return "thermometer.medium"
        case .network: return "network"
        case .power: return "bolt.fill"
        case .disk: return "internaldrive"
        case .fans: return "fanblades"
        }
    }

    var tint: Color {
        switch self {
        case .cpu: return BeaconColor.cpu
        case .memory: return BeaconColor.memory
        case .gpu: return BeaconColor.gpu
        case .temperature: return BeaconColor.temperature
        case .network: return BeaconColor.download
        case .power: return BeaconColor.power
        case .disk: return BeaconColor.disk
        case .fans: return BeaconColor.fan
        }
    }
}

/// One dashboard tile: the reading, and the chart, ring or bar that suits it.
struct DashboardTile: View {
    let session: MacSession
    let kind: MetricKind
    let unit: TemperatureUnit

    var body: some View {
        let snapshot = session.snapshot
        let history = session.history
        switch kind {
        case .cpu:
            MetricTile(title: kind.title, symbol: kind.symbol, tint: kind.tint, value: Format.percent(snapshot?.cpuUsage),
                       caption: session.info.map { String(localized: "\($0.cpuCores) cores") }) {
                SparkChart(values: history.cpu, tint: kind.tint, maxValue: 1).frame(height: BeaconMetrics.sparkHeight)
            }
        case .memory:
            MetricTile(title: kind.title, symbol: kind.symbol, tint: kind.tint, value: Format.bytes(snapshot?.memoryUsed),
                       caption: snapshot?.memoryTotal.map { String(localized: "of \(Format.bytes($0))") }) {
                HStack {
                    // The Mac warns on memory by its pressure, not by how full it is: the badge says it.
                    LevelBar(fraction: snapshot?.memoryFraction ?? 0, tint: kind.tint, warns: false)
                    if let pressure = snapshot?.memoryPressure, pressure != "normal" { PressureBadge(pressure: pressure) }
                }
            }
        case .gpu:
            MetricTile(title: kind.title, symbol: kind.symbol, tint: kind.tint, value: Format.percent(snapshot?.gpuUsage)) {
                SparkChart(values: history.gpu, tint: kind.tint, maxValue: 1).frame(height: BeaconMetrics.sparkHeight)
            }
        case .temperature:
            MetricTile(title: kind.title, symbol: kind.symbol, tint: kind.tint,
                       value: Format.temperature(snapshot?.cpuTemperature, unit: unit),
                       caption: snapshot?.gpuTemperature.map { String(localized: "GPU \(Format.temperature($0, unit: unit))") } ?? String(localized: "CPU"))
        case .network:
            MetricTile(title: kind.title, symbol: kind.symbol, tint: kind.tint, value: Format.rate(snapshot?.networkDownBytesPerSec),
                       caption: String(localized: "↑ \(Format.rate(snapshot?.networkUpBytesPerSec))")) {
                SparkChart(values: history.networkDown, tint: kind.tint).frame(height: BeaconMetrics.sparkHeight)
            }
        case .power:
            let power = snapshot?.power
            if let charge = power?.chargePercent {
                MetricTile(title: kind.title, symbol: power?.isCharging == true ? "battery.100percent.bolt" : "battery.75percent",
                           tint: kind.tint, value: Format.percent(Double(charge) / 100),
                           caption: power?.isCharging == true ? String(localized: "Charging") : Format.duration(power?.timeRemainingSeconds)) {
                    LevelBar(fraction: Double(charge) / 100, tint: kind.tint, warns: false)
                }
            } else {
                MetricTile(title: kind.title, symbol: kind.symbol, tint: kind.tint, value: Format.watts(power?.systemWatts),
                           caption: String(localized: "The Mac draws")) {
                    SparkChart(values: history.power, tint: kind.tint).frame(height: BeaconMetrics.sparkHeight)
                }
            }
        case .disk:
            let disk = snapshot?.disks.first { $0.isInternal } ?? snapshot?.disks.first
            MetricTile(title: kind.title, symbol: kind.symbol, tint: kind.tint,
                       value: disk.map { Format.percent(Double($0.usedBytes) / Double(max($0.totalBytes, 1))) } ?? "–",
                       caption: disk?.name) {
                LevelBar(fraction: disk.map { Double($0.usedBytes) / Double(max($0.totalBytes, 1)) } ?? 0, tint: kind.tint, warns: true)
            }
        case .fans:
            let speeds = snapshot?.fanSpeeds ?? []
            MetricTile(title: kind.title, symbol: kind.symbol, tint: .secondary,
                       value: speeds.first.map { $0.formatted(.number.precision(.fractionLength(0))) } ?? "–",
                       unit: speeds.isEmpty ? nil : "rpm",
                       caption: speeds.isEmpty ? String(localized: "No fan readings") : String(localized: "\(speeds.count) fans"))
        }
    }
}

#Preview("Dashboard") {
    let model = AppModel(demoOnly: true)
    NavigationStack { DashboardView(session: model.demo) }.environment(model)
}
