// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Beacon's type: SF Pro Rounded for readings, with digits of one width so a
/// changing number doesn't shimmy; the system text styles for everything
/// else, so Dynamic Type scales the whole app.
enum BeaconType {
    /// The one reading a screen is about (a detail page's headline number).
    static let hero = Font.system(.largeTitle, design: .rounded, weight: .semibold).monospacedDigit()
    /// A tile's reading.
    static let reading = Font.system(.title2, design: .rounded, weight: .semibold).monospacedDigit()
    /// A smaller reading beside another (upload under download).
    static let readingSmall = Font.system(.headline, design: .rounded, weight: .semibold).monospacedDigit()
    /// A tile's title, above its reading.
    static let tileTitle = Font.subheadline.weight(.medium)
    /// The unit after a reading, and captions under it.
    static let unit = Font.footnote.weight(.medium)
    static let caption = Font.caption
    /// Section headings: small capitals, as the Mac panel's `sectionTitle`.
    static let section = Font.footnote.weight(.semibold)
}

/// Beacon's lengths, on a 4-point grid.
enum BeaconMetrics {
    static let spacing2: CGFloat = 4
    static let spacing3: CGFloat = 8
    static let spacing4: CGFloat = 12
    static let spacing5: CGFloat = 16
    static let spacing6: CGFloat = 20
    /// The screen's side margins.
    static let margin: CGFloat = 16
    /// A tile's corner: concentric with the screen's on a modern iPhone, at the screen margin.
    static let tileRadius: CGFloat = 24
    static let tilePadding: CGFloat = 16
    static let tileMinHeight: CGFloat = 148
    /// A chart inside a tile.
    static let sparkHeight: CGFloat = 36
    static let ringLineWidth: CGFloat = 8
    static let barHeight: CGFloat = 6
}

/// Beacon's motion: readings ease into their new value with no bounce (a
/// number that overshoots reads as a wrong number); taps get a quick, slightly
/// springy answer. Reduce Motion turns both into a cross-fade.
enum BeaconMotion {
    static let reading = Animation.smooth(duration: 0.45)
    static let tap = Animation.snappy(duration: 0.25)
    static let appear = Animation.smooth(duration: 0.35)
}
