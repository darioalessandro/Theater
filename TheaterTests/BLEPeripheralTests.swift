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
import CoreBluetooth

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
                
                it("should start with in idle state") {
                    let actor : Actor = system.actorForRef(system.actorOf(BLEPeripheral.self, name:  "BLEPeripheral2"))!
                    let peripheral = actor as! BLEPeripheral
                    let idle = peripheral.currentState()!.0
                    expect(idle).to(equal(peripheral.states.idle), description : "Failed to switch state")
                }
                
                it("should transition to advertising if it is forced to and then stop if required") {
                    //Simulating CoreBluetooth message
                    let actor : Actor = system.actorForRef(system.actorOf(BLEPeripheral.self, name:  "BLEPeripheral3"))!
                    let peripheral = actor as! BLEPeripheral
                    peripheral.peripheralManagerDidStartAdvertising(CBPeripheralManager(), error: nil)
                    expect(peripheral.currentState()!.0).toEventually(equal(peripheral.states.advertising), timeout: 5, pollInterval: 1, description : "Failed to switch state")
                    peripheral.this ! BLEPeripheral.StopAdvertising(sender : nil)
                    expect(peripheral.currentState()!.0).toEventually(equal(peripheral.states.idle), timeout: 5, pollInterval: 1, description : "Failed to switch state")
                    peripheral.this ! Harakiri(sender: nil)
                    expect(system.selectActor("BLEPeripheral3")).toEventually(beNil(), timeout: 10, pollInterval: 1, description: "peripheral never died")
                }
                
            })
            
        }
    }
}
