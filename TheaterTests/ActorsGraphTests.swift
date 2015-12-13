//
//  ActorsGraphTst.swift
//  Actors
//
//  Created by Dario Lencina on 12/12/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Theater

class ActorGraphTests: QuickSpec {
    
    override func spec() {
        
        describe("BLEPeripheral") {
            it("should stop when requested") {
                expect(true)
             //expect(system.selectActor("BLEPeripheral1")).toEventually(beNil(), timeout: 10, pollInterval: 1, description: "peripheral never died")
            }
        }
    }

}