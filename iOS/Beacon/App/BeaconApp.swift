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
                // The Mac's QR code is a beacon:// link: the Camera app hands it here too. Anything can open
                // such a link, so it's shown for the owner to confirm, never saved on its own.
                .onOpenURL { url in model.propose(link: url.absoluteString) }
                .task {
                    // BeaconKit™'s renders (`-kitExport 1`): draw every specimen, write them out, quit.
                    if KitExport.isRequested { KitExport.run() }
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
