//
//  Module.swift
//  BirdTracker
//
//  Created by Calvin Buckley on 2025-08-31.
//

import Foundation
import UniformTypeIdentifiers
import openmpt
import os

// #MARK: - Error/Logging

fileprivate let openmptLogger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "libopenmpt")

fileprivate func openmptLog(message: UnsafePointer<CChar>?, user: UnsafeMutableRawPointer?) {
    guard let message = message else {
        openmptLogger.debug("Null pointer from OpenMPT")
        return
    }
    // let this = Unmanaged<Module>.fromOpaque(user).takeUnretainedValue()
    let messageString = String(cString: message)
    openmptLogger.debug("\(messageString, privacy: .public)")
}

fileprivate func openmptError(class: Int32, user: UnsafeMutableRawPointer?) -> Int32 {
    // XXX: We should be storing and doing error handling in most cases
    return OPENMPT_ERROR_FUNC_RESULT_LOG | OPENMPT_ERROR_FUNC_RESULT_STORE
}

struct ModuleError: Error {
    let error: Int32
    let message: String
}

// #MARK: - Class

class Module {
    let underlying: OpaquePointer!
    
    let fileHandle: FileHandle!
    
    // #MARK: - File Types
    
    static func supportedExtensions() -> [String] {
        let extsCString = openmpt_get_supported_extensions()!
        let extsString = String(cString: extsCString)
        return extsString.split(separator: ";").map { String($0) }
    }
    
    static func supportedTypes() -> [UTType] {
        let exts = supportedExtensions()
        return exts.compactMap { ext in
            UTType(filenameExtension: ext)
        }
    }
    
    // #MARK: - Init
    
    var error: Int32
    var errorCString: UnsafePointer<CChar>?
    
    init(fileHandle: FileHandle) throws {
        self.fileHandle = fileHandle
        self.error = OPENMPT_ERROR_OK
        let fdCallbacks = openmpt_stream_get_fd_callbacks()
        let wrappedFd = UnsafeMutableRawPointer(bitPattern: UInt(self.fileHandle.fileDescriptor))
        underlying = openmpt_module_create2(fdCallbacks,
                                            wrappedFd,
                                            openmptLog,
                                            nil, // can't take self here
                                            openmptError,
                                            nil, // or here
                                            &error,
                                            &errorCString,
                                            nil)
        if underlying == nil {
            if let errorCString = self.errorCString {
                let errorString = String(cString: errorCString)
                openmpt_free_string(errorCString)
                throw ModuleError(error: error, message: errorString)
            } else {
                throw ModuleError(error: error, message: "(nil string)")
            }
        }
    }
    
    deinit {
        openmpt_module_destroy(underlying)
    }
    
    // #MARK: - Reading
    
    func readStereo(left: UnsafeMutablePointer<Float>, right: UnsafeMutablePointer<Float>, count: Int, sampleRate: Int32 = 48000) -> Int {
        return openmpt_module_read_float_stereo(underlying, sampleRate, count, left, right)
    }
    
    func readMono(buffer: UnsafeMutablePointer<Float>, count: Int, sampleRate: Int32 = 48000) -> Int {
        return openmpt_module_read_float_mono(underlying, sampleRate, count, buffer)
    }
    
    // #MARK: - Position/Status
    
    var position: TimeInterval {
        get {
            return openmpt_module_get_position_seconds(underlying)
        }
        set {
            openmpt_module_set_position_seconds(underlying, newValue)
        }
    }
    
    var duration: TimeInterval {
        return openmpt_module_get_duration_seconds(underlying)
    }
    
    var currentOrder: Int32 {
        return openmpt_module_get_current_order(underlying)
    }
    
    var currentPattern: Int32 {
        return openmpt_module_get_current_pattern(underlying)
    }
    
    var currentRow: Int32 {
        return openmpt_module_get_current_row(underlying)
    }
    
    func setPosition(order: Int32, row: Int32) {
        openmpt_module_set_position_order_row(underlying, order, row)
    }
    
    var currentPlayingChannels: Int32 {
        return openmpt_module_get_current_playing_channels(underlying)
    }
    
    var currentSpeed: Int32 {
        return openmpt_module_get_current_speed(underlying)
    }
    
    var currentEstimatedBPM: Double {
        return openmpt_module_get_current_estimated_bpm(underlying)
    }
    
    var currentTempo: Double {
        return openmpt_module_get_current_tempo2(underlying)
    }
    
    // XXX: enum of .forever/.once/.n(Int32)
    var repeatCount: Int32 {
        get {
            return openmpt_module_get_repeat_count(underlying)
        }
        set {
            openmpt_module_set_repeat_count(underlying, newValue)
        }
    }
    
    // #MARK: - Channels
    
    var channels: Int32 {
        return openmpt_module_get_num_channels(underlying)
    }
    
    var channelNames: [String] {
        var names: [String] = []
        for i in 0...channels {
            let cString = openmpt_module_get_channel_name(underlying, i)!
            names.append(String(cString: cString))
        }
        return names
    }
    
    // #MARK: Patterns
    
    struct Pattern {
        let module: Module
        
        let index: Int32
        let name: String
        
        let rows: Int32
        let rowsPerBeat: Int32
        let rowsPerMeasure: Int32
        
        let isSkip: Bool
        let isStop: Bool
        
        init(module: Module, index i: Int32) {
            self.module = module
            self.index = i
            self.name = String(cString: openmpt_module_get_pattern_name(module.underlying, i))
            self.rows = openmpt_module_get_pattern_num_rows(module.underlying, i)
            self.rowsPerBeat = openmpt_module_get_pattern_rows_per_beat(module.underlying, i)
            self.rowsPerMeasure = openmpt_module_get_pattern_rows_per_measure(module.underlying, i)
            self.isSkip = openmpt_module_is_pattern_skip_item(module.underlying, i) != 0
            self.isStop = openmpt_module_is_pattern_stop_item(module.underlying, i) != 0
        }
        
        func formatted(row: Int32, channel: Int32, width: Int = 0, pad: Bool = false) -> String {
            let cString = openmpt_module_format_pattern_row_channel(module.underlying, index, row, channel, width, pad ? 1 : 0)!
            return String(cString: cString)
        }
    }
    
    var patterns: [Pattern] {
        let count = openmpt_module_get_num_patterns(underlying)
        var patterns: [Pattern] = []
        for i in 0...count {
            patterns.append(Pattern(module: self, index: i))
        }
        return patterns
    }
}
