//
//  ViewControllerActor.swift
//  ActorsParty
//
//  Created by Dario on 10/30/15.
//  Copyright © 2015 Dario. All rights reserved.
//

import UIKit


/**
    This message is used to set the view controller to a subclass of ViewCtrlActor
*/

public class SetViewCtrl<T : UIViewController> : Actor.Message {
    
    /**
     Da controller
    */
    
    public let ctrl : T
    
    /**
     Constructor
    */
    
    public init(ctrl : T) {
        self.ctrl = ctrl
        super.init(sender: nil)
    }
}

/**
 Convenience subclass of Actor to bind a UIViewController, which is very common when dealing with UIKit.
*/

public class ViewCtrlActor<A : UIViewController> : Actor {
    
    public let waitingForCtrlState = "waitingForCtrl"
    
    public let withCtrlState = "withCtrl"
    
    /**
    Subclasses must override this constructor.
    */
    
    required public init(context : ActorSystem, ref : ActorRef) {
        super.init(context: context, ref: ref)
    }
    
    /**
    By default, the ViewCtrlActor instances go to the waitingForCtrl state.
    */
    
    override public func preStart() {
        super.preStart()
        self.become(self.waitingForCtrlState, state: self.waitingForCtrl)
    }
    
    /**
    This built in method waits for a SetViewCtrl message to transition to the withCtrl state.
    */
    
    final lazy var waitingForCtrl : Receive = {[unowned self](msg : Actor.Message) in
        switch(msg) {
            case let a as SetViewCtrl<A>:
                unowned let b = a.ctrl
                self.become(self.withCtrlState, state:self.withCtrl(b))
                
            default:
                self.receive(msg)
        }
    }
    
    /**
     Subclasses of ViewCtrlActor must override this method to handle messages.
     
     - parameter ctrl : controller that was set to this Actor
    */
    
    public func withCtrl(ctrl : A) -> Receive {
        return { (msg : Actor.Message) in }
    }
    
    deinit {
        print("killing")
    }
    
}

