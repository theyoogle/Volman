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

    override var representedObject: Any? {
        didSet {
            
        }
    }
}

