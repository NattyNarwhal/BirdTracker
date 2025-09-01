//
//  ModulePlayer.swift
//  BirdTracker
//
//  Created by Calvin Buckley on 2025-08-31.
//

import Foundation
import AVFAudio

class ModulePlayer: ObservableObject {
    var currentModule: Module?
    
    var playing = false
    
    var engine = AVAudioEngine()
    var playerNode = AVAudioPlayerNode()
    let format = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 2)
    
    init() {
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        engine.prepare()
    }
    
    func play() {
        guard let module = self.currentModule else {
            print("Ope, no module")
            return
        }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: 480) else {
            print("Ope, no buffer")
            return
        }
        do {
            try engine.start()
        } catch {
            print("Ope, can't start audio?")
        }
        let interval = 1 / (format!.sampleRate / Double(buffer.frameCapacity))
        let timer = Timer(timeInterval: interval / 2, repeats: true) {
            [weak self] _ in
            guard self?.playing  == true else {
                return
            }
        
            guard let floatChannelData = buffer.floatChannelData else {
                return
            }
            let count = module.readStereo(left: floatChannelData[0], right: floatChannelData[1], count: Int(buffer.frameCapacity))
            if count == 0 {
                return
            }
            buffer.frameLength = AVAudioFrameCount(count)
            self?.playerNode.scheduleBuffer(buffer, at: nil, options: [.interrupts])
        }
        RunLoop.current.add(timer, forMode: .common)
        
        playerNode.play()
        playing = true
    }
    
    func stop() {
        playing = false
        playerNode.stop()
        engine.stop()
    }
}
