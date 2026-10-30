// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

#if VORSSAINT_DEVELOPMENT
import SwiftUI

/// The Settings detail column's width at the window's minimum size.
private let settingsWidth: CGFloat = 520

extension KitSpecimen {
    static var settingsCard: KitSpecimen {
        KitSpecimen("SettingsCard", .settings, variants: [
            KitVariant("titled", "SettingsCard(title:)", width: settingsWidth, backdrop: .window) {
                SettingsCard(title: L10n.shared.s.tabGeneral) {
                    SettingsRow(symbol: "power", title: L10n.shared.s.launchAtLogin) {
                        Toggle("", isOn: .constant(true)).toggleStyle(.switch).labelsHidden()
                    }
                    SettingsRow(symbol: "circle.lefthalf.filled", title: kitText("Görünüm", "Appearance"),
                                caption: kitText("Sistemle aynı, açık ya da koyu", "As the system, light or dark")) {
                        Toggle("", isOn: .constant(false)).toggleStyle(.switch).labelsHidden()
                    }
                }
            },
            KitVariant("untitled", "SettingsCard()", width: settingsWidth, backdrop: .window) {
                SettingsCard {
                    SettingsRow(symbol: "chart.line.uptrend.xyaxis", title: L10n.shared.s.tabMonitor) {
                        Toggle("", isOn: .constant(true)).toggleStyle(.switch).labelsHidden()
                    }
                }
            },
        ])
    }

    static var settingsRow: KitSpecimen {
        KitSpecimen("SettingsRow", .settings, variants: [
            KitVariant("toggle", "SettingsRow(symbol:title:accessory:)", width: settingsWidth, backdrop: .window) {
                SettingsRow(symbol: "moon.zzz.fill", title: L10n.shared.s.keepAwakeTitle) {
                    Toggle("", isOn: .constant(true)).toggleStyle(.switch).labelsHidden()
                }
            },
            KitVariant("caption", #"caption:, badge: "BETA""#, width: settingsWidth, backdrop: .window) {
                SettingsRow(symbol: "record.circle", title: kitText("Ekran kaydı", "Screen recording"), badge: "BETA",
                            caption: kitText("Bir pencereyi ya da alanı videoya kaydeder.", "Records a window or an area to video.")) {
                    Button(kitText("Aç", "Open")) {}
                }
            },
            KitVariant("menuBarGlyph", "symbol: nil", width: settingsWidth, backdrop: .window) {
                SettingsRow(symbol: nil, title: kitText("Menü çubuğu simgesi", "Menu bar icon")) {
                    Toggle("", isOn: .constant(true)).toggleStyle(.switch).labelsHidden()
                }
            },
        ])
    }

    static var settingsChoiceRow: KitSpecimen {
        KitSpecimen("SettingsChoiceRow", .settings, variants: [
            KitVariant("segments", "SettingsChoiceRow(symbol:title:selection:options:)", width: settingsWidth, backdrop: .window) {
                SettingsChoiceRow(symbol: "timer", title: kitText("Yenileme aralığı", "Refresh interval"), selection: .constant(2)) {
                    Text("1 s").tag(1)
                    Text("2 s").tag(2)
                    Text("5 s").tag(5)
                }
            },
        ])
    }

    static var settingsMenuRow: KitSpecimen {
        KitSpecimen("SettingsMenuRow", .settings, variants: [
            KitVariant("menu", "SettingsMenuRow(symbol:title:selection:options:)", width: settingsWidth, backdrop: .window) {
                SettingsMenuRow(symbol: "thermometer.medium", title: kitText("Sıcaklık birimi", "Temperature unit"), selection: .constant("c")) {
                    Text("°C").tag("c")
                    Text("°F").tag("f")
                }
            },
        ])
    }

    static var trailingSwitchToggleStyle: KitSpecimen {
        KitSpecimen("TrailingSwitchToggleStyle", .settings, variants: [
            KitVariant("on", ".toggleStyle(TrailingSwitchToggleStyle())", width: settingsWidth, backdrop: .window) {
                Toggle(kitText("Bildirim göster", "Show a notification"), isOn: .constant(true))
                    .toggleStyle(TrailingSwitchToggleStyle())
            },
        ])
    }
}
#endif
