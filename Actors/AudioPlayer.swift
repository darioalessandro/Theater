//
//  AudioPlayer.swift
//  Actors
//
//  Created by Dario Lencina on 11/19/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import Theater
import AudioToolbox

class AudioPlayer : Actor {
    class PlaySound : Message {
        let name : String
        let ext : String
        
        init(sender: Optional<ActorRef>, name : String, ext : String) {
            self.name = name
            self.ext = ext
            super.init(sender: sender)
        }
    }
    
    override func receive(msg: Actor.Message) {
        switch(msg) {
        case let sound as PlaySound:
            if let soundURL = NSBundle.mainBundle().URLForResource(sound.name, withExtension: sound.ext) {
                var mySound: SystemSoundID = 0
                AudioServicesCreateSystemSoundID(soundURL, &mySound)
                AudioServicesPlaySystemSound(mySound);
            }
        default:
            super.receive(msg)
        }
    }
    
}