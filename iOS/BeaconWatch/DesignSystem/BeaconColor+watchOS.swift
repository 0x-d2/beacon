// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Beacon's colours on the watch. watchOS is always dark, so each is the
/// colour the phone's BeaconColor (Beacon/DesignSystem/BeaconColor.swift)
/// gives it in dark mode: the system colour the Mac's menu panel gives that
/// metric. The names are the same, so the components the phone and the watch
/// share draw alike on both.
enum BeaconColor {
    // MARK: Metrics

    /// CPU: PanelMetricColor.green.
    static let cpu = Color.green
    /// GPU: PanelMetricColor.mint.
    static let gpu = Color.mint
    /// Memory: PanelMetricColor.cyan.
    static let memory = Color.cyan
    /// Download, and the network as a whole: the system blue, as the Mac's usage bars.
    static let download = Color.accentColor
    /// Upload: PanelMetricColor.orange.
    static let upload = Color.orange
    /// Power and the battery: PanelMetricColor.yellow.
    static let power = Color.yellow
    /// Temperatures: PanelMetricColor.orange, as the Mac's sensor readouts.
    static let temperature = Color.orange
    /// Disks: PanelMetricColor.pink.
    static let disk = Color.pink
    /// Fans: the secondary label, a quiet reading.
    static let fan = Color.secondary

    // MARK: States

    static let positive = Color.green
    static let caution = Color.yellow
    static let critical = Color.red

    // MARK: Surfaces

    /// The screen behind the rows: the watch's own black.
    static let canvas = Color.black
    /// A row's own fill, as the watch's lists draw theirs.
    static let tile = Color.white.opacity(0.14)
    /// A track under a bar or a ring: a little brighter than the phone's, to read on a row on black.
    static let track = Color.white.opacity(0.16)
    static let hairline = Color.white.opacity(0.12)

    /// A level's colour as the Mac's usage bars choose it: calm, then caution
    /// past 60%, critical past 85%.
    static func level(_ fraction: Double, calm: Color) -> Color {
        switch fraction {
        case ..<0.6: return calm
        case ..<0.85: return caution
        default: return critical
        }
    }
}
