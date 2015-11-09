//
//  GreetingActor.swift
//  Actors
//
//  Created by Dario Lencina on 11/9/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import Theater

class Greeting : Actor.Message {}
class Angry : Actor.Message {}
class Happy : Actor.Message {}

class GreetingActor: Actor {
    
    override func receive(msg: Actor.Message) {
        return self.happy()(msg)
    }
    
    func happy() -> Receive { return {(msg : Message) in
            switch(msg) {
            case let g as Greeting:
                print("Hello \(g.sender)")
                
            case is Angry:
                self.become("angry", state: self.angry())
            
            default:
                super.receive(msg)
            }
        }
    }
    
    func angry()  -> Receive { return {(msg : Message) in
            switch(msg) {
            case let g as Greeting:
                print("Go away \(g.sender)")
                
            case is Happy:
                self.become("happy", state: self.happy())
                
            default:
                super.receive(msg)
            }
        }
    }

    
}