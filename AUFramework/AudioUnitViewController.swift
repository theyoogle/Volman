//
//  AudioUnitViewController.swift
//  VPlug
//
//  Created by The YooGle on 14/08/22.
//

import CoreAudioKit

public class AudioUnitViewController: AUViewController, AUAudioUnitFactory {
    
    public var audioUnit: VPlugAudioUnit? {
        didSet {
            DispatchQueue.main.async {
                if self.isViewLoaded {
                    self.connectWithAU()
                }
            }
        }
    }
    
    private var volumeParam: AUParameter?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        if audioUnit == nil { return }
        
        connectWithAU()
    }
    
    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        audioUnit = try VPlugAudioUnit(componentDescription: componentDescription, options: [])
        return audioUnit!
    }
    
    func connectWithAU() {
        guard let paramTree = audioUnit?.parameterTree else {
            fatalError("paramTree nil!")
        }
        volumeParam = paramTree.value(forKey: "param1") as? AUParameter
    }
    
    @IBAction func volumeSlider(_ sender: NSSliderCell) {
        volumeParam?.value = AUValue(sender.doubleValue)
    }
}
