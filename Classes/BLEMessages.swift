//
//  BLEMessages.swift
//  Actors
//
//  Created by Dario Lencina on 10/15/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import CoreBluetooth

/**
BLECentral related messages
*/

public class BLECentralMsg {
    
    /**
    Namespace for Peripheral related messages
    */
    
    public class Peripheral {
        /**
        Tries to connect to CBPeripheral
        */
        public class Connect : Message {
            public let peripheral : CBPeripheral
            
            public init(sender: Optional<ActorRef>, peripheral : CBPeripheral) {
                self.peripheral = peripheral
                super.init(sender: sender)
            }
        }
        
        /**
        Message sent from BLECentral to subscribers when it connects to peripheral
        */
        public class OnConnect : Connect {}
        
        /**
        Message sent from BLECentral to subscribers when it disconnects from peripheral
        */
        
        public class OnDisconnect : Connect {
            
            let error : Optional<NSError>
            
            public init(sender: Optional<ActorRef>, peripheral: CBPeripheral, error : Optional<NSError>) {
                self.error = error
                super.init(sender: sender, peripheral: peripheral)
            }
        }
        
        /**
        Message sent from BLECentral to force disconnecting all peripherals
        */
        
        public class Disconnect : Connect {}
    }
    
    
    /**
    Use this message to tell BLECentral to start scanning, scanning success depends on the status of the BLE hardware, BLECentral will message all it's listeners when it actually starts scanning an @see BLECentralMsg#StateChanged when it actually starts scanning.
    */
    
    public class StartScanning : Message {
        
        public let services : Optional<[CBUUID]>
        
        public init(services : Optional<[CBUUID]>, sender : Optional<ActorRef>) {
            self.services = services
            super.init(sender: sender)
        }
    }
    
    /**
    Use AddListener to subscribe to BLECentral events such as @see BLECentralMsg#DevicesObservationUpdate.
    */
    
    public class AddListener : Message {}
    
    /**
    Use RemoveListener to stop receiving BLECentral events such as #BLECentralMsg.DevicesObservationUpdate.
    */
    
    public class RemoveListener : Message {}
    
    /**
    Tell BLECentral to stop scanning
    */
    
    public class StopScanning : Message {}
    
    /**
    An StateChanged message will be sent to all #BLECentral.listeners when the underlying CBCentralManager changes it's state.
    */
    
    public class StateChanged : Message {
        let state : CBCentralManagerState
        
        init(sender : ActorRef, state : CBCentralManagerState) {
            self.state = state
            super.init(sender: sender)
        }
    }
    
    /**
    DevicesObservationUpdate contains an immutable dictionary with all the devices that BLECentral saw and all the observations (#BLEPeripheral) since it was created, this is very useful when monitoring RSSI because it provides a time dimension, which is important to determine if the customer is moving towards the BLE device or away from it.
    */
    
    public class DevicesObservationUpdate : Message {
        public let devices : [String : [BLEPeripheralObservation]]
        
        init(sender : Optional<ActorRef>, devices : [String : [BLEPeripheralObservation]]) {
            self.devices = devices
            super.init(sender: sender)
        }
    }
    
    /**

    */
    public class DidDiscoverCharacteristicsForService : Message {
        public let chars : [CBCharacteristic]
        public let svc : CBService
        public let peripheral : CBPeripheral
        
        public init(sender: Optional<ActorRef>, chars : [CBCharacteristic], svc : CBService, peripheral : CBPeripheral) {
            self.chars = chars
            self.svc = svc
            self.peripheral = peripheral
            super.init(sender: sender)
        }
    }
    
    public class DidDiscoverServices : Message {
        public let svcs : [CBService]
        public let peripheral : CBPeripheral
        
        public init(sender: Optional<ActorRef>, svcs : [CBService], peripheral : CBPeripheral) {
            self.svcs = svcs
            self.peripheral = peripheral
            super.init(sender: sender)
        }
    }
    
    public class DidUpdateValueForCharacteristic : Message {
        public let char : CBCharacteristic
        public let peripheral : CBPeripheral
        public let error : NSError?
        
        public init(sender : Optional<ActorRef>, char : CBCharacteristic, peripheral : CBPeripheral, error : NSError?) {
            self.char = char
            self.peripheral = peripheral
            self.error = error
            super.init(sender : sender)
        }
    }
}

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
