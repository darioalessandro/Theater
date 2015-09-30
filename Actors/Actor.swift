//
//  Actor.swift
//  Actors
//
//  Created by Dario Lencina on 9/26/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation

infix operator ! {associativity left precedence 130}

public func !(actorRef : ActorRef, msg : Message) -> Void {
    actorRef.tell(msg)
}

public class Actor : NSObject {
    
    public let mailbox : NSOperationQueue = NSOperationQueue()
    
    public var sender : Optional<ActorRef>
    
    public let this : ActorRef
    
    private let context : ActorSystem
    
    required public init(context : ActorSystem, ref : ActorRef) {
        mailbox.maxConcurrentOperationCount = 1 //serial queue
        sender = Optional.None
        self.context = context
        self.this = ref
    }
    
    public func receive(msg : Message) -> Void {
        switch msg {
        case is Harakiri:
            self.context.stop(this)
            break;
        default :
            print("message not handled %@", [msg.description()])
        }
    }
    
    public func tell(msg : Message) -> Void {
        mailbox.addOperationWithBlock { () -> Void in
            self.sender = msg.sender
            self.receive(msg)
        }
    }
    
    deinit {
        print("killing \(this.path.asString)")
    }

}