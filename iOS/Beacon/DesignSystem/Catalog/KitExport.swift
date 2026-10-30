// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI
import UIKit

/// `-kitExport 1`: BeaconKit™'s iOS renders (docs/beaconkit.md › iOS). Draws
/// every specimen variant in the dark and the light theme with ImageRenderer
/// at @3x, resolves the colour tokens in both, writes it all to the app's
/// Documents/kit and quits. docs/scripts/kit.sh launches it once per
/// language and copies the folder out of the simulator; the screens it
/// photographs itself (`-screen …`).
///
///     Documents/kit/registry.json                         the specimens and their variants
///     Documents/kit/tokens.json                           the colours, light and dark
///     Documents/kit/components/<theme>/<id>/<variant>.png  + manifest.json (sizes in points)
@MainActor
enum KitExport {
    static var isRequested: Bool { UserDefaults.standard.bool(forKey: "kitExport") }

    /// The width a variant without its own is drawn at: an iPhone 18 Pro's, inside the screen margins.
    static let pageWidth: CGFloat = 402 - 2 * BeaconMetrics.margin

    static func run() {
        let folder = URL.documentsDirectory.appending(path: "kit")
        try? FileManager.default.removeItem(at: folder)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var manifest: [String: [String: Any]] = [:]
        for theme in ["dark", "light"] {
            for specimen in KitCatalog.specimens {
                for variant in specimen.variants {
                    let content = variant.content()
                        .frame(width: variant.width ?? pageWidth, height: variant.height, alignment: .leading)
                        .padding(BeaconMetrics.spacing5)
                        .background(BeaconColor.canvas)
                        .environment(\.colorScheme, theme == "dark" ? .dark : .light)
                    let renderer = ImageRenderer(content: content)
                    renderer.scale = 3
                    guard let image = renderer.uiImage, let png = image.pngData() else { continue }
                    let file = folder.appending(path: "components/\(theme)/\(specimen.id)/\(variant.id).png")
                    try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
                    try? png.write(to: file)
                    manifest["\(theme)/\(specimen.id)/\(variant.id)"] = ["width": image.size.width, "height": image.size.height]
                }
            }
        }
        write(manifest, to: folder.appending(path: "components/manifest.json"))
        write([
            "specimens": KitCatalog.specimens.map { specimen in
                ["id": specimen.id, "category": specimen.category.rawValue,
                 "variants": specimen.variants.map { ["id": $0.id, "title": $0.title] }] as [String: Any]
            },
        ], to: folder.appending(path: "registry.json"))
        write(["colors": BeaconColor.catalog.map { name, color in
            ["id": name, "light": hex(color, .light), "dark": hex(color, .dark)] as [String: Any]
        }], to: folder.appending(path: "tokens.json"))
        print("kit-export: \(manifest.count) images → \(folder.path)")
        exit(0)
    }

    private static func hex(_ color: Color, _ style: UIUserInterfaceStyle) -> [String: Any] {
        let resolved = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let byte = { (value: CGFloat) in String(format: "%02x", Int((min(max(value, 0), 1) * 255).rounded())) }
        return ["hex": "#" + byte(red) + byte(green) + byte(blue), "alpha": (Double(alpha) * 1000).rounded() / 1000]
    }

    private static func write(_ object: Any, to file: URL) {
        try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        if let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: file)
        }
    }
}

extension BeaconColor {
    /// The tokens the catalog lists, by name, in BeaconColor's order.
    @MainActor static let catalog: [(String, Color)] = [
        ("cpu", cpu), ("gpu", gpu), ("memory", memory), ("download", download), ("upload", upload), ("power", power),
        ("temperature", temperature), ("disk", disk), ("fan", fan), ("positive", positive), ("caution", caution),
        ("critical", critical), ("canvas", canvas), ("tile", tile), ("track", track), ("hairline", hairline),
    ]
}
