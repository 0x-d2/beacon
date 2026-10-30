// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

@main
struct BeaconApp: App {
    @State private var model = AppModel(demoOnly: ProcessInfo.processInfo.arguments.contains("-demo"))
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MacsView()
                .environment(model)
                // The Mac's QR code is a beacon:// link: the Camera app hands it here too.
                .onOpenURL { url in model.pair(link: url.absoluteString) }
                .task {
                    // Launch arguments for the simulator and the catalog's renders: `-screen dashboard`, `-pair <link>`.
                    if let screen = UserDefaults.standard.string(forKey: "screen") { model.open(screen: screen) }
                    if let link = UserDefaults.standard.string(forKey: "pair") { model.pair(link: link) }
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { model.pauseAll() }
        }
    }
}
