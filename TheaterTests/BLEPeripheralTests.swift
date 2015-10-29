//
//  BLEPeripheralTests.swift
//  Actors
//
//  Created by Dario Lencina on 10/28/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Theater

class BLEPeripheralTests: QuickSpec {
    
    override func spec() {
        
        describe("BLEPeripheral") {
            
            let system = TestActorSystem(name: "testo")
            
            describe("lifecycle", {
                
                let actor : Actor = system.actorForRef(system.actorOf(BLEPeripheral.self, name:  "BLEPeripheral"))!
                let peripheral = actor as! BLEPeripheral
                
                it("should start with no listeners") {
                    expect(peripheral.listeners).to(beEmpty())
                    expect(peripheral.context).to(beIdenticalTo(system))
                    expect(system.selectActor("BLEPeripheral")).toEventually(beIdenticalTo(peripheral.this), timeout: 10, pollInterval: 1, description: "peripheral never died")
                }
                
                it("should stop when requested") {
                    peripheral.this ! Harakiri(sender: nil)
                    expect(system.selectActor("BLEPeripheral")).toEventually(beNil(), timeout: 10, pollInterval: 1, description: "peripheral never died")
                }
                
            })
        }
    }
}
