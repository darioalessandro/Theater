//
//  Actor.swift
//  Actors
//
//  Created by Dario Lencina on 9/26/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation

public class Actor {
    
    private let mailbox : NSOperationQueue = NSOperationQueue()
    
    public var sender : Optional<Actor>
    
    public init() {
        mailbox.maxConcurrentOperationCount = 1 //serial queue
        sender = Optional.None
    }
    
    public func receive(msg : Message) -> Void {
        switch msg {
            default :
                NSException.raise("message not handled", format: "%@", arguments : getVaList([msg.description()]))
        }
    }
    
    public func send (msg : Message) -> Void {
        mailbox.addOperationWithBlock { () -> Void in
            self.sender = msg.sender
            self.receive(msg)
        }
    }
}