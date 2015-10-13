//
//  Actor.swift
//  Actors
//
//  Created by Dario Lencina on 9/26/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation


/**
'!' Is a shortcut for typing actor ! msg instead of actorRef.tell(msg)
*/

infix operator ! {associativity left precedence 130}

public func !(actorRef : ActorRef, msg : Message) -> Void {
    actorRef.tell(msg)
}

public typealias Receive = (Message) -> (Void)

/**

'Actor'

Actors are the central elements of Theater.

## Subclassing notes

You must subclass Actor to implement your own actor classes such as: BankAccount, Device, Person etc.

the single most important to override is

public func receive(msg : Message) -> Void

Which will be called when some other actor tries to ! (tell) you something

*/

public class Actor : NSObject {
    
    private var statesStack : Stack<(String,Receive)> = Stack()
    
    /**
    Each actor has it's own mailbox to process messages.
    */
    
    public let mailbox : NSOperationQueue = NSOperationQueue()
    
    /**
    Sender has a reference to the last actor ref that sent this actor a message
    */
    
    public var sender : Optional<ActorRef>
    
    /**
    Reference to the ActorRef of the current actor
    */
    
    public let this : ActorRef
    
    /**
    Context refers to the Actor System that this actor belongs to.
    */
    
    public let context : ActorSystem
    
    /**
    Actors can adopt diferent behaviours or states, you can "push" a new state into the statesStack by using this method.
    
    @param state: the new state to push
    @param name: The name of the new state
    */
    
    public func become(name : String, state : Receive) -> Void  {
        self.statesStack.push((name, state))
    }
    
    /**
    Pop the state at the head of the statesStack and go to the previous stored state
    */
    
    public func unbecome() {
        self.statesStack.pop()
    }
    
    /**
    Pop states from the statesStack until it finds name
    @param name: the state that you can to pop to.
    */
    
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
    
    /**
    This method will be called when there's an incoming message, notice that if you push a state int the statesStack this method will not be called anymore until you pop all the states from the statesStack.
    
    @param msg: the incoming message
    */
    
    public func receive(msg : Message) -> Void {
        switch msg {
            case is Harakiri:
                self.context.stop(self.this)
                break
            default :
                print("message not handled \(NSStringFromClass(msg.dynamicType))")
        }
    }
    
    /**
    This method is used by the ActorSystem to communicate with the actors, do not override.
    */
    
    final public func tell(msg : Message) -> Void {
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
    
    /**
    Default constructor used by the ActorSystem to create a new actor
    */
    
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