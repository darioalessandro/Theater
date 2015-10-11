//
//  ArrayAsStack.swift
//  Actors
//
//  Created by Dario on 10/5/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation

public class Stack<A> {
    
    var array : [A] 
    
    public init() {
        self.array = [A]()
    }
    
    public func push(element : A) -> Void {
        self.array.insert(element, atIndex: 0)
    }
    
    public func pop() -> Optional<A> {
        if let first = self.array.first {
            self.array.removeFirst()
            return first
        } else {
            return Optional.None
        }
    }
    
    public func head() -> Optional<A> {
        return self.array.first
    }
    
}