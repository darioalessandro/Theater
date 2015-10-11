//
//  NSOperationQueue.swift
//  Actors
//
//  Created by Dario on 10/5/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation

prefix operator ^ {}
public prefix func ^ (block : (Void) -> (Void)) -> Void {
    NSOperationQueue.mainQueue().addOperationWithBlock(block)
}