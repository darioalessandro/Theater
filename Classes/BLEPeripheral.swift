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
    
    public var listeners : [ActorRef] = []
    
    var charsubscriptions : [CBCentral : [CBCharacteristic]] = [CBCentral : [CBCharacteristic]]()
    
    public struct States {
        public let idle = "idle"
        public let connected = "connected"
        public let advertising = "advertising"
    }
    
    public let states : States = States()
    
    private var advertisementData : [String : AnyObject]?
    
    private var peripheral : CBPeripheralManager
    
    required public init(context: ActorSystem, ref: ActorRef) {
        self.peripheral = CBPeripheralManager() //Stupid swift
        super.init(context: context, ref: ref)
        self.peripheral = CBPeripheralManager(delegate: self, queue: self.mailbox.underlyingQueue)
        self.peripheral.removeAllServices()
    }
    
    override public func preStart() -> Void {
        become(states.idle, state: self.idle)
    }
    
    public override func receive(msg : Message) -> Void {
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
    
    public lazy var idle : Receive = {[unowned self] (msg : Message) in
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
    
    public lazy var advertising : Receive = {[unowned self](msg : Message) in
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
                if var subs = self.charsubscriptions[m.central] {
                    subs.append(m.characteristic)
                } else {
                    self.charsubscriptions[m.central] = [m.characteristic]
                }
                self.broadcast(msg)
                
            case let m as CentralDidUnsubscribeFromCharacteristic:
                if var subs = self.charsubscriptions[m.central],
                    let i = subs.indexOf(m.characteristic) {
                        subs.removeAtIndex(i)
                }
                self.broadcast(msg)
            
            default :
                self.receive(msg)
        }
    }
    
    public func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        this ! PeripheralManagerDidUpdateState(sender : this, state : peripheral.state)
    }
    
    public func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        this ! CentralDidSubscribeToCharacteristic(sender: this, central: central, characteristic: characteristic)
    }
    
    public func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
            this ! CentralDidUnsubscribeFromCharacteristic(sender: this, central: central, characteristic: characteristic)
    }
    
    public func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager, error: NSError?) {
        if let error = error {
            self.popToState(self.states.idle)
            this ! FailedToStartAdvertising(sender: this, error: error)
        } else {
            self.become(self.states.advertising, state: self.advertising)
            this ! DidStartAdvertising(sender: this)
        }
    }
    
    public func peripheralManager(peripheral: CBPeripheralManager, didReceiveReadRequest request: CBATTRequest) {
        this ! DidReceiveReadRequest(sender: this, request: request)
    }
    
    public func peripheralManager(peripheral: CBPeripheralManager, didReceiveWriteRequests requests: [CBATTRequest]) {
        this ! DidReceiveWriteRequests(sender: this, requests: requests)
    }
    
    /*!
    *  @method peripheralManagerIsReadyToUpdateSubscribers:
    *
    *  @param peripheral   The peripheral manager providing this update.
    *
    *  @discussion         This method is invoked after a failed call to @link updateValue:forCharacteristic:onSubscribedCentrals: @/link, when <i>peripheral</i> is again
    *                      ready to send characteristic value updates.
    *
    */
    
    public func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager) {
        //TODO: What is this for?
    }
    
    public func peripheralManager(peripheral: CBPeripheralManager, willRestoreState dict: [String : AnyObject]) {
        //TODO: what is this for?
    }
    
    deinit {
        self.peripheral.stopAdvertising()
    }
    
}