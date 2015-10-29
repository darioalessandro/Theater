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

public extension BLECentral {
    
    /**
    Namespace for Peripheral related messages
    */
    
    public class Peripheral {
        /**
        Tries to connect to CBPeripheral
        */
        public class Connect : Message {
            public let peripheral : CBPeripheral
            
            public init(sender: ActorRef?, peripheral : CBPeripheral) {
                self.peripheral = peripheral
                super.init(sender: sender)
            }
        }
        
        /**
        Message sent from BLECentral to subscribers when it connects to peripheral
        */
        public class OnConnect : Message {
            
            public let peripheralConnection : ActorRef?
            
            public let peripheral : CBPeripheral
            
            public init(sender: ActorRef?, peripheral: CBPeripheral, peripheralConnection : ActorRef?) {
                self.peripheralConnection = peripheralConnection
                self.peripheral = peripheral
                super.init(sender: sender)
            }
        }
        
        /**
        Message sent from BLECentral to subscribers when it disconnects from peripheral
        */
        
        public class OnDisconnect : Message {
            
            let error : Optional<NSError>
            
            public let peripheral : CBPeripheral
            
            public init(sender: Optional<ActorRef>, peripheral: CBPeripheral, error : Optional<NSError>) {
                self.peripheral = peripheral
                self.error = error
                super.init(sender: sender)
            }
        }
        
        /**
        Message sent from BLECentral to force disconnecting all peripherals
        */
        
        public class Disconnect : Message {
            public let peripheral : CBPeripheral
            
            public init(sender: ActorRef?, peripheral : CBPeripheral) {
                self.peripheral = peripheral
                super.init(sender: sender)
            }
        }
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
    
    public class CentralDidUnsubscribeFromCharacteristic : Message {
        public let central: CBCentral
        public let characteristic: CBCharacteristic
        
        public init(sender: Optional<ActorRef>, central : CBCentral, characteristic : CBCharacteristic) {
            self.central = central
            self.characteristic = characteristic
            super.init(sender: sender)
        }

    }
    
    public class DidReceiveReadRequest : Message {
        public let request: CBATTRequest
        public init(sender: Optional<ActorRef>, request : CBATTRequest) {
            self.request = request
            super.init(sender: sender)
        }
    }
    
    public class RespondToRequest : Message {
        public let result : CBATTError
        public let request: CBATTRequest
        
        public init(sender: Optional<ActorRef>, request : CBATTRequest, result : CBATTError) {
            self.result = result
            self.request = request
            super.init(sender: sender)
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
    
    public class RemoveServices : Message {
        public let svcs : [CBMutableService]
        
        public init(sender: Optional<ActorRef>, svcs : [CBMutableService]) {
            self.svcs = svcs
            super.init(sender: sender)
        }
    }
    
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
 PeripheralConnection messages, most are just wrappers for the CBPeripheralDelegate original methods
 */

public extension BLEPeripheralConnection {
    
    public class AddListener : Message {}
    
    public class SetPeripheral : Message {
        public let peripheral : CBPeripheral
        
        public init(sender: Optional<ActorRef>, peripheral : CBPeripheral) {
            self.peripheral = peripheral
            super.init(sender: sender)
        }
    }
    
    public class PeripheralDidUpdateName : Message {
        
        public let peripheral : CBPeripheral
        
        public init(sender: Optional<ActorRef>, peripheral : CBPeripheral) {
            self.peripheral = peripheral
            super.init(sender: sender)
        }
    }
    
    public class DidModifyServices : Message {
        
        public let peripheral : CBPeripheral
        
        public let invalidatedServices : [CBService]
        
        public init(sender: Optional<ActorRef>, peripheral : CBPeripheral, invalidatedServices:[CBService]) {
            self.peripheral = peripheral
            self.invalidatedServices = invalidatedServices
            super.init(sender: sender)
        }
    }
    
    public class DidReadRSSI : Message {
        
        public let peripheral : CBPeripheral
        
        public let error : NSError?
        
        public let RSSI : NSNumber
        
        public init(sender: Optional<ActorRef>,
            peripheral : CBPeripheral,
            error : NSError?,
            RSSI : NSNumber) {
                self.error = error
                self.RSSI = RSSI
                self.peripheral = peripheral
                super.init(sender: sender)
        }
    }
    
    public class DidDiscoverServices : Message {
        
        public let peripheral : CBPeripheral
        
        public let error : NSError?
        
        public init(sender: Optional<ActorRef>,
            peripheral : CBPeripheral,
            error : NSError?) {
                self.error = error
                self.peripheral = peripheral
                super.init(sender: sender)
        }
    }
    
    public class DiscoverServices : Message {
        public let services : [CBUUID]
        
        public init(sender: Optional<ActorRef>,
            services : [CBUUID]) {
                self.services = services
                super.init(sender: sender)
        }
    }
    
    public class DidDiscoverIncludedServicesForService : Message {
        
        public let peripheral : CBPeripheral
        
        public let error : NSError?
        
        public let service: CBService
        
        public init(sender: Optional<ActorRef>,
            peripheral : CBPeripheral,
            service : CBService,
            error : NSError?) {
                self.service = service
                self.error = error
                self.peripheral = peripheral
                super.init(sender: sender)
        }
    }
    
    public class DidDiscoverCharacteristicsForService : Message {
        public let peripheral : CBPeripheral
        
        public let error : NSError?
        
        public let service: CBService
        
        public init(sender: Optional<ActorRef>,
            peripheral : CBPeripheral,
            service : CBService,
            error : NSError?) {
                self.service = service
                self.error = error
                self.peripheral = peripheral
                super.init(sender: sender)
        }
    }
    
    public class DidUpdateValueForCharacteristic : Message {
        
        public let peripheral : CBPeripheral
        
        public let error : NSError?
        
        public let characteristic: CBCharacteristic
        
        public init(sender: Optional<ActorRef>,
            peripheral : CBPeripheral,
            characteristic: CBCharacteristic,
            error : NSError?) {
                self.characteristic = characteristic
                self.error = error
                self.peripheral = peripheral
                super.init(sender: sender)
        }
    }
    
    public class DidWriteValueForCharacteristic : Message {
        public let peripheral : CBPeripheral
        
        public let error : NSError?
        
        public let characteristic: CBCharacteristic
        
        public init(sender: Optional<ActorRef>,
            peripheral : CBPeripheral,
            characteristic: CBCharacteristic,
            error : NSError?) {
                self.characteristic = characteristic
                self.error = error
                self.peripheral = peripheral
                super.init(sender: sender)
        }
    }
    
    public class DidUpdateNotificationStateForCharacteristic : Message {
        public let peripheral : CBPeripheral
        
        public let error : NSError?
        
        public let characteristic: CBCharacteristic
        
        public init(sender: Optional<ActorRef>,
            peripheral : CBPeripheral,
            characteristic: CBCharacteristic,
            error : NSError?) {
                self.characteristic = characteristic
                self.error = error
                self.peripheral = peripheral
                super.init(sender: sender)
        }
    }
    
    public class DidDiscoverDescriptorsForCharacteristic : Message {
        public let peripheral : CBPeripheral
        
        public let error : NSError?
        
        public let characteristic: CBCharacteristic
        
        public init(sender: Optional<ActorRef>,
            peripheral : CBPeripheral,
            characteristic: CBCharacteristic,
            error : NSError?) {
                self.characteristic = characteristic
                self.error = error
                self.peripheral = peripheral
                super.init(sender: sender)
        }
    }
    
    public class DidUpdateValueForDescriptor : Message {
        public let peripheral: CBPeripheral
        public let descriptor: CBDescriptor
        public let error: NSError?
        
        public init(sender: Optional<ActorRef>,
            peripheral: CBPeripheral,
            descriptor: CBDescriptor,
            error: NSError?) {
                self.peripheral = peripheral
                self.descriptor = descriptor
                self.error = error
                super.init(sender: sender)
        }
    }
    
    public class DidWriteValueForDescriptor : Message {
        public let peripheral: CBPeripheral
        public let descriptor: CBDescriptor
        public let error: NSError?
        
        public init(sender: Optional<ActorRef>,
            peripheral: CBPeripheral,
            descriptor: CBDescriptor,
            error: NSError?) {
                self.peripheral = peripheral
                self.descriptor = descriptor
                self.error = error
                super.init(sender: sender)
        }
    }
}