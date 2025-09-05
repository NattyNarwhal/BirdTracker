//
//  PatternViewer.swift
//  BirdTracker
//
//  Created by Calvin Buckley on 2025-09-04.
//

import SwiftUI

struct PatternViewer: View {
    let pattern: Module.Pattern
    
    let highlightedRow: Int32
    
    struct Cell: Identifiable {
        let id: Int32
    }
    
    struct Channel: Identifiable {
        let id: Int32
        let name: String
    }
    
    struct Row: Identifiable {
        let id: Int32
        let channels: [Cell]
    }
    
    var body: some View {
        let channelNames = pattern.module.channelNames
        let channels = (0...pattern.module.channels).map { channel in
            return Channel(id: channel, name: channelNames[Int(channel)])
        }
        let rows = (0...pattern.rows).map { row in
            return Row(id: row, channels: (0...pattern.module.channels).map { channel in
                Cell(id: row)
            })
        }
        // This feels really awkward
        ScrollViewReader { proxy in
            Table(of: Row.self, selection: Binding(get: { return highlightedRow }, set: { _ in })) {
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
