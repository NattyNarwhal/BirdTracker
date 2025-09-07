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
    var currentModuleState: ModuleState? {
        willSet {
            self.stop()
        }
    }
    
    var currentModule: Module? {
        currentModuleState?.module
    }
    
    var playing = false
    
    var volume: Float {
        get {
            return sourceNode.volume
        }
        set {
            sourceNode.volume = newValue
        }
    }
    
    private var engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode!
    // XXX: Handle this dynamically changing based on output device?
    private let format = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 2)
    
    init() {
        self.sourceNode = AVAudioSourceNode(format: format!, renderBlock: { silence, timestamp, frameCount, buffers in
            guard let module = self.currentModule else {
                print("Ope, no module")
                self.stop()
                return noErr
            }
            
            let abl = UnsafeMutableAudioBufferListPointer(buffers)
            let left = abl[0].mData!.assumingMemoryBound(to: Float.self)
            let right = abl[1].mData!.assumingMemoryBound(to: Float.self)
            
            let count = module.readStereo(left: left, right: right, count: Int(frameCount))
            if count == 0 {
                silence.pointee = true
            }
            
            // Or we gunk up the audio thread
            DispatchQueue.main.async {
                if let moduleState = self.currentModuleState {
                    // TODO: Check if this is because of an error of end of module
                    if count == 0 {
                        // We can't stop the audio thread from the audio thread,
                        // otherwise "ERROR, attempting to cleanup while rendering"
                        self.stop()
                        // Reset position (and then move onto next track)
                        moduleState.module.position = 0
                        moduleState.position = 0
                        moduleState.currentRow = module.currentRow
                        moduleState.currentOrder = module.currentOrder
                        moduleState.currentPattern = module.currentPattern
                    } else {
                        moduleState.currentRow = module.currentRow
                        moduleState.currentOrder = module.currentOrder
                        moduleState.currentPattern = module.currentPattern
                        moduleState.position = module.position
                    }
                }
            }
            
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
    
    func pause() {
        playing = false
        engine.stop()
    }
    
    func stop() {
        playing = false
        engine.stop()
    }
}
