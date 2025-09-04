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
    
    var body: some View {
        VStack {
            Button {
                if let handle = FileHandle(forReadingAtPath: "/Users/calvin/Downloads/truefaith.xm"),
                   let module = try? Module(fileHandle: handle) {
                    player.currentModule = module
                    
                }
            } label: {
                Text("Load")
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
        }
        .padding()
    }
}
