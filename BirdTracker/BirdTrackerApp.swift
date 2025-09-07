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
    @FocusedValue(\.focusedInspectorMode) private var focusedInspectorMode
    
    var body: some Scene {
        DocumentGroup(viewing: ModuleState.self) { file in
            ContentView(moduleState: file.document)
                .environment(\.player, player)
        }
        .commands {
            CommandGroup(before: .sidebar) {
                if let focusedModule, let focusedInspectorMode {
                    Picker(selection: focusedInspectorMode) {
                        Text("None").tag(ContentView.InspectorMode.none)
                            .keyboardShortcut("0")
                        Text("Sequences").tag(ContentView.InspectorMode.orders)
                            .keyboardShortcut("1")
                        Text("Patterns").tag(ContentView.InspectorMode.patterns)
                            .keyboardShortcut("2")
                        Text("Samples").tag(ContentView.InspectorMode.samples)
                            .keyboardShortcut("3")
                        if focusedModule.module.instrumentCount > 1 {
                            Text("Instruments").tag(ContentView.InspectorMode.instruments)
                                .keyboardShortcut("4")
                        }
                        Text("Metadata").tag(ContentView.InspectorMode.metadata)
                            .keyboardShortcut("5")
                    } label: {
                        Label("Inspector", systemImage: "info.circle")
                    }
                    .pickerStyle(.menu)
                    Divider()
                }
            }
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
    var focusedInspectorMode: Binding<ContentView.InspectorMode>? {
        get { self[FocusedInspectorModeKey.self] }
        set { self[FocusedInspectorModeKey.self] = newValue }
    }
}

private struct FocusedModuleKey: FocusedValueKey {
    typealias Value = ModuleState
}

private struct FocusedInspectorModeKey: FocusedValueKey {
    typealias Value = Binding<ContentView.InspectorMode>
}
