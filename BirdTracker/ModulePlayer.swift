//
//  ModulePlayer.swift
//  BirdTracker
//
//  Created by Calvin Buckley on 2025-08-31.
//

import Foundation
import AVFAudio
import SwiftUI

@Observable class ModulePlayer {
    var currentModule: Module? {
        didSet {
            self.currentRow = 0
            self.currentPattern = 0
        }
    }
    
    var playing = false
    
    // Updated by the callback, as the callback is variable based on tempo
    var currentRow: Int32 = 0
    var currentPattern: Int32 = 0
    
    private var engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode!
    private let format = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 2)
    
    init() {
        self.sourceNode = AVAudioSourceNode(format: format!, renderBlock: { silence, timestamp, frameCount, buffers in
            guard let module = self.currentModule else {
                print("Ope, no module")
                return noErr
            }
            
            let abl = UnsafeMutableAudioBufferListPointer(buffers)
            let left = abl[0].mData!.assumingMemoryBound(to: Float.self)
            let right = abl[1].mData!.assumingMemoryBound(to: Float.self)
            
            let count = module.readStereo(left: left, right: right, count: Int(frameCount))
            if count == 0 {
                silence.pointee = true
            }
            
            self.currentRow = module.currentRow
            self.currentPattern = module.currentPattern
            
            return noErr
        })
        
        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
        engine.prepare()
    }
    
    func play() {
        guard self.currentModule != nil else {
            print("Ope, no module")
            return
        }
        do {
            try engine.start()
        } catch {
            print("Ope, can't start audio?")
        }
        playing = true
    }
    
    func stop() {
        self.currentRow = 0
        self.currentPattern = 0
        playing = false
        engine.stop()
    }
}
