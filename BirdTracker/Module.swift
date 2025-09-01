//
//  Module.swift
//  BirdTracker
//
//  Created by Calvin Buckley on 2025-08-31.
//

import Foundation
import openmpt

class Module {
    let underlying: OpaquePointer!
    
    let fileHandle: FileHandle!
    
    init(fileHandle: FileHandle) {
        self.fileHandle = fileHandle
        let fdCallbacks = openmpt_stream_get_fd_callbacks()
        let wrappedFd = UnsafeMutableRawPointer(bitPattern: UInt(self.fileHandle.fileDescriptor))
        underlying = openmpt_module_create2(fdCallbacks, wrappedFd, nil, nil, nil, nil, nil, nil, nil)
    }
    
    func readStereo(left: UnsafeMutablePointer<Float>, right: UnsafeMutablePointer<Float>, count: Int, sampleRate: Int32 = 48000) -> Int {
        return openmpt_module_read_float_stereo(underlying, sampleRate, count, left, right)
    }
    
    func readMono(buffer: UnsafeMutablePointer<Float>, count: Int, sampleRate: Int32 = 48000) -> Int {
        return openmpt_module_read_float_mono(underlying, sampleRate, count, buffer)
    }
    
    deinit {
        openmpt_module_destroy(underlying)
    }
}
