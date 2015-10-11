//
//  Message.swift
//  Actors
//
//  Created by Dario Lencina on 9/26/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation

@objc public class Message : NSObject {
    
    public let sender : Optional<ActorRef>
    
     public init(sender : Optional<ActorRef>) {
        self.sender = sender
    }
    
}

public class Harakiri : Message {
    
    public override init(sender: Optional<ActorRef>) {
        super.init(sender: sender)
    }
}

public class MessageWithOperationId : Message {
    public let operationId : NSUUID
    
    public init(sender: Optional<ActorRef>, operationId : NSUUID) {
        self.operationId = operationId
        super.init(sender : sender)
    }
}

public class DeadLetter : Message {
    public let deadActor : ActorRef
    public let message : Message
    
    public init(message : Message, sender: Optional<ActorRef>, deadActor : ActorRef) {
        self.deadActor = deadActor
        self.message = message
        super.init(sender: sender)
    }
}

