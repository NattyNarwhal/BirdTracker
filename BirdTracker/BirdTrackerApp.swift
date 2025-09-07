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
        DocumentGroup(viewing: ModuleState.self) { file in
            ContentView(moduleState: file.document)
                .environment(\.player, player)
        }
        .commands {
            CommandMenu("Playback") {
                let moduleLoaded = player.currentModuleState != nil
                if moduleLoaded && player.playing {
                    Button("Pause") {
                        player.pause()
                    }
                    .keyboardShortcut(.space, modifiers: [])
                } else if moduleLoaded {
                    Button("Play") {
                        player.play()
                    }
                    .keyboardShortcut(.space, modifiers: [])
                }
            }
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
