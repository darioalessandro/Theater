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
                
                let actor : Actor = system.actorForRef(system.actorOf(BLEPeripheral.self, name:  "BLEPeripheral1"))!
                let peripheral = actor as! BLEPeripheral
                
                it("should start with no listeners") {
                    expect(peripheral.listeners).to(beEmpty())
                    expect(peripheral.context).to(beIdenticalTo(system))
                    expect(system.selectActor("BLEPeripheral1")).toEventually(beIdenticalTo(peripheral.this), timeout: 10, pollInterval: 1, description: "peripheral never died")
                }
                
                it("should stop when requested") {
                    peripheral.this ! Harakiri(sender: nil)
                    expect(system.selectActor("BLEPeripheral1")).toEventually(beNil(), timeout: 10, pollInterval: 1, description: "peripheral never died")
                }
                
            })
            
            describe("states", {
                
                let actor : Actor = system.actorForRef(system.actorOf(BLEPeripheral.self, name:  "BLEPeripheral2"))!
                let peripheral = actor as! BLEPeripheral
                
                it("should start with in idle state") {
                    let idle = peripheral.currentState()!.0
                    expect(idle).to(equal(peripheral.states.idle), description : "Failed to switch state")
                }
                
                it("should transition to advertising if it is forced to") {
                    peripheral.become(peripheral.states.advertising, state: peripheral.advertising)
                    let advertising = peripheral.currentState()!.0
                    expect(advertising).to(equal(peripheral.states.advertising), description : "Failed to switch state")
                }
                
                it("should transition to back to idle if it is forced to") {
                    peripheral.unbecome()
                    let idle = peripheral.currentState()!.0
                    expect(idle).to(equal(peripheral.states.idle), description : "Failed to switch state")
                }
                
                it("should stop when requested") {
                    peripheral.this ! Harakiri(sender: nil)
                    expect(system.selectActor("BLEPeripheral1")).toEventually(beNil(), timeout: 10, pollInterval: 1, description: "peripheral never died")
                }
            })
            
        }
    }
}
