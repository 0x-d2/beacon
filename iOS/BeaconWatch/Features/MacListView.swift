// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// The first screen: the Macs the iPhone has paired, or, with none yet, where
/// to pair one and a way to look around with the demo Mac. With one Mac the
/// app opens straight on it (WatchModel).
struct MacListView: View {
    @Environment(WatchModel.self) private var model

    var body: some View {
        @Bindable var model = model
        NavigationStack(path: $model.path) {
            Group {
                if model.macs.isEmpty {
                    ScrollView {
                        EmptyState(symbol: "macbook.and.iphone", title: "No Macs yet",
                                   message: "Pair a Mac in Beacon on your iPhone and it shows up here.") {
                            Button("Try with sample data") { model.path = [.mac(model.demo.id)] }
                        }
                    }
                } else {
                    List(model.macs) { mac in
                        NavigationLink(value: WatchRoute.mac(mac.id)) {
                            Label(mac.name, systemImage: "desktopcomputer").lineLimit(2)
                        }
                    }
                }
            }
            .navigationTitle("Macs")
            .navigationDestination(for: WatchRoute.self) { route in
                switch route {
                case let .mac(id):
                    if let state = model.state(for: id) { WatchDashboardView(state: state) }
                case let .metric(id, kind):
                    if let state = model.state(for: id) { WatchMetricView(state: state, kind: kind) }
                }
            }
        }
    }
}

#Preview("Empty") {
    MacListView().environment(WatchModel(demoOnly: true))
}
