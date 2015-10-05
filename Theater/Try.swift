//
//  Try.swift
//  Actors
//
//  Created by Dario Lencina on 9/26/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation

public class Try<T> {

    /** Returns `true` if the `Try` is a `Failure`, `false` otherwise.
    */
    public func isFailure() -> Bool {return false}
    
    /** Returns `true` if the `Try` is a `Success`, `false` otherwise.
    */
    public func isSuccess() -> Bool {return false}
    
    public func hasValue() -> Optional<T> {return Optional.None}

    /** Returns the value from this `Success` or throws the exception if this is a `Failure`.
    */
    public func get() -> T {return NSObject() as! T}
    
    public func description() -> String {
        return "Try"
    }
    
    public func map<U>(f : (T) -> (U)) -> Try<U> {
        return Try<U>()
    }
    
    class func gen(r: T) -> Try<T> {
        do {
            let s = Success(value : r)
            return s
        }catch let error as NSError {
            return Failure(exception : error)
        }
        
    }
}

public class Success<T> : Try<T> {
    
    private let value : T
    
    public init(value : T) { self.value = value}
    
    override public func isFailure() -> Bool {return false}
    
    override public func isSuccess() -> Bool { return true}
    
    override public func get() -> T {return self.value}
    
    override public func hasValue() -> Optional<T> {return Optional.Some(self.value)}
    
    override public func description() -> String {
        return "Success : \(self.get())"
    }
    
    override public func map<U>(f : (T) -> (U)) -> Try<U> {
        return Try<U>.gen(f(self.value))
    }
    
}

public class Failure<T> : Try<T> {
    
    public let exception : NSError
    
    public init(exception : NSError) {self.exception = exception}

    override public func isFailure() -> Bool {return true}
    
    override public func isSuccess() -> Bool { return false}
    
    override public func get() -> T {
        NSException.raise(self.exception.description, format: "", arguments: getVaList([""]))
        return NSObject() as! T
    }
    
    override public func description() -> String {
        return "Failure : \(self.exception)"
    }
    
    override public func map<U>(f : (T) -> (U)) -> Failure<U> {
        return self as! Failure<U>
    }

}

