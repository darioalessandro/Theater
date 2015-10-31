//
//  Actor.swift
//  Actors
//
//  Created by Dario Lencina on 9/26/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation

infix operator ! {associativity left precedence 130}

/**
 
 '!' Is a shortcut for typing:
 
 ```
 actor ! msg
 ```
 
 instead of
 
 ```
 actorRef.tell(msg)
 ```
 
 */

public func !(actorRef : ActorRef, msg : Actor.Message) -> Void {
    actorRef.tell(msg)
}

public typealias Receive = (Actor.Message) -> (Void)

/**

'Actor'

Actors are the central elements of Theater.

## Subclassing notes

You must subclass Actor to implement your own actor classes such as: BankAccount, Device, Person etc.

the single most important to override is
 
```
public func receive(msg : Actor.Message) -> Void
```
 
Which will be called when some other actor tries to ! (tell) you something

*/

public class Actor : NSObject {
    
    /**
    Here we save all the actor states
    */
    
    final private let statesStack : Stack<(String,Receive)> = Stack()
    
    /**
    Each actor has it's own mailbox to process Actor.Messages.
    */
    
    final public let mailbox : NSOperationQueue = NSOperationQueue()
    
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
    
    - Parameter state: the new state to push
    - Parameter name: The name of the new state, it is used in the logs which is very useful for debugging
    */
    
    final public func become(name : String, state : Receive) -> Void  {
        self.statesStack.push((name, state))
    }
    
    /**
    Pop the state at the head of the statesStack and go to the previous stored state
    */
    
    final public func unbecome() {
        self.statesStack.pop()
    }
    
    /**
    Current state
    - Returns: The state at the top of the statesStack
    */
     
    final public func currentState() -> (String,Receive)? {
        return self.statesStack.head()
    }
    
    /**
    Pop states from the statesStack until it finds name
    - Parameter name: the state that you can to pop to.
    */
    
    final public func popToState(name : String) -> Void {
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
    pop to root state
    */
     
    final public func popToRoot() -> Void {
        while !self.statesStack.isEmpty() {
            unbecome()
        }
    }
    
    /**
    This method will be called when there's an incoming message, notice that if you push a state int the statesStack this method will not be called anymore until you pop all the states from the statesStack.
    
    - Parameter msg: the incoming message
    */
    
    public func receive(msg : Actor.Message) -> Void {
        switch msg {
            case is Harakiri:
                self.context.stop(self.this)

            default :
                print("message not handled \(NSStringFromClass(msg.dynamicType))")
        }
    }
    
    /**
    This method is used by the ActorSystem to communicate with the actors, do not override.
    */
    
    final public func tell(msg : Actor.Message) -> Void {
        mailbox.addOperationWithBlock { () in
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
     Is called when an Actor is started. Actors are automatically started asynchronously when created. Empty default implementation.
    */
     
    public func preStart() -> Void {
        
    }
    
    /**
    Schedule Once is a timer that executes the code in block after seconds
    */
     
    final public func scheduleOnce(seconds:Double, block : Void -> Void) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC))), self.mailbox.underlyingQueue!, block)
    }
    
    /**
    Default constructor used by the ActorSystem to create a new actor, you should not call this directly, use  actorOf in the ActorSystem to create a new actor
    */
    
    required public init(context : ActorSystem, ref : ActorRef) {
        mailbox.maxConcurrentOperationCount = 1 //serial queue
        mailbox.underlyingQueue = dispatch_queue_create(ref.path.asString, nil)
        sender = Optional.None
        self.context = context
        self.this = ref
        super.init()
        self.preStart()
    }
    
    deinit {
        print("killing \(self.this.path.asString)")
    }

}