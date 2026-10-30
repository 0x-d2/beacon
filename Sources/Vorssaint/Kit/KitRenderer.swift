// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

#if VORSSAINT_DEVELOPMENT
import AppKit
import ScreenCaptureKit
import SwiftUI

/// `--kit-render <dir>`: photographs every specimen variant and catalog
/// surface in each language and theme for the BeaconKit™ site
/// (docs/beaconkit.md › Renders; docs/scripts/kit.sh runs it).
///
///     <dir>/export/registry.json                                   the specimens, in render order
///     <dir>/render/components/<lang>/<theme>/<slug>/<variant>.png  + manifest.json (sizes in points)
///     <dir>/render/surfaces/<lang>/<theme>/<surface>.png           + manifest.json
///
/// Each variant is drawn in a borderless window of its own above an opaque
/// backdrop window, both this process's, and photographed from the screen,
/// so a material blurs the backdrop as it would the desktop and AppKit
/// controls draw as they do in the app. Without Screen Recording permission
/// it falls back to the windows alone (materials then come out flat), and
/// says so in the manifest. A render on a 1x screen is refused: the site
/// shows @2x pixels.
enum KitRenderer {
    static func isRequested(by arguments: [String]) -> Bool {
        arguments.contains("--kit-render")
    }

    static func runAndExit() -> Never {
        let options = KitRenderOptions(CommandLine.arguments)
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        // main.swift's top-level code runs on the main thread.
        let host = MainActor.assumeIsolated { KitRenderHost(options: options) }
        DispatchQueue.main.async {
            Task { @MainActor in
                let status = await host.run()
                exit(status)
            }
        }
        app.run()
        exit(0)
    }
}

struct KitRenderOptions {
    var output = URL(fileURLWithPath: "/tmp/beacon-kit")
    var languages: [AppLanguage] = [.tr, .enUS]
    var themes = ["dark", "light"]
    var steps: Set<String> = ["export", "components", "surfaces"]
    var specimens: Set<String> = []

    init(_ arguments: [String]) {
        var index = 0
        while index < arguments.count {
            let argument = arguments[index]
            let value = index + 1 < arguments.count ? arguments[index + 1] : ""
            switch argument {
            case "--kit-render":
                output = URL(fileURLWithPath: value)
                index += 1
            case "--languages":
                languages = value.split(separator: ",").compactMap { $0 == "en" ? .enUS : AppLanguage(rawValue: String($0)) }
                index += 1
            case "--themes":
                themes = value.split(separator: ",").map(String.init).filter { $0 == "dark" || $0 == "light" }
                index += 1
            case "--only":
                steps = Set(value.split(separator: ",").map(String.init) + ["export"])
                index += 1
            case "--specimen":
                specimens.insert(value)
                index += 1
            default:
                break
            }
            index += 1
        }
    }
}

/// A borderless panel that can be key, so controls draw in their active state.
private final class KitRenderPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// The desktop the specimens sit on: a fixed, soft wallpaper, the same in every
/// run, so a translucent material has something to blur.
private final class KitDesktopView: NSView {
    var dark = true { didSet { needsDisplay = true } }

    override func draw(_ dirtyRect: NSRect) {
        let colors: [NSColor] = dark
            ? [NSColor(srgbRed: 0.10, green: 0.16, blue: 0.30, alpha: 1), NSColor(srgbRed: 0.28, green: 0.14, blue: 0.32, alpha: 1), NSColor(srgbRed: 0.08, green: 0.22, blue: 0.24, alpha: 1)]
            : [NSColor(srgbRed: 0.62, green: 0.76, blue: 0.95, alpha: 1), NSColor(srgbRed: 0.93, green: 0.74, blue: 0.86, alpha: 1), NSColor(srgbRed: 0.72, green: 0.90, blue: 0.86, alpha: 1)]
        NSGradient(colors: colors)?.draw(in: bounds, angle: -35)
    }
}

/// A variant or surface on its backdrop, laid out at its width, with the
/// renders' margin around it and no animation.
private struct KitStage: View {
    let width: CGFloat
    let backdrop: KitBackdrop
    let content: AnyView

    static let margin: CGFloat = 16

    var body: some View {
        content
            .frame(width: width, alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: true)
            .environment(\.notchPresentation, backdrop == .notch)
            .padding(Self.margin)
            .background(background)
            .environment(\.colorScheme, backdrop == .notch ? .dark : colorScheme)
            .transaction { transaction in
                transaction.animation = nil
                transaction.disablesAnimations = true
            }
    }

    @Environment(\.colorScheme) private var colorScheme

    @ViewBuilder
    private var background: some View {
        switch backdrop {
        case .panel: Color.clear.panelGlassSurface()
        case .window: Color(nsColor: .windowBackgroundColor)
        case .notch: Color.black
        case .desktop: Color.clear
        }
    }
}

@MainActor
private final class KitRenderHost {
    let options: KitRenderOptions
    private let desktop = KitDesktopView()
    private let backdropWindow: NSWindow
    private let window: KitRenderPanel
    private let hosting = NSHostingView(rootView: AnyView(EmptyView()))
    private var failures = 0
    private var mode = "screen"

    init(options: KitRenderOptions) {
        self.options = options
        backdropWindow = NSWindow(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: false)
        backdropWindow.isOpaque = true
        backdropWindow.hasShadow = false
        backdropWindow.level = .floating
        backdropWindow.contentView = desktop
        window = KitRenderPanel(contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        // A panel hides when its app isn't active, and a renderer `open` starts behind the
        // frontmost app may never be: it stays on screen either way.
        window.hidesOnDeactivate = false
        window.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 1)
        window.contentView = hosting
    }

    func run() async -> Int32 {
        guard let screen = NSScreen.main else { return fail("no screen: the renderer needs a logged-in GUI session") }
        let allowLowScale = ProcessInfo.processInfo.environment["KIT_ALLOW_1X"] == "1"
        guard screen.backingScaleFactor >= 2 || allowLowScale else {
            return fail("the screen is @\(Int(screen.backingScaleFactor))x; the catalog shows @2x renders (a HiDPI display mode, or KIT_ALLOW_1X=1 to try anyway)")
        }
        mode = CGPreflightScreenCaptureAccess() ? "screen" : "window"
        if mode == "window" {
            print("! no Screen Recording permission: materials will come out flat (System Settings › Privacy & Security › Screen & System Audio Recording)")
        }
        SystemMonitor.shared.freezeForKit(KitFixtures.snapshot)
        let specimens = KitCatalog.specimens.filter { options.specimens.isEmpty || options.specimens.contains($0.id) || options.specimens.contains($0.slug) }

        writeRegistry(specimens)
        backdropWindow.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        var components: [String: [String: Any]] = [:]
        var surfaces: [String: [String: Any]] = [:]
        for language in options.languages {
            L10n.shared.language = language
            let lang = language == .tr ? "tr" : "en"
            for theme in options.themes {
                let appearance = NSAppearance(named: theme == "dark" ? .darkAqua : .aqua)
                NSApp.appearance = appearance
                window.appearance = appearance
                backdropWindow.appearance = appearance
                desktop.dark = theme == "dark"
                try? await Task.sleep(nanoseconds: 300_000_000)
                if options.steps.contains("components") {
                    for specimen in specimens {
                        for variant in specimen.variants {
                            let key = "\(lang)/\(theme)/\(specimen.slug)/\(variant.id)"
                            let file = options.output.appendingPathComponent("render/components/\(key).png")
                            if let size = await render(width: variant.width, backdrop: variant.backdrop, capture: variant.capture,
                                                       theme: theme, content: variant.content, to: file) {
                                components[key] = ["width": size.width, "height": size.height, "mode": variant.capture == .imageRenderer ? "imageRenderer" : mode]
                                print("  ✓ \(key)")
                            }
                        }
                    }
                }
                if options.steps.contains("surfaces"), options.specimens.isEmpty {
                    for surface in KitCatalog.surfaces {
                        let key = "\(lang)/\(theme)/\(surface.id)"
                        let file = options.output.appendingPathComponent("render/surfaces/\(key).png")
                        if let size = await render(width: surface.width, backdrop: surface.backdrop, capture: .screen,
                                                   theme: theme, content: surface.content, to: file, settle: 600_000_000) {
                            surfaces[key] = ["width": size.width, "height": size.height, "mode": mode]
                            print("  ✓ \(key)")
                        }
                    }
                }
            }
        }
        merge(components, into: options.output.appendingPathComponent("render/components/manifest.json"))
        merge(surfaces, into: options.output.appendingPathComponent("render/surfaces/manifest.json"))
        print("\(components.count) component images, \(surfaces.count) surface images, \(failures) failed (\(mode) capture)")
        return failures > 0 ? 1 : 0
    }

    /// Lays one view out in the render window, waits for it to settle and
    /// photographs it. The size returned is in points.
    private func render(width: CGFloat, backdrop: KitBackdrop, capture: KitCapture, theme: String,
                        content: () -> AnyView, to file: URL, settle: UInt64 = 180_000_000) async -> CGSize? {
        let stage = KitStage(width: width, backdrop: backdrop, content: content())
        if capture == .imageRenderer {
            let renderer = ImageRenderer(content: stage.environment(\.colorScheme, theme == "dark" ? .dark : .light))
            renderer.scale = 2
            guard let image = renderer.cgImage else { return failed(file, "ImageRenderer drew nothing") }
            return write(image, to: file) ? CGSize(width: CGFloat(image.width) / 2, height: CGFloat(image.height) / 2) : nil
        }
        hosting.rootView = AnyView(stage)
        hosting.layoutSubtreeIfNeeded()
        let size = hosting.fittingSize
        guard size.width > 0, size.height > 0 else { return failed(file, "empty layout") }
        guard let screen = NSScreen.main else { return failed(file, "no screen") }
        let visible = screen.visibleFrame
        guard size.height <= visible.height - 80 else { return failed(file, "taller than the screen (\(Int(size.height)) pt)") }
        let frame = NSRect(x: visible.minX + 40, y: visible.maxY - 40 - size.height, width: size.width, height: size.height)
        window.setFrame(frame, display: true)
        backdropWindow.setFrame(frame.insetBy(dx: -40, dy: -40), display: true)
        window.makeKeyAndOrderFront(nil)
        try? await Task.sleep(nanoseconds: settle)
        window.displayIfNeeded()
        // What the capture needs, read here on the main thread; the capture itself runs off it.
        let target = KitCaptureTarget(
            frame: frame,
            display: screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
            scale: screen.backingScaleFactor,
            mainHeight: NSScreen.screens.first?.frame.height ?? screen.frame.height,
            windows: [CGWindowID(window.windowNumber), CGWindowID(backdropWindow.windowNumber)],
            mode: mode
        )
        do {
            let image = try await withTimeout(seconds: 10) { try await target.capture() }
            return write(image, to: file) ? size : nil
        } catch {
            return failed(file, "\(error)")
        }
    }

    private func write(_ image: CGImage, to file: URL) -> Bool {
        let rep = NSBitmapImageRep(cgImage: image)
        guard let data = rep.representation(using: .png, properties: [:]) else { return failed(file, "PNG encoding") != nil }
        do {
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: file)
            return true
        } catch {
            return failed(file, "\(error)") != nil
        }
    }

    private func writeRegistry(_ specimens: [KitSpecimen]) {
        let registry: [String: Any] = [
            "specimens": KitCatalog.specimens.map { specimen in
                [
                    "id": specimen.id, "slug": specimen.slug, "category": specimen.category.rawValue,
                    "variants": specimen.variants.map {
                        ["id": $0.id, "title": $0.title, "capture": $0.capture.rawValue, "backdrop": $0.backdrop.rawValue, "width": $0.width] as [String: Any]
                    },
                ] as [String: Any]
            },
            "surfaces": KitCatalog.surfaces.map { ["id": $0.id] },
        ]
        let file = options.output.appendingPathComponent("export/registry.json")
        try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        if let data = try? JSONSerialization.data(withJSONObject: registry, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: file)
        }
    }

    /// Adds this run's entries to the manifest on disk: a run of some specimens keeps the others' images.
    private func merge(_ entries: [String: [String: Any]], into file: URL) {
        guard !entries.isEmpty else { return }
        var manifest = (try? Data(contentsOf: file)).flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] } ?? [:]
        for (key, value) in entries { manifest[key] = value }
        try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        if let data = try? JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: file)
        }
    }

    private func failed(_ file: URL, _ reason: String) -> CGSize? {
        failures += 1
        print("  ✘ \(file.path.components(separatedBy: "/render/").last ?? file.lastPathComponent): \(reason)")
        return nil
    }

    private func fail(_ reason: String) -> Int32 {
        print("kit-render: \(reason)")
        return 2
    }
}

/// One photograph: the screen region under `frame` (every window there, ours
/// on top), or without permission our two windows alone.
private struct KitCaptureTarget: Sendable {
    let frame: NSRect
    let display: CGDirectDisplayID?
    let scale: CGFloat
    let mainHeight: CGFloat
    let windows: Set<CGWindowID>
    let mode: String

    func capture() async throws -> CGImage {
        let content: SCShareableContent
        if mode == "window", #available(macOS 14.4, *) {
            content = try await SCShareableContent.currentProcess
        } else {
            content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        }
        guard let screen = content.displays.first(where: { $0.displayID == display }) ?? content.displays.first else {
            throw KitRenderError.noDisplay
        }
        let filter = mode == "window"
            ? SCContentFilter(display: screen, including: content.windows.filter { windows.contains($0.windowID) })
            : SCContentFilter(display: screen, excludingWindows: [])
        let configuration = SCStreamConfiguration()
        // Points from the display's top-left corner (AppKit counts from the main screen's bottom).
        configuration.sourceRect = CGRect(x: frame.minX - screen.frame.minX,
                                          y: mainHeight - frame.maxY - screen.frame.minY,
                                          width: frame.width, height: frame.height)
        configuration.width = Int((frame.width * scale).rounded())
        configuration.height = Int((frame.height * scale).rounded())
        configuration.showsCursor = false
        configuration.captureResolution = .best
        configuration.colorSpaceName = CGColorSpace.sRGB
        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
    }
}

private enum KitRenderError: Error {
    case noDisplay
    case timedOut
}

/// The operation, or an error once `seconds` pass: a capture that waits on a
/// permission prompt nobody will answer must not hang an unattended run.
private func withTimeout<T: Sendable>(seconds: Double, _ operation: @escaping @Sendable () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw KitRenderError.timedOut
        }
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}
#endif
