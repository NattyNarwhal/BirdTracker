//
//  BirdTrackerApp.swift
//  BirdTracker
//
//  Created by Calvin Buckley on 2025-08-22.
//

import SwiftUI

@main
struct BirdTrackerApp: App {
    @Environment(\.player) private var player
    
    @FocusedValue(\.focusedModule) private var focusedModule
    
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
                } else if let focusedModule {
                    Button("Play") {
                        player.currentModuleState = focusedModule
                        player.play()
                    }
                    .keyboardShortcut(.space, modifiers: [])
                } else {
                    Button("Play") { }
                    .keyboardShortcut(.space, modifiers: [])
                    .disabled(true)
                }
                Button("Stop") {
                    player.currentModuleState = nil
                }
                .keyboardShortcut(".")
                .disabled(!moduleLoaded)
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

extension FocusedValues {
    var focusedModule: ModuleState? {
        get { self[FocusedModuleKey.self] }
        set { self[FocusedModuleKey.self] = newValue }
    }
}

private struct FocusedModuleKey: FocusedValueKey {
    typealias Value = ModuleState
}
