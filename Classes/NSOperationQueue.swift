//
//  NSOperationQueue.swift
//  Actors
//
//  Created by Dario on 10/5/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation

prefix operator ^ {}

/**
 Convenience operator that executes a block with type (Void) -> (Void) in the main queue.
 
 Replaces:
 
 ```
 NSOperationQueue.mainQueue().addOperationWithBlock({
 print("blah")
 })
 ```
 
 with
 
 ```
 ^{print("blah")}
 ```
 
 */

public prefix func ^ (block : (Void) -> (Void)) -> Void {
    NSOperationQueue.mainQueue().addOperationWithBlock(block)
}