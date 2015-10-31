//
//  WithListeners.swift
//  Actors
//
//  Created by Dario Lencina on 10/24/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation

/**
 Generic protocol so that Actors can have a collection of observers.
*/

public protocol WithListeners : class {
    
    var listeners : [ActorRef] { get set }
    
    /**
     adds sender to listeners
     */
    
    
    func addListener(sender : ActorRef?)
    
    /**
     removes sender from listeners
     */
    
    func removeListener(sender : ActorRef?)

    /**
     Send m to all listeners
     */
    
    func broadcast(msg : Message)

}

/**
 This default implementation of WithListeners mantains the listeners collection so that the Actor does not have to deal with that.
*/

extension WithListeners {

    /**
     adds sender to listeners
     */
    
    public func addListener(sender : ActorRef?) {
        if let s = sender {
            
            if (listeners.contains({ a -> Bool in return s.path.asString == a.path.asString}) == false) {
                listeners.append(s)
            }
        }
    }
    
    /**
     removes sender from listeners
    */
    
    public func removeListener(sender : ActorRef?) {
        if let l = sender,
            n = listeners.indexOf({ a -> Bool in  return l.path.asString == a.path.asString}) {
                listeners.removeFirst(n)
        }
    }
    
    /**
    Send m to all listeners
    */
    
    public func broadcast(m : Message) { listeners.forEach { $0 ! m} }
}