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
    This extension contains all the messages that BLEPeripheral produces
*/

public extension BLEPeripheral {
    
    public class StartAdvertising : Message {
        public let advertisementData : [String : AnyObject]?
        
        public init(sender: Optional<ActorRef>, advertisementData : [String : AnyObject]?) {
            self.advertisementData = advertisementData
            super.init(sender: sender)
        }
    }
    
    public class StopAdvertising : Message {}
    
    public class DidStartAdvertising : Message {}
    
    public class DidStopAdvertising : Message {}
    
    public class FailedToStartAdvertising : Error {}
    
    public class Error : Message {
        let error : NSError
        init(sender : Optional<ActorRef>, error : NSError) {
            self.error = error
            super.init(sender: sender)
        }
    }
    
    public class CentralDidSubscribeToCharacteristic : Message {
        public let central: CBCentral
        public let characteristic: CBCharacteristic
        
        public init(sender: Optional<ActorRef>, central : CBCentral, characteristic : CBCharacteristic) {
            self.central = central
            self.characteristic = characteristic
            super.init(sender: sender)
        }
    }
    
    public class CentralDidUnsubscribeFromCharacteristic : CentralDidSubscribeToCharacteristic {}
    
    public class DidReceiveReadRequest : Message {
        public let request: CBATTRequest
        public init(sender: Optional<ActorRef>, request : CBATTRequest) {
            self.request = request
            super.init(sender: sender)
        }
    }
    
    public class RespondToRequest : DidReceiveReadRequest {
        
        public let result : CBATTError
        
        public init(sender: Optional<ActorRef>, request : CBATTRequest, result : CBATTError) {
            self.result = result
            super.init(sender: sender, request:request)
        }
        
    }
    
    public class DidReceiveWriteRequests : Message {
        public let requests: [CBATTRequest]
        
        public init(sender: Optional<ActorRef>, requests : [CBATTRequest]) {
            self.requests = requests
            super.init(sender: sender)
        }
    }
    
    public class PeripheralManagerDidUpdateState : Message {
        
        public let state : CBPeripheralManagerState
        
        public init(sender: Optional<ActorRef>, state : CBPeripheralManagerState) {
            self.state = state
            super.init(sender: sender)
        }
    }
    
    public class AddServices : Message {
        public let svcs : [CBMutableService]
        
        public init(sender: Optional<ActorRef>, svcs : [CBMutableService]) {
            self.svcs = svcs
            super.init(sender: sender)
        }
    }
    
    public class RemoveServices : AddServices {}
    
    public class UpdateCharacteristicValue : Message {
        public let char : CBMutableCharacteristic
        public let centrals : [CBCentral]?
        public let value : NSData
        
        public init(sender: Optional<ActorRef>,
                     char : CBMutableCharacteristic,
                 centrals : [CBCentral]?,
                    value : NSData) {
            self.char = char
            self.centrals = centrals
            self.value = value
            super.init(sender: sender)
        }
    }
}

/**
    Actor wrapper of CBPeripheralManager
*/

public final class BLEPeripheral : Actor, CBPeripheralManagerDelegate, WithListeners {
    
    public var listeners : [ActorRef] = []
    
    var charsubscriptions : [CBCentral : [CBCharacteristic]] = [CBCentral : [CBCharacteristic]]()
    
    struct States {
        let idle = "idle"
        let connected = "connected"
        let advertising = "advertising"
    }
    
    private let states : States = States()
    
    private var advertisementData : [String : AnyObject]?
    
    private let peripheral : CBPeripheralManager = CBPeripheralManager()
    
    required public init(context: ActorSystem, ref: ActorRef) {
        super.init(context: context, ref: ref)
        self.peripheral.delegate = self
    }
    
    override public func preStart() -> Void {
        become(states.idle, state: self.idle)
    }
    
    public override func receive(msg : Message) -> Void {
        switch(msg) {
            case let m as AddServices:
                m.svcs.forEach{self.peripheral.addService($0)}
            
            case let m as RemoveServices:
                m.svcs.forEach{self.peripheral.removeService($0)}
            
        default:
            super.receive(msg)
        }
    }
    
    private lazy var idle : Receive = {[unowned self] (msg : Message) in
        switch (msg) {
            case let m as StartAdvertising:
                self.peripheral.startAdvertising(m.advertisementData)
            
            case is FailedToStartAdvertising:
                self.broadcast(msg)
            
            default :
                self.receive(msg)
            }
    }
    
    private lazy var advertising : Receive = {[unowned self](msg : Message) in
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