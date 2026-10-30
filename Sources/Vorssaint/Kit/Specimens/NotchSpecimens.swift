// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

#if VORSSAINT_DEVELOPMENT
import SwiftUI

extension KitSpecimen {
    static var notchIconButton: KitSpecimen {
        KitSpecimen("NotchIconButton", .notch, variants: [
            KitVariant("row", "NotchIconButton(symbol:title:selected:)", width: 260, backdrop: .notch) {
                HStack(spacing: 6) {
                    NotchIconButton(symbol: "slider.horizontal.3", title: kitText("Denetimler", "Controls"), selected: true, action: {})
                    NotchIconButton(symbol: "speaker.wave.2", title: L10n.shared.s.mixerSection, action: {})
                    NotchIconButton(symbol: "music.note", title: kitText("Müzik", "Music"), action: {})
                    NotchIconButton(symbol: "gauge.with.dots.needle.50percent", title: L10n.shared.s.systemSection, action: {})
                }
            },
        ])
    }

    static var notchPillButton: KitSpecimen {
        KitSpecimen("NotchPillButton", .notch, variants: [
            KitVariant("regular", "NotchPillButton(title:)", width: 200, backdrop: .notch) {
                NotchPillButton(title: kitText("Vazgeç", "Cancel"), action: {})
            },
            KitVariant("prominent", "prominent: true", width: 200, backdrop: .notch) {
                NotchPillButton(title: L10n.shared.s.menuSettings, prominent: true, action: {})
            },
        ])
    }

    static var notchEmptyView: KitSpecimen {
        KitSpecimen("NotchEmptyView", .notch, variants: [
            KitVariant("empty", "NotchEmptyView(symbol:message:actions:)", width: 320, backdrop: .notch) {
                NotchEmptyView(symbol: "slider.horizontal.3", message: kitText("Adada modül yok", "No modules in the island")) {
                    NotchPillButton(title: L10n.shared.s.menuSettings, prominent: true, action: {})
                }
            },
        ])
    }

    static var notchButtonStyle: KitSpecimen {
        KitSpecimen("NotchButtonStyle", .notch, variants: [
            KitVariant("transport", ".buttonStyle(NotchButtonStyle())", width: 180, backdrop: .notch) {
                HStack(spacing: 8) {
                    ForEach(["backward.fill", "play.fill", "forward.fill"], id: \.self) { symbol in
                        Button {} label: { Image(systemName: symbol).frame(width: 36, height: 30) }
                            .buttonStyle(NotchButtonStyle())
                    }
                }
            },
        ])
    }
}
#endif
