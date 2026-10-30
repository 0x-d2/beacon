// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// A level as a ring: a track and an arc that fills clockwise from the top,
/// its colour turning to caution and critical as the Mac's usage bars do,
/// with whatever the caller puts in the middle. VoiceOver reads the level.
struct GaugeRing<Label: View>: View {
    /// 0...1; nil draws the track alone (no reading yet).
    var value: Double?
    var tint: Color
    var lineWidth: CGFloat = BeaconMetrics.ringLineWidth
    /// Whether the colour follows the level (usage) or stays the tint (a battery's charge).
    var warns = true
    @ViewBuilder var label: () -> Label

    var body: some View {
        let fraction = min(1, max(0, value ?? 0))
        let color = warns ? BeaconColor.level(fraction, calm: tint) : tint
        ZStack {
            Circle().stroke(BeaconColor.track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: value == nil ? 0 : max(0.002, fraction))
                .stroke(color.gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(BeaconMotion.reading, value: fraction)
            label()
        }
        .padding(lineWidth / 2)
        .accessibilityElement(children: .combine)
        .accessibilityValue(Format.percent(value))
    }
}

extension GaugeRing where Label == EmptyView {
    init(value: Double?, tint: Color, lineWidth: CGFloat = BeaconMetrics.ringLineWidth, warns: Bool = true) {
        self.init(value: value, tint: tint, lineWidth: lineWidth, warns: warns) { EmptyView() }
    }
}

extension KitSpecimen {
    @MainActor static let gaugeRing = KitSpecimen("GaugeRing", .instruments, [
        KitVariant("calm", "value: 0.23, tint: BeaconColor.cpu") {
            GaugeRing(value: 0.23, tint: BeaconColor.cpu) { Text(Format.percent(0.23)).font(BeaconType.readingSmall) }
                .frame(width: 88, height: 88)
        },
        KitVariant("caution", "value: 0.72") {
            GaugeRing(value: 0.72, tint: BeaconColor.cpu) { Text(Format.percent(0.72)).font(BeaconType.readingSmall) }
                .frame(width: 88, height: 88)
        },
        KitVariant("critical", "value: 0.93") {
            GaugeRing(value: 0.93, tint: BeaconColor.memory) { Text(Format.percent(0.93)).font(BeaconType.readingSmall) }
                .frame(width: 88, height: 88)
        },
        KitVariant("charge", "warns: false, tint: BeaconColor.power") {
            GaugeRing(value: 0.86, tint: BeaconColor.power, warns: false) { Image(systemName: "battery.75percent") }
                .frame(width: 88, height: 88)
        },
        KitVariant("empty", "value: nil") {
            GaugeRing(value: nil, tint: BeaconColor.cpu).frame(width: 88, height: 88)
        },
    ])
}

#Preview("GaugeRing") { KitSpecimen.gaugeRing.preview() }
