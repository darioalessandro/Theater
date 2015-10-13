//
//  ActorContext.swift
//  Actors
//
//  Created by Dario Lencina on 9/27/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation

/**
An actor system has a tree like structure, ActorPath gives you an url like way to find an actor inside a given actor system.

@warning: We still do not support multiple levels of actors. Currently all actors are direct children of the ActorSystem that it belongs to.
*/

public class ActorPath {
    
    public let asString : String
    
    public init(path : String) {
        self.asString = path
    }
}

/**
'ActorRef' provides a reference to a given 'Actor', you should always talk to actors though it's ActorRef.
*/

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

/**
The first rule about actors is that you should not access them directly, you always talk to them through it's ActorRef, but for testing sometimes is really convenient to just get the actor and inspect it's properties, that is the reason why we provide 'TestActorSystem' please do not use it in your AppCode, only in tests.
*/

public class TestActorSystem : ActorSystem {
    public override func actorForRef(ref : ActorRef) -> Optional<Actor> {
        return super.actorForRef(ref)
    }
}

/**

All actors live in 'ActorSystem'.

You might have more than 1 actor system.

For convenience, we provide AppActorSystem.shared which provides a default actor system.

*/

public class ActorSystem  {
    
    /**
    @warning: this contaings a dic with all the actors that belong to the 'ActorSystem' eventually this will look more like a graph than a dic.
    */
    
    var actors : Dictionary = [String : Actor]()
    
    /**
    The name of the 'ActorSystem'
    */
    
    let name : String
    
    public init(name : String) {
        self.name = name
    }
    
    /**
    This is used to stop or kill an actor
    - Parameter actorRef: the actorRef of the actor that you want to stop.
    */
    
    public func stop(actorRef : ActorRef) {
        self.actors.removeValueForKey(actorRef.path.asString)
    }
    
    /**
    This method is used to instantiate actors using an Actor class as the 'blueprint' and assigning a unique name to it.
    */
    
    public func actorOf(clz : Actor.Type, name : String) -> ActorRef {
        let ref = ActorRef(context:self, path:ActorPath(path:name))
        let actorInstance : Actor = clz.init(context: self, ref: ref)
        actors[name] = actorInstance
        return ref
    }
    
    /**
    This method is used to instantiate actors using an Actor class as the 'blueprint' and assigning a random unique name to it.
    */
    
    public func actorOf(clz : Actor.Type) -> ActorRef {
        return actorOf(clz, name: NSUUID.init().UUIDString)
    }
    
    /**
    Private method to get the underlying actor given an actor ref, remember that you shoulf never access an actor directly other than for testing.
    */
    
    func actorForRef(ref : ActorRef) -> Optional<Actor> {
        return self.actors[ref.path.asString]
    }
    
    /**
    This method tries finding an actor given it's actorpath as a string
    - Parameter actorPath : the actor path as string
    - Returns: an ActorRef or None
    */
    
    public func selectActor(actorPath : String) -> Optional<ActorRef>{
        return self.actors[actorPath].map({ (a : Actor) -> ActorRef in return a.this})
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
