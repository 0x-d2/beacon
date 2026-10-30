// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

// The system colours the app names (`.green`, `.secondary`, `Color.accentColor`), resolved the way this Mac draws
// them in Aqua and Dark Aqua, for the BeaconKit™ catalog (docs/beaconkit.md › Colours). The high-contrast
// appearances resolve to the same values here (macOS 27), so they are left out rather than shown as if they differed.
// The catalog's own tokens.json resolves the app's tokens at render time; this covers the system's, which the source
// only names. Run on a Mac after a macOS update and commit the result:
//
//   swift docs/scripts/kit-system-colors.swift > web/collector/system-colors.json
import AppKit

let colors: [(String, NSColor)] = [
    ("red", .systemRed), ("orange", .systemOrange), ("yellow", .systemYellow), ("green", .systemGreen),
    ("mint", .systemMint), ("teal", .systemTeal), ("cyan", .systemCyan), ("blue", .systemBlue),
    ("indigo", .systemIndigo), ("purple", .systemPurple), ("pink", .systemPink), ("brown", .systemBrown),
    ("gray", .systemGray), ("accentColor", .controlAccentColor), ("primary", .labelColor),
    ("secondary", .secondaryLabelColor), ("tertiary", .tertiaryLabelColor), ("quaternary", .quaternaryLabelColor),
    ("separator", .separatorColor), ("windowBackground", .windowBackgroundColor),
    ("controlBackground", .controlBackgroundColor), ("underPageBackground", .underPageBackgroundColor),
    ("white", .white), ("black", .black), ("clear", .clear),
]
let appearances: [(String, NSAppearance.Name)] = [("light", .aqua), ("dark", .darkAqua)]

func hex(_ color: NSColor) -> [String: Any] {
    let rgb = color.usingColorSpace(.sRGB) ?? .black
    let channel = { (value: CGFloat) in String(format: "%02x", Int((min(max(value, 0), 1) * 255).rounded())) }
    return ["hex": "#" + channel(rgb.redComponent) + channel(rgb.greenComponent) + channel(rgb.blueComponent),
            "alpha": (Double(rgb.alphaComponent) * 1000).rounded() / 1000]
}

var out: [String: Any] = [:]
for (name, color) in colors {
    var values: [String: Any] = [:]
    for (key, appearanceName) in appearances {
        NSAppearance(named: appearanceName)?.performAsCurrentDrawingAppearance { values[key] = hex(color) }
    }
    out[name] = values
}
let info = ProcessInfo.processInfo.operatingSystemVersion
let document: [String: Any] = [
    "macOS": "\(info.majorVersion).\(info.minorVersion).\(info.patchVersion)",
    "accent": "The viewer's accent setting at the time of the run (Multicolor: blue).",
    "colors": out,
]
let data = try JSONSerialization.data(withJSONObject: document, options: [.prettyPrinted, .sortedKeys])
print(String(decoding: data, as: UTF8.self))
