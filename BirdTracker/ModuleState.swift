//
//  ModuleState.swift
//  BirdTracker
//
//  Created by Calvin Buckley on 2025-09-07.
//

import SwiftUI
import UniformTypeIdentifiers

// The reason why this is a class is so we can just have the module file as the only visible state.
// The other variables are used for tracking the state in a way visible to SwiftUI observability,
// as the OpenMPT getters are not. We don't want them to influence the snapshot, so we avoid a struct.
@Observable class ModuleState: ReferenceFileDocument {
    func snapshot(contentType: UTType) throws -> Module {
        return module
    }
    
    typealias Snapshot = Module
    
    static var readableContentTypes: [UTType] {
        Module.supportedTypes()
    }
    
    required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.module = try Module(data: data)
        self.duration = self.module.duration
    }
    
    // XXX: SwiftUI doesn't let us have real viewers
    func fileWrapper(snapshot: Module, configuration: WriteConfiguration) throws -> FileWrapper {
        configuration.existingFile!
    }
    
    var module: Module!
    
    // Updated by the callback, as the callback is variable based on tempo
    var currentRow: Int32 = 0
    var currentOrder: Int32 = 0
    var currentPattern: Int32 = 0
    var position: Double = 0
    var duration: Double = 0
    
    var currentPlayingChannels: Int32 = 0
    var currentSpeed: Int32 = 0
    var currentTempo: Double = 0
    var currentEstimatedBPM: Double = 0
    
    func update() {
        self.currentRow = module.currentRow
        self.currentOrder = module.currentOrder
        self.currentPattern = module.currentPattern
        self.position = module.position
        
        // these adjust dynamically too
        self.currentPlayingChannels = module.currentPlayingChannels
        self.currentEstimatedBPM = module.currentEstimatedBPM
        self.currentTempo = module.currentTempo
        self.currentSpeed = module.currentSpeed
    }
    
    func seek(time: TimeInterval) {
        self.module.position = time
        // if paused
        self.update()
    }
    
    func seek(order: Int32, row: Int32) {
        self.module.setPosition(order: order, row: row)
        // if paused
        self.update()
    }
}
