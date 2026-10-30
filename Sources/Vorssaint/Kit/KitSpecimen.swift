// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

#if VORSSAINT_DEVELOPMENT
import SwiftUI

/// One component as the BeaconKit™ catalog shows it (docs/beaconkit.md ›
/// Renders): its catalog id (the type's name, or `.modifier()` for a view
/// modifier, as web/collector/components.ts names it), its category and the
/// ways it is drawn. The specimens live apart from the components, in
/// Kit/Specimens/, so the upstream files stay untouched.
struct KitSpecimen {
    let id: String
    let category: KitCategory
    let variants: [KitVariant]

    init(_ id: String, _ category: KitCategory, variants: [KitVariant]) {
        self.id = id
        self.category = category
        self.variants = variants
    }

    /// The id as a folder name: `.panelCard()` → `panelCard`.
    var slug: String {
        String(id.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) })
    }
}

enum KitCategory: String {
    case shared, panel, charts, settings, notch, tools
}

/// One way a component is drawn: a kind, a state or a size.
struct KitVariant {
    /// Letters, digits, `.` and `-`: it names the image file and the site's anchor.
    let id: String
    /// The API that makes the variant (`kind: .high`), the same in both languages.
    let title: String
    /// The width the variant is laid out at; the height is the content's own.
    /// 308 is the menu panel's content width.
    var width: CGFloat = 308
    var backdrop: KitBackdrop = .panel
    var capture: KitCapture = .screen
    let content: () -> AnyView

    init(_ id: String, _ title: String, width: CGFloat = 308, backdrop: KitBackdrop = .panel,
         capture: KitCapture = .screen, @ViewBuilder content: @escaping () -> some View) {
        self.id = id
        self.title = title
        self.width = width
        self.backdrop = backdrop
        self.capture = capture
        self.content = { AnyView(content()) }
    }
}

/// What a variant sits on, as it does in the app.
enum KitBackdrop: String {
    /// The menu panel: its glass (`.panelGlassSurface()`) over the desktop.
    case panel
    /// A window's own background: the Settings pages.
    case window
    /// The Dynamic Island: black, always in the dark appearance.
    case notch
    /// The desktop alone: floating tools bring their own material.
    case desktop
}

/// How the renderer photographs a variant.
enum KitCapture: String {
    /// The screen itself, with every material and AppKit control as drawn.
    case screen
    /// `ImageRenderer`: plain SwiftUI shapes only (no materials, no AppKit).
    case imageRenderer
}

/// One whole surface the catalog shows (a panel tab, a Settings page), by the
/// id web/collector/surfaces.ts gives it (`panel.system`, `settings.monitor`).
struct KitSurface {
    let id: String
    var width: CGFloat
    var backdrop: KitBackdrop
    let content: () -> AnyView

    init(_ id: String, width: CGFloat, backdrop: KitBackdrop, @ViewBuilder content: @escaping () -> some View) {
        self.id = id
        self.width = width
        self.backdrop = backdrop
        self.content = { AnyView(content()) }
    }
}

/// Copy a specimen shows that the app's tables don't have, in both languages.
/// Sample data only; what the app itself says comes from `L10n`.
func kitText(_ tr: String, _ en: String) -> String {
    L10n.shared.language == .tr ? tr : en
}
#endif
