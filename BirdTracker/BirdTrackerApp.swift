//
//  BirdTrackerApp.swift
//  BirdTracker
//
//  Created by Calvin Buckley on 2025-08-22.
//

import SwiftUI

@main
struct BirdTrackerApp: App {
    @State var player = ModulePlayer()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.player, player)
        }
    }
}

extension EnvironmentValues {
    var player: ModulePlayer {
        get { self[PlayerKey.self] }
        set { self[PlayerKey.self] = newValue }
    }
}

private struct PlayerKey: EnvironmentKey {
    static let defaultValue: ModulePlayer = ModulePlayer()
}
