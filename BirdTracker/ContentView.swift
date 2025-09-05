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
                player.stop()
            } label: {
                Text("Stop")
            }
            Text("\(player.currentPattern)/\(player.currentRow)")
            // as we can't bind directly to player
            Slider(value: Binding(get: {
                player.position
            }, set: { newValue in
                player.currentModule?.position = newValue
            }), in: 0...player.duration)
            Slider(value: Binding(get: {
                player.volume
            }, set: { newValue in
                player.volume = newValue
            }), in: 0...1)
            Text("Pattern:")
            if let pattern = player.currentModule?.patterns[Int(player.currentPattern)] {
                PatternViewer(pattern: pattern, highlightedRow: player.currentRow)
            }
        }
        .padding()
    }
}
