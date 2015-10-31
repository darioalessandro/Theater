//
//  NSOperationQueue.swift
//  Actors
//
//  Created by Dario on 10/5/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation

/**
Convenience operator that executes a block with type (Void) -> (Void) in the main queue.
*/

prefix operator ^ {}

/**
 Convenience operator that executes a block with type (Void) -> (Void) in the main queue.
 */

public prefix func ^ (block : (Void) -> (Void)) -> Void {
    NSOperationQueue.mainQueue().addOperationWithBlock(block)
}