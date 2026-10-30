// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Beacon's BeaconKit™ catalog, the iOS side of the Mac app's (docs/beaconkit.md):
/// each component declares itself once, beside its code, with its variants,
/// and that one declaration feeds the Xcode previews (`#Preview { … .preview() }`)
/// and the in-app gallery (Settings › Design catalog).
struct KitSpecimen: Identifiable {
    let id: String
    let category: KitCategory
    let variants: [KitVariant]

    init(_ id: String, _ category: KitCategory, _ variants: [KitVariant]) {
        self.id = id
        self.category = category
        self.variants = variants
    }

    /// Every variant, titled, on the app's canvas: what a preview and the gallery show.
    @MainActor func preview() -> some View {
        KitSpecimenPage(specimen: self)
    }
}

enum KitCategory: String, CaseIterable, Identifiable {
    case tiles, instruments, badges, rows

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .tiles: return "Tiles"
        case .instruments: return "Instruments"
        case .badges: return "Badges"
        case .rows: return "Rows and states"
        }
    }
}

struct KitVariant: Identifiable {
    let id: String
    /// The API that makes it, the same in every language.
    let title: String
    /// The width it's laid out at; nil fills the page's.
    var width: CGFloat?
    var height: CGFloat?
    let content: () -> AnyView

    init(_ id: String, _ title: String, width: CGFloat? = nil, height: CGFloat? = nil, @ViewBuilder content: @escaping () -> some View) {
        self.id = id
        self.title = title
        self.width = width
        self.height = height
        self.content = { AnyView(content()) }
    }
}

enum KitCatalog {
    @MainActor static let specimens: [KitSpecimen] = [
        .metricTile, .gaugeRing, .sparkChart, .levelBar, .coreGrid, .pressureBadge, .statusPill, .statRow, .emptyState,
    ]
}

private struct KitSpecimenPage: View {
    let specimen: KitSpecimen

    var body: some View {
        VStack(alignment: .leading, spacing: BeaconMetrics.spacing5) {
            ForEach(specimen.variants) { variant in
                VStack(alignment: .leading, spacing: BeaconMetrics.spacing3) {
                    Text(variant.title).font(.caption.monospaced()).foregroundStyle(.secondary)
                    variant.content()
                        .frame(width: variant.width, height: variant.height, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityIdentifier("kit.variant.\(variant.id)")
            }
        }
        .padding(BeaconMetrics.margin)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BeaconColor.canvas)
    }
}

/// Settings › Design catalog: every component in every variant, live, in
/// the theme and type size the phone is set to.
struct KitGalleryView: View {
    var body: some View {
        List {
            ForEach(KitCategory.allCases) { category in
                Section(category.title) {
                    ForEach(KitCatalog.specimens.filter { $0.category == category }) { specimen in
                        NavigationLink(specimen.id) {
                            ScrollView { specimen.preview() }
                                .background(BeaconColor.canvas)
                                .navigationTitle(specimen.id)
                                .navigationBarTitleDisplayMode(.inline)
                        }
                        .font(.body.monospaced())
                    }
                }
            }
        }
        .navigationTitle("Design catalog")
    }
}

#Preview("Gallery") { NavigationStack { KitGalleryView() } }
