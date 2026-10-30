// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

#if VORSSAINT_DEVELOPMENT
import SwiftUI

extension KitSpecimen {
    static var panelSection: KitSpecimen {
        KitSpecimen("PanelSection", .panel, variants: [
            KitVariant("collapsible", "PanelSection(.system, title:)") {
                PanelSection(.system, title: L10n.shared.s.systemSection, collapsible: true) {
                    Text(kitText("Bölümün içeriği", "The section's content"))
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .panelCard()
                }
            },
        ])
    }

    static var utilityActionButton: KitSpecimen {
        KitSpecimen("UtilityActionButton", .panel, variants: [
            KitVariant("plain", "UtilityActionButton(title:caption:systemImage:)") {
                UtilityActionButton(title: kitText("Temizlik modu", "Cleaning mode"),
                                    caption: kitText("Klavyeyi ve izleme dörtgenini kilitler", "Locks the keyboard and trackpad"),
                                    systemImage: "sparkles", action: {})
                    .panelCard(padded: false)
            },
            KitVariant("badge", #"badge: "BETA", shortcutHint: "⌥⌘C""#) {
                UtilityActionButton(title: kitText("Ekran kaydı", "Screen recording"),
                                    caption: kitText("Bir pencereyi ya da alanı kaydeder", "Records a window or an area"),
                                    systemImage: "record.circle", badge: "BETA", shortcutHint: "⌥⌘C", action: {})
                    .panelCard(padded: false)
            },
            KitVariant("attention", "needsAttention: true") {
                UtilityActionButton(title: kitText("Kaldırıcı", "Uninstaller"),
                                    caption: kitText("Tam Disk Erişimi gerekiyor", "Needs Full Disk Access"),
                                    systemImage: "trash", needsAttention: true, action: {})
                    .panelCard(padded: false)
            },
        ])
    }

    static var panelToggleRow: KitSpecimen {
        let row = { (on: Bool, active: Bool) in
            PanelToggleRow(title: L10n.shared.s.keepAwakeTitle,
                           caption: kitText("Mac uyumaz, ekran açık kalır", "The Mac stays awake, the display on"),
                           systemImage: "moon.zzz.fill", isOn: .constant(on), isActive: active,
                           activeText: active ? kitText("1 sa 20 dk kaldı", "1 h 20 min left") : nil)
                .panelCard(padded: false)
        }
        return KitSpecimen("PanelToggleRow", .panel, variants: [
            KitVariant("off", "isOn: false") { row(false, false) },
            KitVariant("on", "isOn: true") { row(true, false) },
            KitVariant("active", #"isActive: true, activeText:"#) { row(true, true) },
        ])
    }

    static var panelBetaBadge: KitSpecimen {
        KitSpecimen("PanelBetaBadge", .panel, variants: [
            KitVariant("beta", #"PanelBetaBadge(text: "BETA")"#, width: 80) { PanelBetaBadge(text: "BETA") },
        ])
    }

    static var processUsageRow: KitSpecimen {
        KitSpecimen("ProcessUsageRow", .panel, variants: [
            KitVariant("cpu", "ProcessUsageRow(row:value:)") {
                VStack(spacing: 4) {
                    ForEach(KitFixtures.processes) { process in
                        ProcessUsageRow(row: process, value: String(format: "%.1f%%", process.value))
                    }
                }
                .panelCard()
            },
        ])
    }
}
#endif
