// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI
import UIKit

/// Beacon's colours. A metric keeps the colour the Mac's menu panel gives it
/// (`PanelMetricColor` in the Mac app's UI/Theme.swift: the system colour in
/// dark mode, the same hue darkened in light mode so it reads on white), so a
/// reading looks like itself on both screens. Everything else is the system's.
enum BeaconColor {
    // MARK: Metrics

    /// CPU: PanelMetricColor.green.
    static let cpu = dynamic(light: (0.00, 0.44, 0.18), dark: UIColor.systemGreen)
    /// GPU: PanelMetricColor.mint.
    static let gpu = dynamic(light: (0.00, 0.44, 0.40), dark: UIColor.systemMint)
    /// Memory: PanelMetricColor.cyan.
    static let memory = dynamic(light: (0.00, 0.43, 0.54), dark: UIColor.systemCyan)
    /// Download, and the network as a whole: the system blue, as the Mac's usage bars.
    static let download = Color.accentColor
    /// Upload: PanelMetricColor.orange.
    static let upload = dynamic(light: (0.68, 0.30, 0.00), dark: UIColor.systemOrange)
    /// Power and the battery: PanelMetricColor.yellow.
    static let power = dynamic(light: (0.56, 0.36, 0.00), dark: UIColor.systemYellow)
    /// Temperatures: PanelMetricColor.orange, as the Mac's sensor readouts.
    static let temperature = dynamic(light: (0.68, 0.30, 0.00), dark: UIColor.systemOrange)
    /// Disks: PanelMetricColor.pink.
    static let disk = dynamic(light: (0.68, 0.06, 0.34), dark: UIColor.systemPink)
    /// Fans: the secondary label, a quiet reading.
    static let fan = Color.secondary

    // MARK: States

    static let positive = dynamic(light: (0.00, 0.44, 0.18), dark: UIColor.systemGreen)
    static let caution = dynamic(light: (0.56, 0.36, 0.00), dark: UIColor.systemYellow)
    static let critical = dynamic(light: (0.68, 0.08, 0.10), dark: UIColor.systemRed)

    // MARK: Surfaces

    /// The screen behind the tiles.
    static let canvas = Color(uiColor: .systemGroupedBackground)
    /// A tile's own fill.
    static let tile = Color(uiColor: .secondarySystemGroupedBackground)
    /// A track under a bar or a ring.
    static let track = Color.primary.opacity(0.08)
    /// A hairline between rows.
    static let hairline = Color.primary.opacity(0.08)

    /// A level's colour as the Mac's usage bars choose it: calm, then caution
    /// past 60%, critical past 85%.
    static func level(_ fraction: Double, calm: Color) -> Color {
        switch fraction {
        case ..<0.6: return calm
        case ..<0.85: return caution
        default: return critical
        }
    }

    /// A colour that is `light` in light mode and `dark` in dark mode.
    private static func dynamic(light: (Double, Double, Double), dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : UIColor(red: light.0, green: light.1, blue: light.2, alpha: 1)
        })
    }
}
