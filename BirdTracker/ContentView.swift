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
    
    struct MetadataView: View {
        let moduleState: ModuleState
        
        var module: Module {
            moduleState.module
        }
        
        @ViewBuilder func field(label: String, string: String) -> some View {
            LabeledContent {
                Text(string)
                    .textSelection(.enabled)
            } label: {
                Text(label)
            }
        }
        
        @ViewBuilder func field(label: String, number: Int32) -> some View {
            LabeledContent {
                Text(String(number))
                    .textSelection(.enabled)
            } label: {
                Text(label)
            }
        }
        
        @ViewBuilder func field(label: String, number: Double) -> some View {
            LabeledContent {
                Text(String(number))
                    .textSelection(.enabled)
            } label: {
                Text(label)
            }
        }
        
        var body: some View {
            VStack(alignment: .leading) {
                Form {
                    if let title = module.metadata["title"] {
                        field(label: "Title", string: title)
                    }
                    if let artist = module.metadata["artist"] {
                        field(label: "Artist", string: artist)
                    }
                    if let tracker = module.metadata["tracker"] {
                        field(label: "Tracker", string: tracker)
                    }
                    if let trackerType = module.metadata["type_long"] {
                        field(label: "Format", string: trackerType)
                    }
                    if let trackerType = module.metadata["originaltype_long"] {
                        field(label: "Original Format", string: trackerType)
                    }
                    if let container = module.metadata["container_long"] {
                        field(label: "Container", string: container)
                    }
                    if let savedDateISO8601 = module.metadata["date"] {
                        field(label: "Date", string: savedDateISO8601)
                    }
                    Divider()
                    field(label: "Active Channels", number: moduleState.currentPlayingChannels)
                    field(label: "Est. BPM", number: moduleState.currentEstimatedBPM)
                    field(label: "Speed", number: moduleState.currentSpeed)
                    field(label: "Tempo", number: moduleState.currentTempo)
                }
                .formStyle(.columns)
                if let message = module.metadata["message_raw"] {
                    // TODO: Alignment of this is weird.
                    ScrollView([.horizontal, .vertical]) {
                        VStack(alignment: .leading) {
                            Text(message)
                                .textSelection(.enabled)
                                .monospaced()
                                .frame(maxHeight: .infinity, alignment: .topLeading)
                        }
                    }
                    .scrollIndicators(.visible)
                }
            }
            .padding()
        }
    }
    
    struct PatternsView: View {
        let moduleState: ModuleState
        
        var body: some View {
            Table(moduleState.module.patterns) {
                TableColumn("ID") {
                    Text(String($0.id))
                }
                TableColumn("Name", value: \.name)
            }
        }
    }
    
    struct SamplesView: View {
        let moduleState: ModuleState
        
        var body: some View {
            List(moduleState.module.samples) {
                Text($0.name)
                    .textSelection(.enabled)
                    .listRowSeparator(.hidden)
            }
            .scrollContentBackground(.hidden)
            .monospaced()
        }
    }
    
    struct InstrumentsView: View {
        let moduleState: ModuleState
        
        var body: some View {
            List(moduleState.module.instruments) {
                Text($0.name)
                    .textSelection(.enabled)
                    .listRowSeparator(.hidden)
            }
            .scrollContentBackground(.hidden)
            .monospaced()
        }
    }
    
    struct OrdersView: View {
        @Environment(\.player) private var player
        
        let moduleState: ModuleState
        
        @State var selectedOrders: Module.Order.ID?
        
        // weird but works out for us
        func seekToOrder(items: Set<Module.Order.ID>) {
            guard let orderID = items.first else {
                return
            }
            moduleState.seek(order: orderID, row: 0)
            if moduleState.module == player.currentModule {
                player.updateNowPlaying()
            }
        }
        
        var body: some View {
            Table(moduleState.module.orders, selection: $selectedOrders) {
                TableColumn("ID") {
                    Text(String($0.id))
                }
                TableColumn("Pattern") {
                    Text(String($0.pattern))
                }
                TableColumn("Name", value: \.name)
            }
            .contextMenu(forSelectionType: Module.Order.ID.self) { items in
                Button("Seek to Order") {
                    seekToOrder(items: items)
                }
            } primaryAction: { items in
                seekToOrder(items: items)
            }
        }
    }
    
    enum InspectorMode {
        case none
        case orders
        case patterns
        case samples
        case instruments
        case metadata
    }
    
    @State var inspectorMode: InspectorMode = .none
    // On iOS, default to a denser zoom level
    #if os(macOS)
    @State var patternCellZoom: PatternViewer.PatternCellZoom = .full
    #else
    @State var patternCellZoom: PatternViewer.PatternCellZoom = .note
    #endif
    
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
                .inspector(isPresented: Binding(get: { self.inspectorMode != .none },
                                                set: { newValue in if !newValue { self.inspectorMode = .none } })) {
                    if inspectorMode == .orders {
                        OrdersView(moduleState: moduleState)
                            .environment(\.player, player)
                    } else if inspectorMode == .patterns {
                        PatternsView(moduleState: moduleState)
                    } else if inspectorMode == .samples {
                        SamplesView(moduleState: moduleState)
                    } else if inspectorMode == .instruments {
                        InstrumentsView(moduleState: moduleState)
                    } else if inspectorMode == .metadata {
                        MetadataView(moduleState: moduleState)
                    }
                }
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
                Menu {
                    Picker(selection: $inspectorMode) {
                        Text("None").tag(InspectorMode.none)
                        Text("Sequences").tag(InspectorMode.orders)
                        Text("Patterns").tag(InspectorMode.patterns)
                        Text("Samples").tag(InspectorMode.samples)
                        if module.instrumentCount > 0 {
                            Text("Instruments").tag(InspectorMode.instruments)
                        }
                        Text("Metadata").tag(InspectorMode.metadata)
                    } label: {
                    }
                    .pickerStyle(.inline)
                } label: {
                    Label("Inspector", systemImage: "info.circle")
                }
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
