//
//  WithListeners.swift
//  Actors
//
//  Created by Dario Lencina on 10/24/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation

public protocol WithListeners : class {
    
    var listeners : [ActorRef] { get set }
    
    func addListener(sender : Optional<ActorRef>)
    
    func removeListener(sender : Optional<ActorRef>)

}

extension WithListeners {
        
    public func addListener(sender : Optional<ActorRef>) {
        if let s = sender {
            
            if (listeners.contains({ a -> Bool in return s.path.asString == a.path.asString}) == false) {
                listeners.append(s)
            }
        }
    }
    
    public func removeListener(sender : Optional<ActorRef>) {
        if let l = sender,
            n = listeners.indexOf({ a -> Bool in  return l.path.asString == a.path.asString}) {
                listeners.removeFirst(n)
        }
    }
}