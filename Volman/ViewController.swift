//
//  ViewController.swift
//  Volman
//
//  Created by The YooGle on 14/08/22.
//

import Cocoa

class ViewController: NSViewController {
    
    private var audioPlayer: AudioPlayer!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let url = Bundle.main.url(forResource: "nokia", withExtension: "wav") else {
            fatalError("Can't create url from resource")
        }
        audioPlayer = AudioPlayer(url)
        audioPlayer.play()
    }

    override var representedObject: Any? {
        didSet {
            
        }
    }
}

