//
//  ArrayAsStack.swift
//  Actors
//
//  Created by Dario on 10/5/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation

/**
Stack data structure implementation for general purposes.
*/

public class Stack<A> {
    
    
    private var array : [A]
    
    public init() {
        self.array = [A]()
    }
    
    /**
    Push an element of type A into the Stack
    */
    
    public func push(element : A) -> Void {
        self.array.insert(element, atIndex: 0)
    }
    
    /**
    Pop an element from the Stack, if the stack is emplty, it returns None
    */
    
    public func pop() -> Optional<A> {
        if let first = self.array.first {
            self.array.removeFirst()
            return first
        } else {
            return Optional.None
        }
    }
    
    /**
    Peek into the stack, handy when you want to determine what's left in the Stack without removing the element from the stack
    */
    
    public func head() -> Optional<A> {
        return self.array.first
    }
    
}