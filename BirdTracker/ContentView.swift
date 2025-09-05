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
    
    @State var showOpenDialog = false
    
    var body: some View {
        VStack {
            Button {
                showOpenDialog = true
            } label: {
                Text("Load")
            }
            .fileImporter(isPresented: $showOpenDialog, allowedContentTypes: Module.supportedTypes()) { result in
                switch result {
                case .success(let resultURL):
                    if let handle = try? FileHandle(forReadingFrom: resultURL),
                       let module = try? Module(fileHandle: handle) {
                        player.currentModule = module
                    }
                default:
                    break
                }
                showOpenDialog = false
            }
            Button {
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
                player.position
            }, set: { newValue in
                player.currentModule?.position = newValue
                player.position = newValue // if paused
            }), in: 0...player.duration)
            Slider(value: Binding(get: {
                player.volume
            }, set: { newValue in
                player.volume = newValue
            }), in: 0...1)
            if let module = player.currentModule {
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
            Text("\(player.currentPattern)/\(player.currentRow)")
            if let pattern = player.currentModule?.patterns[Int(player.currentPattern)] {
                PatternViewer(pattern: pattern, highlightedRow: player.currentRow)
                    .environment(\.player, player)
            }
        }
        .padding()
    }
}
