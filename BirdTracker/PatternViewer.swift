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
    
    enum PatternCellZoom: Double {
        case full = 1
        case noteVolume = 0.50
        case note = 0
        
        func displacement(value: Double) -> PatternCellZoom {
            print(value)
            
            if value > 1.25 {
                return .full
            } else if value < 0.75 {
                return .note
            } else {
                return .noteVolume
            }
        }
        
        var width: CGFloat {
            switch self {
            case .noteVolume:
                90
            case .note:
                30
            default:
                120
            }
        }
    }
    
    let zoom: PatternCellZoom

    // On iPhone at least, we can only display a single column from a table
#if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isCompact: Bool { horizontalSizeClass == .compact }
#else
    private let isCompact = false
#endif
    
    var body: some View {
        ScrollViewReader { proxy in
            Table(of: Module.PatternRow.self, selection: Binding(get: { return highlightedRow },
                                                                 set: { newValue in updatePosition(row: newValue) })) {
                if isCompact {
                    // This is a single column for all channels, like a lot of early GUI tracker players did.
                    // This has a lot of limitations, but the performance is much better for huge patterns
                    // (i.e. 64 channels * 256 rows)
                    TableColumn("Channels") { (row: Module.PatternRow) in
                        let channelCells = row.cells.map { $0.note }.joined(separator: " ")
                        Text(channelCells)
                            .lineLimit(1)
                    }
                } else {
                    TableColumn("Row") { (row: Module.PatternRow) in
                        Text(String(row.id, radix: 16, uppercase: true))
                            .frame(width: 30, height: 16, alignment: .trailing)
                            .fixedSize()
                    }
                    .width(30)
                    TableColumnForEach(pattern.module.channels) { channel in
                        let width: CGFloat = zoom.width
                        TableColumn(channel.name) { (row: Module.PatternRow) in
                            let cell: Module.PatternCell = row.cells[Int(channel.id)]
                            let text: String = switch zoom {
                            case .noteVolume:
                                "\(cell.note) \(cell.instrument)\(cell.volumeEffect)\(cell.volume)"
                            case .note:
                                cell.note
                            default:
                                cell.formatted
                            }
                            Text(text)
                                .fixedSize()
                        }
                        .width(width)
                    }
                }
            } rows: {
                ForEach(pattern.rows) { (row: Module.PatternRow) in
                    TableRow(row)
                }
            }
            .id(pattern.id) // or it won't update the rows on pattern change
            .monospaced()
            .onChange(of: highlightedRow) { _, newValue in
                proxy.scrollTo(highlightedRow, anchor: .center)
            }
        }
    }
}
