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
    
    // for visionOS inspector window
    
    var body: some Scene {
        DocumentGroup(viewing: ModuleState.self) { file in
            ContentView(moduleState: file.document)
                .environment(\.player, player)
        }
        .commands {
            #if !os(visionOS)
            CommandGroup(before: .sidebar) {
                if let focusedModule, let focusedInspectorMode {
                    Picker(selection: focusedInspectorMode) {
                        Text("None").tag(InspectorMode.none)
                            .keyboardShortcut("0")
                        Text("Sequences").tag(InspectorMode.orders)
                            .keyboardShortcut("1")
                        Text("Patterns").tag(InspectorMode.patterns)
                            .keyboardShortcut("2")
                        Text("Samples").tag(InspectorMode.samples)
                            .keyboardShortcut("3")
                        if focusedModule.module.instrumentCount > 1 {
                            Text("Instruments").tag(InspectorMode.instruments)
                                .keyboardShortcut("4")
                        }
                        Text("Metadata").tag(InspectorMode.metadata)
                            .keyboardShortcut("5")
                    } label: {
                        Label("Inspector", systemImage: "info.circle")
                    }
                    .pickerStyle(.menu)
                    Divider()
                }
            }
            #endif
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
        
        #if os(visionOS)
        WindowGroup(for: ModuleStateRef.self) { $ref in
            let moduleState = ref!.take()
            InspectorWindow(moduleState: moduleState)
        }
        .windowResizability(.contentSize)
        .windowStyle(.plain)
        #endif
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
    var focusedInspectorMode: Binding<InspectorMode>? {
        get { self[FocusedInspectorModeKey.self] }
        set { self[FocusedInspectorModeKey.self] = newValue }
    }
}

private struct FocusedModuleKey: FocusedValueKey {
    typealias Value = ModuleState
}

private struct FocusedInspectorModeKey: FocusedValueKey {
    typealias Value = Binding<InspectorMode>
}
