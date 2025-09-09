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
    
    func updatePosition(row: Int32?) {
        if let row {
            moduleState.seek(order: pattern.module.currentOrder, row: row)
            if pattern.module == player.currentModule {
                player.updateNowPlaying()
            }
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            Table(of: Module.PatternRow.self, selection: Binding(get: { return highlightedRow }, set: { newValue in updatePosition(row: newValue) })) {
                TableColumn("Row") { (row: Module.PatternRow) in
                    Text(String(row.id, radix: 16, uppercase: true))
                }
                .width(30)
                TableColumnForEach(pattern.module.channels) { channel in
                    TableColumn(channel.name) { (row: Module.PatternRow) in
                        // For now, this just uses the OpenMPT formatted text, but we could provide a richer thing here
                        Text(row.cells[Int(channel.id)].formatted)
                    }
                }
            } rows: {
                ForEach(pattern.rows) { (row: Module.PatternRow) in
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
