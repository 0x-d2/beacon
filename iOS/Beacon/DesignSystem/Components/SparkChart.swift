// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Charts
import SwiftUI

/// The recent readings as a small area chart, oldest on the left, the way the
/// Mac panel's Sparkline draws them: a line over a fading fill, no axes. With
/// `maxValue` the scale is fixed (a percentage); without it, it follows the
/// highest reading (a network rate).
struct SparkChart: View {
    var values: [Double]
    var tint: Color
    var maxValue: Double? = nil

    var body: some View {
        Chart(Array(values.enumerated()), id: \.offset) { index, value in
            AreaMark(x: .value("t", index), y: .value("v", value))
                .foregroundStyle(LinearGradient(colors: [tint.opacity(0.32), tint.opacity(0.02)], startPoint: .top, endPoint: .bottom))
                .interpolationMethod(.monotone)
            LineMark(x: .value("t", index), y: .value("v", value))
                .foregroundStyle(tint)
                .lineStyle(StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.monotone)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartXScale(domain: 0...max(1, values.count - 1))
        .chartYScale(domain: 0...max(maxValue ?? (values.max() ?? 1), 0.0001))
        .accessibilityHidden(true)
    }
}

extension KitSpecimen {
    @MainActor static let sparkChart = KitSpecimen("SparkChart", .instruments, [
        KitVariant("cpu", "maxValue: 1, tint: BeaconColor.cpu") {
            SparkChart(values: DemoData.history.cpu, tint: BeaconColor.cpu, maxValue: 1)
                .frame(height: BeaconMetrics.sparkHeight)
        },
        KitVariant("network", "tint: BeaconColor.download") {
            SparkChart(values: DemoData.history.networkDown, tint: BeaconColor.download)
                .frame(height: BeaconMetrics.sparkHeight)
        },
        KitVariant("short", "two readings") {
            SparkChart(values: [0.2, 0.3], tint: BeaconColor.memory, maxValue: 1)
                .frame(height: BeaconMetrics.sparkHeight)
        },
    ])
}

#Preview("SparkChart") { KitSpecimen.sparkChart.preview() }
