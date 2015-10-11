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

public typealias Receive = (Message) -> (Void)

public class Actor : NSObject {
    
    private var statesStack : Stack<(String,Receive)> = Stack()
    
    public let mailbox : NSOperationQueue = NSOperationQueue()
    
    public var sender : Optional<ActorRef>
    
    public let this : ActorRef
    
    public let context : ActorSystem
    
    public func become(name : String, state : Receive) -> Void  {
        self.statesStack.push((name, state))
    }
    
    public func unbecome() {
        self.statesStack.pop()
    }
    
    public func popToState(name : String) {
        if let (hName, _ ) = self.statesStack.head() {
            if hName != name {
                unbecome()
                popToState(name)
            }
        } else {
            print("unable to find state with name \(name)")
        }
    }
    
    public func receive(msg : Message) -> Void {
        switch msg {
            case is Harakiri:
                self.context.stop(self.this)
                break
            default :
                print("message not handled \(NSStringFromClass(msg.dynamicType))")
        }
    }
    
    public func tell(msg : Message) -> Void {
        mailbox.addOperationWithBlock { () -> Void in
            self.sender = msg.sender
            print("Tell = \(self.sender?.path.asString) \(msg) \(self.this.path.asString) ")
            if let (name,state) : (String,Receive) = self.statesStack.head() {
                print("Sending message to state \(name)")
                state(msg)
            } else {
                self.receive(msg)
            }
        }
    }
    
    required public init(context : ActorSystem, ref : ActorRef) {
        mailbox.maxConcurrentOperationCount = 1 //serial queue
        sender = Optional.None
        self.context = context
        self.this = ref
    }
    
    deinit {
        print("killing \(self.this.path.asString)")
    }

}