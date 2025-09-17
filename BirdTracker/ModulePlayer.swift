//
//  ModulePlayer.swift
//  BirdTracker
//
//  Created by Calvin Buckley on 2025-08-31.
//

import Foundation
import AVFoundation
import AVFAudio
import MediaPlayer
import SwiftUI

@Observable class ModulePlayer {
    var currentModuleState: ModuleState? {
        didSet {
            updateNowPlaying()
        }
    }
    
    var currentModule: Module? {
        currentModuleState?.module
    }
    
    var playing = false {
        didSet {
            updateNowPlaying()
        }
    }
    
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
        // #MARK: AVFoundation setup
        #if !os(macOS)
        let avSession = AVAudioSession.sharedInstance()
        do {
            try avSession.setCategory(.playback)
        } catch {
            print("Ope, no AV category")
        }
        #endif
        
        self.sourceNode = AVAudioSourceNode(format: format!, renderBlock: { silence, timestamp, frameCount, buffers in
            guard let moduleState = self.currentModuleState,
                  let module = self.currentModule else {
                print("Ope, no module")
                self.stop()
                return noErr
            }
            
            let abl = UnsafeMutableAudioBufferListPointer(buffers)
            let left = abl[0].mData!.assumingMemoryBound(to: Float.self)
            let right = abl[1].mData!.assumingMemoryBound(to: Float.self)
            
            let count = module.readStereo(left: left, right: right, count: Int(frameCount), sampleRate: Int32(self.format!.sampleRate))
            if count == 0 {
                silence.pointee = true
            }
            
            // Avoid swamping SwiftUI with observability induced view updates.
            // A smarter thing would be only call update when the speed calls for it,
            // not every sample request from AVF
            let newRow = module.currentRow
            let newOrder = module.currentOrder
            if !(moduleState.currentRow == newRow && moduleState.currentOrder == newOrder) {
                DispatchQueue.main.async {
                    self.currentModuleState?.update()
                }
            }
            
            // TODO: Check if this is because of an error of end of module
            if count == 0 {
                DispatchQueue.main.async {
                    // We can't stop the audio thread from the audio thread,
                    // otherwise "ERROR, attempting to cleanup while rendering"
                    self.stop()
                    // Reset position (and then move onto next track)
                    moduleState.module.position = 0
                }
            }
            
            return noErr
        })
        
        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
        engine.prepare()
        
        // #MARK: MPRemoteCommandCenter setup
        let remoteCentre = MPRemoteCommandCenter.shared()
        // this is sent sometimes as a toggle, i.e. from keyboard
        remoteCentre.playCommand.isEnabled = true
        remoteCentre.playCommand.addTarget { event in
            if self.currentModuleState == nil {
                return .noActionableNowPlayingItem
            }
            if self.playing {
                self.pause()
            } else {
                self.play()
            }
            return .success
        }
        remoteCentre.pauseCommand.isEnabled = true
        remoteCentre.pauseCommand.addTarget { event in
            if self.currentModuleState == nil {
                return .noActionableNowPlayingItem
            }
            self.pause()
            return .success
        }
        remoteCentre.stopCommand.isEnabled = true
        remoteCentre.stopCommand.addTarget { event in
            if self.currentModuleState == nil {
                return .noActionableNowPlayingItem
            }
            self.currentModuleState = nil
            self.stop()
            return .success
        }
        remoteCentre.changePlaybackPositionCommand.isEnabled = true
        remoteCentre.changePlaybackPositionCommand.addTarget { event in
            let seekEvent = event as! MPChangePlaybackPositionCommandEvent
            if self.currentModuleState == nil {
                return .noActionableNowPlayingItem
            }
            self.seek(time: seekEvent.positionTime)
            return .success
        }
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
    
    // #MARK: - Playback controls
    
    func pause() {
        playing = false
        engine.stop()
    }
    
    func stop() {
        playing = false
        engine.stop()
    }
    
    func seek(time: TimeInterval) {
        if let currentModuleState {
            currentModuleState.seek(time: time)
            updateNowPlaying()
        }
    }
    
    // #MARK: - MPNowPlayingInfoCenter
    
    func updateNowPlaying() {
        let npic = MPNowPlayingInfoCenter.default()
        let centre = MPNowPlayingInfoCenter.default()
        var songInfo: [String: Any] = [:]
        
        if playing {
            centre.playbackState = .playing
        } else if currentModule != nil {
            centre.playbackState = .paused
        } else {
            centre.playbackState = .stopped
        }
        
        if let currentModule {
            songInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: currentModule.position)
            songInfo[MPMediaItemPropertyPlaybackDuration] = NSNumber(value: currentModule.duration)
            
            if let title = currentModule.metadata["title"] {
                songInfo[MPMediaItemPropertyTitle] = title
            }
            if let artist = currentModule.metadata["artist"] {
                songInfo[MPMediaItemPropertyArtist] = artist
            }
            if let savedDateISO8601 = currentModule.metadata["date"] {
                let dateParser = ISO8601DateFormatter()
                songInfo[MPMediaItemPropertyReleaseDate] = dateParser.date(from: savedDateISO8601)
            }
        }
        npic.nowPlayingInfo = songInfo
    }
}
