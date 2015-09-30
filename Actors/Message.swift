//
//  Message.swift
//  Actors
//
//  Created by Dario Lencina on 9/26/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation

public class Message {
    
    public let sender : Optional<ActorRef>
    
    public func description() -> String {
        return "Message"
    }
    
    public init(sender : Optional<ActorRef>) {
        self.sender = sender
    }
}

public class Harakiri : Message {
    
    public override init(sender: Optional<ActorRef>) {
        super.init(sender: sender)
    }
}

