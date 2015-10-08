//
//  ActorContext.swift
//  Actors
//
//  Created by Dario Lencina on 9/27/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation

public class ActorPath {
    
    public let asString : String
    
    public init(path : String) {
        self.asString = path
    }
}

public class ActorRef {
    
    public let context : ActorSystem
    
    public let path : ActorPath
    
    public init(context : ActorSystem, path : ActorPath) {
        self.context = context
        self.path = path
    }

    public func tell (msg : Message) -> Void {
        self.context.tell(msg, recipient:self)
    }
    
}

public class TestActorSystem : ActorSystem {
    public override func actorForRef(ref : ActorRef) -> Optional<Actor> {
        return super.actorForRef(ref)
    }
}

public class ActorSystem  {
    
    var actors : Dictionary = [String : Actor]()
    
    let name : String
    
    public init(name : String) {
        self.name = name
    }
    
    public func stop(actorRef : ActorRef) {
        self.actors.removeValueForKey(actorRef.path.asString)
    }
    
    public func actorOf(clz : Actor.Type, name : String) -> ActorRef {
        let ref = ActorRef(context:self, path:ActorPath(path:name))
        let actorInstance : Actor = clz.init(context: self, ref: ref)
        actors[name] = actorInstance
        return ref
    }
    
    public func actorOf(clz : Actor.Type) -> ActorRef {
        return actorOf(clz, name: NSUUID.init().UUIDString)
    }
    
    func actorForRef(ref : ActorRef) -> Optional<Actor> {
        return self.actors[ref.path.asString]
    }
    
    public func tell(msg : Message, recipient : ActorRef) -> Void {
        if let actor = actorForRef(recipient) {
            actor.tell(msg)
        } else if let sender = msg.sender {
            sender ! DeadLetter(message: msg, sender:Optional.None, deadActor: recipient)
        } else {
            print("Dropped message \(msg)")
        }
    }
}
