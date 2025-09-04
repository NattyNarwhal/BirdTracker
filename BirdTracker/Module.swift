//
//  Module.swift
//  BirdTracker
//
//  Created by Calvin Buckley on 2025-08-31.
//

import Foundation
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
}
