//
//  Inspector.swift
//  BirdTracker
//
//  Created by Calvin Buckley on 2025-09-12.
//

import SwiftUI

enum InspectorMode {
    case none
    case orders
    case patterns
    case samples
    case instruments
    case metadata
}

struct Inspector: View {
    @Environment(\.player) private var player
    
    let inspectorMode: InspectorMode
    let moduleState: ModuleState
    
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
    
    var body: some View {
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

#if os(visionOS)
struct InspectorWindow: View {
    @Environment(\.player) private var player
    
    let moduleState: ModuleState
    @State var inspectorMode: InspectorMode = .instruments
    
    var body: some View {
        NavigationStack {
            Inspector(inspectorMode: inspectorMode, moduleState: moduleState)
        }
        .modify {
            // cap the width for anything other than metadata
            if inspectorMode != .metadata {
                $0.frame(width: 400)
            } else {
                $0
            }
        }
        .glassBackgroundEffect()
        .ornament(attachmentAnchor: .scene(.bottom)) {
            Picker(selection: $inspectorMode) {
                // this doesn't support badges in this context
                Text("Sequences \(Int(moduleState.module.orderCount))").tag(InspectorMode.orders)
                Text("Patterns \(Int(moduleState.module.patternCount))").tag(InspectorMode.patterns)
                Text("Samples \(Int(moduleState.module.sampleCount))").tag(InspectorMode.samples)
                if moduleState.module.instrumentCount > 0 {
                    Text("Instruments \(Int(moduleState.module.instrumentCount))").tag(InspectorMode.instruments)
                }
                Text("Metadata").tag(InspectorMode.metadata)
            } label: {
            }
        }
    }
}
#endif
