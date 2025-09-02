//
//  ModulePlayer.swift
//  BirdTracker
//
//  Created by Calvin Buckley on 2025-08-31.
//

import Foundation
import AVFAudio
import AudioToolbox

class ModulePlayer: ObservableObject {
    var currentModule: Module?
    
    var playing = false
    var timer: Timer?
    
    var engine = AVAudioEngine()
    var sourceNode: AVAudioSourceNode!
    let format = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 2)
    
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
            return noErr
        })
        
        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
        engine.prepare()
    }
    
    func play() {
        do {
            try engine.start()
        } catch {
            print("Ope, can't start audio?")
        }
        playing = true
    }
    
    func stop() {
        self.timer?.invalidate()
        playing = false
        engine.stop()
    }
}
