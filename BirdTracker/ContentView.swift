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
    
    var moduleState: ModuleState
    
    var module: Module {
        moduleState.module
    }
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    if player.currentModule != moduleState.module {
                        player.currentModuleState = moduleState
                    }
                    player.play()
                } label: {
                    Text("Play")
                }
                Button {
                    player.pause()
                } label: {
                    Text("Pause")
                }
                // as we can't bind directly to player
                Slider(value: Binding(get: {
                    moduleState.position
                }, set: { newValue in
                    moduleState.module.position = newValue
                    moduleState.position = newValue // if paused
                }), in: 0...moduleState.duration)
                Slider(value: Binding(get: {
                    player.volume
                }, set: { newValue in
                    player.volume = newValue
                }), in: 0...1)
            }
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
            Text("\(moduleState.currentPattern)/\(moduleState.currentRow)")
            let pattern = module.patterns[Int(moduleState.currentPattern)]
            PatternViewer(moduleState: moduleState, pattern: pattern, highlightedRow: moduleState.currentRow)
                .environment(\.player, player)
        }
        .focusedSceneValue(\.focusedModule, moduleState)
        .padding()
    }
}
