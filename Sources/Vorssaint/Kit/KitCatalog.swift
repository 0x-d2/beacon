// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

#if VORSSAINT_DEVELOPMENT
import SwiftUI

/// What BeaconKit™ photographs, in the order the site lists it. A new
/// specimen (Kit/Specimens/) is added here; docs/beaconkit.md › Renders.
enum KitCatalog {
    static var specimens: [KitSpecimen] {
        [
            .panelCard, .hudBackdrop, .keyCap, .shortcutCaps, .brandMark, .brandBadge, .disclosureHeaderRow,
            .fullDiskAccessNote, .colorSwatch,
            .panelSection, .utilityActionButton, .panelToggleRow, .panelBetaBadge, .processUsageRow,
            .sparkline, .usageBar, .pressureIndicator, .cpuCoreMatrix, .notchMeter,
            .settingsCard, .settingsRow, .settingsChoiceRow, .settingsMenuRow, .trailingSwitchToggleStyle,
            .notchIconButton, .notchPillButton, .notchEmptyView, .notchButtonStyle,
        ]
    }

    /// Whole surfaces, by web/collector/surfaces.ts's ids. Only views that
    /// draw from the frozen readings and start no service of their own: a
    /// page that registers hotkeys, applies the appearance or asks for a
    /// permission would change what it is photographing, or the Mac.
    static var surfaces: [KitSurface] {
        [
            KitSurface("panel.system", width: 308, backdrop: .panel) {
                SystemSection(collapsible: false, showConnectedDevices: {})
            },
            KitSurface("settings.about", width: 520, backdrop: .window) {
                AboutSettings()
            },
        ]
    }
}
#endif
