//
//  ContentView.swift
//  BirdTracker
//
//  Created by Calvin Buckley on 2025-08-22.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.player) private var player
    
    var moduleState: ModuleState
    
    var module: Module {
        moduleState.module
    }
    
    @State var inspectorMode: InspectorMode = .none
    // On iOS, default to a denser zoom level
    #if os(macOS)
    @State var patternCellZoom: PatternViewer.PatternCellZoom = .full
    #else
    @State var patternCellZoom: PatternViewer.PatternCellZoom = .note
    #endif
    
    @Environment(\.openWindow) private var openWindow

    @State private var showVolumePopover = false
    
    struct PlayerVolumeSlider: View {
        @Environment(\.player) private var player
        
        var body: some View {
            Slider(value: Binding(get: {
                player.volume
            }, set: { newValue in
                player.volume = newValue
            }), in: 0...1) {
                Text("Volume")
            }
            .frame(minWidth: 200)
        }
    }
    
    var body: some View {
        // subtitle used for displaying time, order, and pattern
        let subtitle = "\(String(timeInterval: moduleState.position))/\(String(timeInterval: moduleState.duration)) \(moduleState.currentOrder)/\(module.orderCount) \(moduleState.currentPattern)/\(moduleState.currentRow)"
        
        VStack {
            let pattern = module.patterns[Int(moduleState.currentPattern)]
            PatternViewer(moduleState: moduleState, pattern: pattern, highlightedRow: moduleState.currentRow, zoom: patternCellZoom)
                .gesture(
                    MagnifyGesture(minimumScaleDelta: 0.25)
                        .onChanged { newValue in
                            self.patternCellZoom = self.patternCellZoom.displacement(value: newValue.magnification)
                        }
                )
                .environment(\.player, player)
            #if !os(visionOS)
                .inspector(isPresented: Binding(get: { self.inspectorMode != .none },
                                                set: { newValue in if !newValue { self.inspectorMode = .none } })) {
                    Inspector(inspectorMode: inspectorMode, moduleState: moduleState)
                        .environment(\.player, player)
                }
            #endif
        }
        .toolbar {
            #if !os(macOS)
            ToolbarItem(id: "positionText") {
                Text(subtitle)
                    .monospacedDigit()
            }
            #endif
            ToolbarItemGroup {
                if player.playing && player.currentModule == moduleState.module {
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
                    moduleState.seek(time: newValue)
                    if self.module == player.currentModule {
                        player.updateNowPlaying()
                    }
                }), in: 0...moduleState.duration) {
                    Text("Position")
                }
                .frame(minWidth: 200)
            }
            ToolbarItem(id: "volumeSlider") {
                // XXX: Dynamically adjust based on how volume is set
                Button("Volume", systemImage: "speaker") {
                    showVolumePopover.toggle()
                }
                .popover(isPresented: $showVolumePopover, arrowEdge: .bottom) {
                    VStack {
                        PlayerVolumeSlider()
                            .environment(\.player, player)
                    }
                    .padding()
                }
            }
            #if os(iOS)
            ToolbarItem(id: "routePicker") {
                // on macOS, this requires picking an AVPlayer
                RoutePicker()
            }
            #endif
            #if os(macOS)
            // Only show on macOS because fully zooming in on iPad at least kind of sucks
            ToolbarItem(id: "zoom") {
                Menu {
                    Picker(selection: $patternCellZoom) {
                        Text("Notes Only").tag(PatternViewer.PatternCellZoom.note)
                        Text("Notes and Volume").tag(PatternViewer.PatternCellZoom.noteVolume)
                        Text("Notes, Volume, and Effects").tag(PatternViewer.PatternCellZoom.full)
                    } label: {
                    }
                    .pickerStyle(.inline)
                } label: {
                    Label("Zoom Level", systemImage: "plus.magnifyingglass")
                }
            }
            #endif
            ToolbarItem(id: "inspector") {
                #if os(visionOS)
                Button("Inspector", systemImage: "info.circle") {
                    // I don't want to figure out how to make ModuleState codable
                    // (since we need the module, not just a snapshot of some properties)
                    openWindow(value: ModuleStateRef(moduleState: moduleState))
                }
                #else
                Menu {
                    Picker(selection: $inspectorMode) {
                        Text("None").tag(InspectorMode.none)
                        Text("Sequences").tag(InspectorMode.orders)
                            .badge(Int(moduleState.module.orderCount))
                        Text("Patterns").tag(InspectorMode.patterns)
                            .badge(Int(moduleState.module.patternCount))
                        Text("Samples").tag(InspectorMode.samples)
                            .badge(Int(moduleState.module.sampleCount))
                        if moduleState.module.instrumentCount > 0 {
                            Text("Instruments").tag(InspectorMode.instruments)
                                .badge(Int(moduleState.module.instrumentCount))
                        }
                        Text("Metadata").tag(InspectorMode.metadata)
                    } label: {
                    }
                    .pickerStyle(.inline)
                } label: {
                    Label("Inspector", systemImage: "info.circle")
                }
                #endif
            }
        }
        .modify {
            if let title = module.metadata["title"] {
                $0.navigationTitle(title)
            } else {
                $0
            }
        }
        #if os(macOS)
        .navigationSubtitle(subtitle)
        #endif
        .focusedSceneValue(\.focusedModule, moduleState)
        .focusedSceneValue(\.focusedInspectorMode, $inspectorMode)
    }
}
