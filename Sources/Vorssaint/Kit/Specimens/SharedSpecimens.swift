// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

#if VORSSAINT_DEVELOPMENT
import SwiftUI

/// Hands a specimen the appearance it's drawn in, for the tokens that take
/// one (`PanelMetricColor.green(for:)`).
struct KitSchemed<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    let content: (ColorScheme) -> Content

    var body: some View { content(scheme) }
}

extension KitSpecimen {
    static var panelCard: KitSpecimen {
        KitSpecimen(".panelCard()", .shared, variants: [
            KitVariant("padded", ".panelCard()") {
                VStack(alignment: .leading, spacing: 6) {
                    sectionTitle(L10n.shared.s.systemSection)
                    Text(kitText("İşlemci %23 · Bellek 11,2 GB", "CPU 23% · Memory 11.2 GB")).font(.system(size: 12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .panelCard()
            },
            KitVariant("rows", ".panelCard(interactive: false, padded: false)") {
                PanelRowGroup(items: ["moon.zzz.fill", "display.2", "speaker.wave.2"]) { symbol in
                    HStack(spacing: PanelRowMetrics.iconSpacing) {
                        Image(systemName: symbol).frame(width: PanelRowMetrics.iconWidth)
                        Text(symbol == "moon.zzz.fill" ? L10n.shared.s.keepAwakeTitle : symbol == "display.2" ? kitText("Parlaklık", "Brightness") : L10n.shared.s.mixerSection)
                        Spacer()
                    }
                    .font(.system(size: 12))
                    .padding(.horizontal, PanelRowMetrics.horizontalInset(island: false))
                    .padding(.vertical, PanelRowMetrics.verticalInset(island: false))
                }
            },
            KitVariant("island", ".panelCard() · notchPresentation", backdrop: .notch) {
                Text(kitText("Adada aynı kart", "The same card in the island"))
                    .font(.system(size: 12))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .panelCard()
            },
        ])
    }

    static var hudBackdrop: KitSpecimen {
        let label = { (text: String) in
            Text(text).font(.system(size: 13, weight: .medium)).padding(16).frame(maxWidth: .infinity)
        }
        return KitSpecimen("HUDBackdrop", .shared, variants: [
            KitVariant("standard", "HUDBackdrop(cornerRadius: 14)", width: 260, backdrop: .desktop) {
                label(kitText("Yüzen panel", "Floating panel")).background(HUDBackdrop(cornerRadius: 14))
            },
            KitVariant("high", "contrast: .high", width: 260, backdrop: .desktop) {
                label(kitText("Yüksek kontrast plakası", "High-contrast plate")).background(HUDBackdrop(cornerRadius: 14, contrast: .high))
            },
        ])
    }

    static var keyCap: KitSpecimen {
        KitSpecimen("KeyCap", .shared, variants: [
            KitVariant("symbols", "KeyCap(label:)", width: 160, backdrop: .window) {
                HStack(spacing: 6) { KeyCap(label: "⌘"); KeyCap(label: "⌥"); KeyCap(label: "⇧"); KeyCap(label: "K") }
            },
        ])
    }

    static var shortcutCaps: KitSpecimen {
        KitSpecimen("ShortcutCaps", .shared, variants: [
            KitVariant("copy", #"keys: ["⌘", "X"]"#, width: 120, backdrop: .window) { ShortcutCaps(keys: ["⌘", "X"]) },
            KitVariant("long", #"keys: ["⌃", "⌥", "⌘", "Space"]"#, width: 200, backdrop: .window) { ShortcutCaps(keys: ["⌃", "⌥", "⌘", "Space"]) },
        ])
    }

    static var brandMark: KitSpecimen {
        KitSpecimen("BrandMark", .shared, variants: [
            KitVariant("primary", "BrandMark(width: 64, tint: .primary)", width: 80, backdrop: .window) { BrandMark(width: 64, tint: .primary) },
        ])
    }

    static var brandBadge: KitSpecimen {
        KitSpecimen("BrandBadge", .shared, variants: [
            KitVariant("64", "BrandBadge(size: 64)", width: 64, backdrop: .window) { BrandBadge(size: 64) },
            KitVariant("28", "BrandBadge(size: 28)", width: 28, backdrop: .window) { BrandBadge(size: 28) },
        ])
    }

    static var disclosureHeaderRow: KitSpecimen {
        let row = { (expanded: Bool) in
            DisclosureHeaderRow(isExpanded: .constant(expanded)) {
                Image(systemName: "cpu")
                Text(kitText("İşlemci kullanımı", "CPU usage")).font(.system(size: 12))
                Spacer()
            }
        }
        return KitSpecimen("DisclosureHeaderRow", .shared, variants: [
            KitVariant("collapsed", "isExpanded: false") { row(false) },
            KitVariant("expanded", "isExpanded: true") { row(true) },
        ])
    }

    static var fullDiskAccessNote: KitSpecimen {
        KitSpecimen("FullDiskAccessNote", .shared, variants: [
            KitVariant("regular", "FullDiskAccessNote()", width: 420, backdrop: .window) { FullDiskAccessNote() },
            KitVariant("compact", "compact: true") { FullDiskAccessNote(compact: true) },
        ])
    }

    static var colorSwatch: KitSpecimen {
        KitSpecimen("ColorSwatch", .shared, variants: [
            KitVariant("sizes", "ColorSwatch(color:size:)", width: 120, backdrop: .window) {
                HStack(spacing: 8) {
                    ColorSwatch(color: ColorValue(red: 1, green: 0.58, blue: 0))
                    ColorSwatch(color: ColorValue(red: 0.04, green: 0.52, blue: 1), size: 20)
                    ColorSwatch(color: ColorValue(red: 0.2, green: 0.78, blue: 0.35, alpha: 0.5), size: 28)
                }
            },
        ])
    }
}
#endif
