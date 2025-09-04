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
        }
        .padding()
    }
}
