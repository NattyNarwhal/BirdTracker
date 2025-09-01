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
    
    func readStereo() -> ([Float32], [Float32])? {
        var left = Array<Float32>(repeating: 0, count: 480)
        var right = Array<Float32>(repeating: 0, count: 480)
        
        let count = openmpt_module_read_float_stereo(underlying, 48000, 480, &left, &right)
        if count == 0 {
            return nil
        }
        return (left, right)
    }
    
    func readStereo(left: UnsafeMutablePointer<Float>, right: UnsafeMutablePointer<Float>, count: Int = 480) -> Int {
        return openmpt_module_read_float_stereo(underlying, 48000, count, left, right)
    }
    
    deinit {
        openmpt_module_destroy(underlying)
    }
}
