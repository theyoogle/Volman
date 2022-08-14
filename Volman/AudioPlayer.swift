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
        engine.connect(playerNode, to: engine.mainMixerNode, format: file.processingFormat)
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
}
