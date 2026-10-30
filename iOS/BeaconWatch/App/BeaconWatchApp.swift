// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Beacon on the Apple Watch: the paired Macs' readings, read through the
/// iPhone (iOS/README.md › Apple Watch).
@main
struct BeaconWatchApp: App {
    @State private var model = WatchModel(demoOnly: ProcessInfo.processInfo.arguments.contains("-demo"))
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MacListView()
                .environment(model)
                // The complication opens its Mac.
                .onOpenURL { model.open(link: $0) }
                .task {
                    // For the simulator and the screenshots: `-screen dashboard`, `-screen cpu`…
                    if let screen = UserDefaults.standard.string(forKey: "screen") { model.open(screen: screen) }
                }
        }
        // Wrist down (inactive) the readings still come, for the always-on screen; in the background they stop.
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { model.setPaused(true) }
            if phase == .active { model.setPaused(false) }
        }
    }
}
