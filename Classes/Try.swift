//
//  Try.swift
//  Actors
//
//  Created by Dario Lencina on 9/26/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation

public class Try<T> : NSCoder {
    
    private let e : NSException = NSException(name: "invalid usage", reason: "please do not use this class directly, use Success || Failure", userInfo: nil)

    public func isFailure() -> Bool {e.raise(); return false}
    
    public func isSuccess() -> Bool {e.raise(); return false}
    
    public func toOptional() -> Optional<T> {
        return  Optional.None
    }
    
    public func get() -> T { e.raise(); return NSObject() as! T}
    
    public func map<U>(f : (T) -> (U)) -> Try<U> {return Try<U>()}
    
    public func getOrElse(d : (Void) -> T) -> T {
        if self.isSuccess() {
            return get()
        }else{
            return d()
        }
    }
    
    class func gen(r: T) -> Try<T> {
        do {
            let s = Success(value : r)
            return s
        } catch let error as NSError {
            return Failure(exception : error)
        }
    }
    
    override public init() {
        super.init()
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {

    }
    
    public init?(coder aDecoder: NSCoder) {
        super.init()
    }
}

public class Success<T> : Try<T> {
    
    private let value : T
    
    public init(value : T) {
        self.value = value
        super.init()
    }
    
    override public func isFailure() -> Bool {return false}
    
    override public func isSuccess() -> Bool { return true}
    
    override public func get() -> T {return self.value}
    
    override public func map<U>(f : (T) -> (U)) -> Try<U> {
        return Try<U>.gen(f(self.value))
    }
    
    override public func toOptional() -> Optional<T> {
        return  Optional.Some(self.value)
    }
    
    override public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.value as! NSObject, forKey:"value")
    }
    
    override public init?(coder aDecoder: NSCoder) {
        self.value = aDecoder.decodeObjectForKey("value") as! T
        super.init()
    }
    
}

public class Failure<T> : Try<T> {
    
    public let exception : NSError
    
    public init(exception : NSError) {
        self.exception = exception
        super.init()
    }

    override public func isFailure() -> Bool {return true}
    
    override public func isSuccess() -> Bool { return false}
    
    override public func get() -> T {
        NSException.raise(self.exception.description, format: "", arguments: getVaList([""]))
        return NSObject() as! T
    }
    
    override public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.exception, forKey:"exception")
    }
    
    override public init?(coder aDecoder: NSCoder) {
        self.exception = aDecoder.decodeObjectForKey("exception") as! NSError
        super.init()
    }
    
    override public func map<U>(f : (T) -> (U)) -> Failure<U> {
        return self as! Failure<U>
    }

}

