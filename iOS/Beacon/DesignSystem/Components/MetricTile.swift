// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// One reading on the dashboard: an icon and title in the reading's colour, the
/// reading in large rounded figures with its unit, an optional caption, and
/// below them whatever the tile draws (a chart, a ring, bars). The tile is a
/// plain card: Liquid Glass belongs to the controls floating over content,
/// not to the content.
struct MetricTile<Accessory: View>: View {
    let title: LocalizedStringKey
    let symbol: String
    var tint: Color
    var value: String
    var unit: String? = nil
    var caption: String? = nil
    @ViewBuilder var accessory: () -> Accessory

    var body: some View {
        VStack(alignment: .leading, spacing: BeaconMetrics.spacing3) {
            Label(title, systemImage: symbol)
                .font(BeaconType.tileTitle)
                .foregroundStyle(tint)
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(BeaconType.reading)
                    .contentTransition(.numericText())
                    .animation(BeaconMotion.reading, value: value)
                if let unit {
                    Text(unit).font(BeaconType.unit).foregroundStyle(.secondary)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            if let caption {
                Text(caption)
                    .font(BeaconType.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            accessory()
        }
        .frame(maxWidth: .infinity, minHeight: BeaconMetrics.tileMinHeight, alignment: .topLeading)
        .padding(BeaconMetrics.tilePadding)
        .background(BeaconColor.tile, in: RoundedRectangle(cornerRadius: BeaconMetrics.tileRadius, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

extension MetricTile where Accessory == EmptyView {
    init(title: LocalizedStringKey, symbol: String, tint: Color, value: String, unit: String? = nil, caption: String? = nil) {
        self.init(title: title, symbol: symbol, tint: tint, value: value, unit: unit, caption: caption) { EmptyView() }
    }
}

extension KitSpecimen {
    @MainActor static let metricTile = KitSpecimen("MetricTile", .tiles, [
        KitVariant("chart", "MetricTile(title:symbol:tint:value:) { SparkChart }", width: 180) {
            MetricTile(title: "CPU", symbol: "cpu", tint: BeaconColor.cpu, value: Format.percent(0.23), caption: "10 cores") {
                SparkChart(values: DemoData.history.cpu, tint: BeaconColor.cpu, maxValue: 1).frame(height: BeaconMetrics.sparkHeight)
            }
        },
        KitVariant("plain", "caption:", width: 180) {
            MetricTile(title: "Fans", symbol: "fanblades", tint: BeaconColor.fan, value: "1,850", unit: "rpm", caption: "1 fan")
        },
        KitVariant("missing", "value: \"–\"", width: 180) {
            MetricTile(title: "GPU", symbol: "square.stack.3d.up", tint: BeaconColor.gpu, value: "–")
        },
    ])
}

#Preview("MetricTile") { KitSpecimen.metricTile.preview() }
