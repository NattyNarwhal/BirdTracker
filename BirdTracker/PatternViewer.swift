//
//  PatternViewer.swift
//  BirdTracker
//
//  Created by Calvin Buckley on 2025-09-04.
//

import SwiftUI

struct PatternViewer: View {
    @Environment(\.player) private var player
    
    let moduleState: ModuleState
    let pattern: Module.Pattern
    
    let highlightedRow: Int32
    
    struct Row: Identifiable {
        let id: Int32
    }
    
    func updatePosition(row: Int32?) {
        if let row {
            moduleState.seek(order: pattern.module.currentOrder, row: row)
            if pattern.module == player.currentModule {
                player.updateNowPlaying()
            }
        }
    }
    
    var body: some View {
        let channels = pattern.module.channels
        let rows = (0...pattern.rows).map { Row(id: $0) }
        // This feels really awkward
        ScrollViewReader { proxy in
            Table(of: Row.self, selection: Binding(get: { return highlightedRow }, set: { newValue in updatePosition(row: newValue) })) {
                TableColumnForEach(channels) { channel in
                    TableColumn(channel.name) { (row: Row) in
                        let formatted = pattern.formatted(row: row.id, channel: channel.id)
                        // For now, this just uses the OpenMPT formatted text, but we could provide a richer thing here
                        Text(formatted)
                    }
                }
            } rows: {
                ForEach(rows) { row in
                    TableRow(row)
                }
            }
            .monospaced()
            .onChange(of: highlightedRow) { _, newValue in
                proxy.scrollTo(highlightedRow, anchor: .center)
            }
        }
    }
}
