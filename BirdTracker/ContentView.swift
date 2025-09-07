//
//  ContentView.swift
//  BirdTracker
//
//  Created by Calvin Buckley on 2025-08-22.
//

import SwiftUI
import openmpt

struct ContentView: View {
    @Environment(\.player) private var player
    
    @State var showInspector = false
    
    var moduleState: ModuleState
    
    var module: Module {
        moduleState.module
    }
    
    var body: some View {
        // subtitle used for displaying time and position
        let subtitle = "\(String(timeInterval: moduleState.position))/\(String(timeInterval: moduleState.duration)) \(moduleState.currentPattern)/\(moduleState.currentRow)"
        
        VStack {
            let pattern = module.patterns[Int(moduleState.currentPattern)]
            PatternViewer(moduleState: moduleState, pattern: pattern, highlightedRow: moduleState.currentRow)
                .environment(\.player, player)
                .inspector(isPresented: $showInspector) {
                    TabView {
                        List(module.samples) {
                            Text($0.name)
                        }
                        .monospaced()
                        .tabItem {
                            Text("Samples")
                        }
                        if module.instrumentCount > 0 {
                            List(module.instruments) {
                                Text($0.name)
                            }
                            .monospaced()
                            .tabItem {
                                Text("Instruments")
                            }
                        }
                    }
                    .tabViewStyle(.grouped)
                }
        }
        .toolbar {
            ToolbarItemGroup {
                if player.playing {
                    Button("Pause", systemImage: "pause") {
                        player.pause()
                    }
                } else {
                    Button("Play", systemImage: "play") {
                        if player.currentModule != moduleState.module {
                            player.currentModuleState = moduleState
                        }
                        player.play()
                    }
                }
            }
            ToolbarItem(id: "positionSlider") {
                // as we can't bind directly to player
                Slider(value: Binding(get: {
                    moduleState.position
                }, set: { newValue in
                    moduleState.module.position = newValue
                    moduleState.position = newValue // if paused
                }), in: 0...moduleState.duration) {
                    Text("Position")
                }
                .frame(minWidth: 200)
            }
            ToolbarItem(id: "volumeSlider") {
                Slider(value: Binding(get: {
                    player.volume
                }, set: { newValue in
                    player.volume = newValue
                }), in: 0...1) {
                    Text("Volume")
                }
                .frame(minWidth: 200)
            }
            ToolbarItem(id: "inspector") {
                Toggle(isOn: $showInspector) {
                    Label("Inspector", systemImage: "info.circle")
                }
            }
        }
        .navigationSubtitle(subtitle)
        .focusedSceneValue(\.focusedModule, moduleState)
    }
}
