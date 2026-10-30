// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

#if VORSSAINT_DEVELOPMENT
import SwiftUI

extension KitSpecimen {
    static var sparkline: KitSpecimen {
        let snapshot = KitFixtures.snapshot
        return KitSpecimen("Sparkline", .charts, variants: [
            KitVariant("cpu", "Sparkline(values:color: PanelMetricColor.green)") {
                KitSchemed { scheme in
                    Sparkline(values: snapshot.cpuHistory, color: PanelMetricColor.green(for: scheme), maxValue: 1)
                        .frame(height: 44)
                        .panelCard()
                }
            },
            KitVariant("network", "color: PanelMetricColor.cyan") {
                KitSchemed { scheme in
                    Sparkline(values: snapshot.netDownHistory, color: PanelMetricColor.cyan(for: scheme))
                        .frame(height: 44)
                        .panelCard()
                }
            },
            KitVariant("baseline", "showsZeroBaseline: true", capture: .imageRenderer) {
                KitSchemed { scheme in
                    Sparkline(values: snapshot.systemPowerHistory, color: PanelMetricColor.orange(for: scheme), showsZeroBaseline: true)
                        .frame(height: 44)
                }
            },
        ])
    }

    static var usageBar: KitSpecimen {
        KitSpecimen("UsageBar", .charts, variants: [
            KitVariant("low", "fraction: 0.23") { UsageBar(fraction: 0.23).panelCard() },
            KitVariant("high", "fraction: 0.72") { UsageBar(fraction: 0.72).panelCard() },
            KitVariant("critical", "fraction: 0.93") { UsageBar(fraction: 0.93).panelCard() },
        ])
    }

    static var pressureIndicator: KitSpecimen {
        KitSpecimen("PressureIndicator", .charts, variants: [
            KitVariant("normal", "pressure: .normal", width: 140) { PressureIndicator(pressure: .normal) },
            KitVariant("warning", "pressure: .warning", width: 140) { PressureIndicator(pressure: .warning) },
            KitVariant("critical", "pressure: .critical", width: 140) { PressureIndicator(pressure: .critical) },
        ])
    }

    static var cpuCoreMatrix: KitSpecimen {
        KitSpecimen("CPUCoreMatrix", .charts, variants: [
            KitVariant("ten", "usage: 10 cores") { CPUCoreMatrix(usage: KitFixtures.snapshot.cpuCoreUsage).panelCard() },
        ])
    }

    static var notchMeter: KitSpecimen {
        KitSpecimen("NotchMeter", .charts, variants: [
            KitVariant("level", "NotchMeter(value: 0.6)", width: 220, backdrop: .notch) { NotchMeter(value: 0.6) },
            KitVariant("tinted", "tint: .green", width: 220, backdrop: .notch) { NotchMeter(value: 0.35, tint: .green) },
        ])
    }
}
#endif
