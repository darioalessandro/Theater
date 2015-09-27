//
//  ActorsDemo.swift
//  Actors
//
//  Created by Dario Lencina on 9/26/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import Theater

class SayHi : Message {
    private var count : NSInteger = 0
    
    convenience init(sender : ActorRef, count : NSInteger) {
        self.init(sender : sender)
        self.count = count
    }
}

class Ping: Actor {
    override func receive(msg : Message) -> Void {
        switch msg {
        case let n where n is SayHi:
                let hi = msg as! SayHi
                print("got message in Ping")
                if hi.count > 10 {
                    print("The end")
                } else {
                    self.sender!.tell(SayHi(sender: this, count: hi.count + 1))
                }
                
                break;
            default :
            print("I do not know what you're talking about")
        }
    }
}

class Pong: Actor {
    override func receive(msg : Message) -> Void {
        switch msg {
        case let n where n is SayHi:
            let hi = msg as! SayHi
            print("got message in Pong")
            if hi.count > 10 {
                print("The end")
            } else {
                self.sender!.tell(SayHi(sender: this, count: hi.count + 1))
            }
            
            break;
        default :
            print("I do not know what you're talking about")
        }
    }
}
