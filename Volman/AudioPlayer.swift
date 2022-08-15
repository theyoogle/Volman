//
//  AudioPlayer.swift
//  Volman
//
//  Created by The YooGle on 14/08/22.
//

import AVFoundation

class AudioPlayer: NSObject {
    
    private let file: AVAudioFile!
    
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var isPlaying = false
    private let audioPlayerQueue = DispatchQueue(label: "AudioPlayerQueue")
    
    public var audioUnit: AUAudioUnit?
    private var audioUnitNode: AVAudioUnit?
    
    init(_ url: URL) {
        guard let file = try? AVAudioFile(forReading: url) else {
            fatalError("Can't load file")
        }
        
        self.file = file
        super.init()
        engine.attach(playerNode)
    }
    
    private func scheduleLoop(_ file: AVAudioFile) {
        playerNode.scheduleFile(file, at: nil) {
            self.audioPlayerQueue.async {
                if self.isPlaying {
                    self.scheduleLoop(file)
                }
            }
        }
    }
    
    private func startPlaying() {
        scheduleLoop(file)
        
        let hardwareFormat = engine.outputNode.outputFormat(forBus: 0)
        engine.connect(engine.mainMixerNode, to: engine.outputNode, format: hardwareFormat)
        
        do {
            try engine.start()
        } catch {
            fatalError("Can't start engine \(error)")
        }
        
        playerNode.play()
        isPlaying = true
    }
    
    func play() {
        audioPlayerQueue.sync {
            if !isPlaying {
                startPlaying()
            }
        }
    }
    
    public func selectAudioUnitWithComponentDescription(_ componentDescription: AudioComponentDescription?, completionHandler: @escaping (() -> Void)) {
        
        func done() {
            if isPlaying {
                playerNode.play()
            }
            completionHandler()
        }
        
        let hardwareFormat = self.engine.outputNode.outputFormat(forBus: 0)
        engine.connect(engine.mainMixerNode, to: engine.outputNode, format: hardwareFormat)
        
        /*
         Pause the player before re-wiring it. (It is not simple to keep it
         playing across an insertion or deletion.)
         */
        if isPlaying {
            playerNode.pause()
        }
        
        // Destroy any pre-existing unit.
        if audioUnitNode != nil {
            // Break player -> effect connection.
            engine.disconnectNodeInput(audioUnitNode!)
            // Break audioUnitNode -> mixer connection
            engine.disconnectNodeInput(engine.mainMixerNode)
            // Connect player -> mixer.
            engine.connect(playerNode, to: engine.mainMixerNode, format: file!.processingFormat)
            // We're done with the unit; release all references.
            engine.detach(audioUnitNode!)
            
            audioUnitNode = nil
            audioUnit = nil
        }
        
        // Insert the audio unit, if any.
        if let componentDescription = componentDescription {
            AVAudioUnit.instantiate(with: componentDescription, options: []) { avAudioUnit, error in
                guard let avAudioUnit = avAudioUnit else {
                    fatalError("avAudioUnit nil \(String(describing: error))")
                }
                
                self.audioUnitNode = avAudioUnit
                self.engine.attach(avAudioUnit)
                // Disconnect player -> mixer.
                self.engine.disconnectNodeInput(self.engine.mainMixerNode)
                // Connect player -> effect -> mixer.
                self.engine.connect(self.playerNode, to: avAudioUnit, format: self.file!.processingFormat)
                self.engine.connect(avAudioUnit, to: self.engine.mainMixerNode, format: self.file!.processingFormat)
                
                self.audioUnit = avAudioUnit.auAudioUnit
                avAudioUnit.auAudioUnit.contextName = "running in AUv3Host"
                
                done()
            }
        } else {
            done()
        }
        
    }
}
