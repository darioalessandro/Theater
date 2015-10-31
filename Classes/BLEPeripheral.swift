//
//  BLEPeripheral.swift
//  Actors
//
//  Created by Dario on 10/26/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import CoreBluetooth

/**
    Actor wrapper of CBPeripheralManager
*/

public final class BLEPeripheral : Actor, CBPeripheralManagerDelegate, WithListeners {
    
    /**
     All actors interested on changes in BLEPeripheral
    */
    
    public var listeners : [ActorRef] = []
    
    /**
     Centrals subscriptions to CBCharacteristics DB
    */
    
    var subscriptions : Subscriptions = Subscriptions()
    
    public struct States {
        public let idle = "idle"
        public let connected = "connected"
        public let advertising = "advertising"
    }
    
    /**
    Human readable states
     */
    
    public let states : States = States()
    
    /**
     CBPeripheral manager is the one that interacts with BLE hardware
     */
    
    private var peripheral : CBPeripheralManager
    
    required public init(context: ActorSystem, ref: ActorRef) {
        self.peripheral = CBPeripheralManager() //Stupid swift
        super.init(context: context, ref: ref)
        self.peripheral = CBPeripheralManager(delegate: self, queue: self.mailbox.underlyingQueue)
        self.peripheral.removeAllServices()
    }
    
    override public func preStart() -> Void {
        super.preStart()
        become(states.idle, state: self.idle)
    }
    
    /**
    This is the fallback message handler in case that the message is not handled on the other states
    */
    
    public override func receive(msg : Actor.Message) -> Void {
        switch(msg) {
            case let m as AddServices:
                if self.peripheral.state == .PoweredOn {
                    m.svcs.forEach{self.peripheral.addService($0)}
            }
            
            case let m as RemoveServices:
                m.svcs.forEach{self.peripheral.removeService($0)}
            
        default:
            super.receive(msg)
        }
    }
    
    /**
     Idle is the initial state
     */
    
    public lazy var idle : Receive = {[unowned self] (msg : Actor.Message) in
        switch (msg) {
            case let m as StartAdvertising:
                self.peripheral.startAdvertising(m.advertisementData)
                self.addListener(m.sender)
            
            case is FailedToStartAdvertising:
                self.broadcast(msg)
            
            default :
                self.receive(msg)
            }
    }
    
    /**
    Message receiver for the advertising state
    */
    
    public lazy var advertising : Receive = {[unowned self](msg : Actor.Message) in
        switch (msg) {
            
            case is DidStartAdvertising,
                 is DidReceiveWriteRequests,
                 is DidReceiveReadRequest:
                self.broadcast(msg)
            
            case let m as RespondToRequest:
                self.peripheral.respondToRequest(m.request, withResult : m.result)
            
            case let m as UpdateCharacteristicValue:
                self.peripheral.updateValue(m.value, forCharacteristic:m.char, onSubscribedCentrals: m.centrals)
            
            case is StopAdvertising:
                self.peripheral.stopAdvertising()
                self.peripheral.removeAllServices()
                self.unbecome()
                self.broadcast(DidStopAdvertising(sender: self.this))
            
            case let m as CentralDidSubscribeToCharacteristic:
                if var subs = self.subscriptions[m.central] {
                    subs.append(m.characteristic)
                } else {
                    self.subscriptions[m.central] = [m.characteristic]
                }
                self.broadcast(msg)
                self.broadcast(SubscriptionsChanged(sender: self.this, subscriptions: self.subscriptions))
                
            case let m as CentralDidUnsubscribeFromCharacteristic:
                if var subs = self.subscriptions[m.central],
                    let i = subs.indexOf(m.characteristic) {
                        subs.removeAtIndex(i)
                        if subs.count == 0 {
                            self.subscriptions.removeValueForKey(m.central)
                        }
                }
                self.broadcast(msg)
                self.broadcast(SubscriptionsChanged(sender: self.this, subscriptions: self.subscriptions))
            
            default :
                self.receive(msg)
        }
    }
    
    /**
     CBPeripheralManagerDelegate methods, BLEPeripheral hides this methods so that messages can interact with BLE devices using actors
     */
    
    
    public func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        this ! PeripheralManagerDidUpdateState(sender : this, state : peripheral.state)
    }
    
    /**
     CBPeripheralManagerDelegate methods, BLEPeripheral hides this methods so that messages can interact with BLE devices using actors
     */
    
    public func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        this ! CentralDidSubscribeToCharacteristic(sender: this, central: central, characteristic: characteristic)
    }
    
    /**
     CBPeripheralManagerDelegate methods, BLEPeripheral hides this methods so that messages can interact with BLE devices using actors
     */
    
    public func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
            this ! CentralDidUnsubscribeFromCharacteristic(sender: this, central: central, characteristic: characteristic)
    }
    
    /**
     CBPeripheralManagerDelegate methods, BLEPeripheral hides this methods so that messages can interact with BLE devices using actors
     */
    
    public func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager, error: NSError?) {
        if let error = error {
            self.popToState(self.states.idle)
            this ! FailedToStartAdvertising(sender: this, error: error)
        } else {
            self.become(self.states.advertising, state: self.advertising)
            this ! DidStartAdvertising(sender: this)
        }
    }
    
    /**
     CBPeripheralManagerDelegate methods, BLEPeripheral hides this methods so that messages can interact with BLE devices using actors
     */
    
    public func peripheralManager(peripheral: CBPeripheralManager, didReceiveReadRequest request: CBATTRequest) {
        this ! DidReceiveReadRequest(sender: this, request: request)
    }
    
    /**
     CBPeripheralManagerDelegate methods, BLEPeripheral hides this methods so that messages can interact with BLE devices using actors
     */
    
    public func peripheralManager(peripheral: CBPeripheralManager, didReceiveWriteRequests requests: [CBATTRequest]) {
        this ! DidReceiveWriteRequests(sender: this, requests: requests)
    }
    
    /**
     CBPeripheralManagerDelegate methods, BLEPeripheral hides this methods so that messages can interact with BLE devices using actors
     */
    
    public func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager) {
        //TODO: What is this for?
    }
    
    /**
     CBPeripheralManagerDelegate methods, BLEPeripheral hides this methods so that messages can interact with BLE devices using actors
     */
    
    public func peripheralManager(peripheral: CBPeripheralManager, willRestoreState dict: [String : AnyObject]) {
        //TODO: what is this for?
    }
    
    deinit {
        self.peripheral.stopAdvertising()
    }
    
}