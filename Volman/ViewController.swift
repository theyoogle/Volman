//
//  ViewController.swift
//  Volman
//
//  Created by The YooGle on 14/08/22.
//

import Cocoa
import AUFramework

class ViewController: NSViewController {
    
    private var audioPlayer: AudioPlayer!
    private var pluginVC: AudioUnitViewController!

    @IBOutlet weak var auContainer: NSView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let url = Bundle.main.url(forResource: "nokia", withExtension: "wav") else {
            fatalError("Can't create url from resource")
        }
        
        addPluginView()
        
        audioPlayer = AudioPlayer(url)
        connectAudioUnitWithPlayer()
        audioPlayer.play()
    }
    
    private func addPluginView() {
        let builtInPluginsURL = Bundle.main.builtInPlugInsURL
        guard let pluginURL = builtInPluginsURL?.appendingPathComponent("VPlug.appex") else {
            fatalError("Can't get plugin URL")
        }
        
        let appExtensionBundle = Bundle(url: pluginURL)
        pluginVC = AudioUnitViewController(nibName: "AudioUnitViewController", bundle: appExtensionBundle)
        
        let auView = pluginVC.view
        auView.frame = auContainer.bounds
        auContainer.addSubview(auView)
    }
    
    private func connectAudioUnitWithPlayer() {
        var componentDescription = AudioComponentDescription()
        componentDescription.componentType = kAudioUnitType_Effect
        componentDescription.componentSubType = 0x56506c75 // "Vplu"   https://codebeautify.org/string-hex-converter
        componentDescription.componentManufacturer = 0x596f6f47 // "YooG"
        componentDescription.componentFlags = 0
        componentDescription.componentFlagsMask = 0
        
        AUAudioUnit.registerSubclass(VPlugAudioUnit.self, as: componentDescription, name: "YooG: VPlug", version: UInt32.max)
        audioPlayer.selectAudioUnitWithComponentDescription(componentDescription) {
            guard let audioUnit = self.audioPlayer.audioUnit as? VPlugAudioUnit else {
                fatalError("playEngine.testAudioUnit nil or cast failed")
            }
            self.pluginVC.audioUnit = audioUnit
        }
    }

    override var representedObject: Any? {
        didSet {
            
        }
    }
}

