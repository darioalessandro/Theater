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

public class ActorSystem  {
    
    var dictionary : Dictionary = [String : Actor]()
    
    let name : String
    
    public init(name : String) {
        self.name = name
    }
    
    public func actorOf(clz : Actor.Type, name : String) -> ActorRef {
        let actorClass  = clz
        let ref = ActorRef(context:self, path:ActorPath(path:name))
        let actorInstance : Actor = actorClass.init(context: self, ref: ref)
        dictionary[name] = actorInstance
        return ref
    }
    
    public func actorOf(clz : Actor.Type) -> ActorRef {
        let uuidString = NSUUID.init().UUIDString
        return actorOf(clz, name: uuidString)
    }
    
    private func actorForRef(ref : ActorRef) -> Optional<Actor> {
        return self.dictionary[ref.path.asString]
    }
    
    public func tell(msg : Message, recipient : ActorRef) -> Void {
        if let actor = actorForRef(recipient) {
            actor.tell(msg)
        } else {
            print("Unable to send message")
        }
    }
}