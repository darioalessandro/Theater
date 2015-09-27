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
    func isFailure() -> Bool {return false}
    
    /** Returns `true` if the `Try` is a `Success`, `false` otherwise.
    */
    func isSuccess() -> Bool {return false}

    
    /** Returns the value from this `Success` or throws the exception if this is a `Failure`.
    */
    func get() -> T {return NSObject() as! T}
    
    public func description() -> String {
        return "Try of \(self.get())"
    }
}

public class Success<T> : Try<T> {
    
    let value : T
    
    public init(value : T) {
        self.value = value
    }
    
    /** Returns `true` if the `Try` is a `Failure`, `false` otherwise.
    */
    override func isFailure() -> Bool {return false}
    
    /** Returns `true` if the `Try` is a `Success`, `false` otherwise.
    */
    override func isSuccess() -> Bool { return true}
    
    
    /** Returns the value from this `Success` or throws the exception if this is a `Failure`.
    */
    override func get() -> T {return self.value}
    
    override public func description() -> String {
        return "Success : \(self.get())"
    }
}

public class Failure<T> : Try<T> {
    
    public let exception : NSError
    
    
    public init(exception : NSError) {
        self.exception = exception
    }
    
    /** Returns `true` if the `Try` is a `Failure`, `false` otherwise.
    */
    override func isFailure() -> Bool {return true}
    
    /** Returns `true` if the `Try` is a `Success`, `false` otherwise.
    */
    override func isSuccess() -> Bool { return false}
    
    
    /** Returns the value from this `Success` or throws the exception if this is a `Failure`.
    */
    override func get() -> T {
        NSException.raise(self.exception.description, format: "", arguments: getVaList([""]))
        return NSObject() as! T
    }
    
    override public func description() -> String {
        return "Failure : \(self.exception)"
    }
}

