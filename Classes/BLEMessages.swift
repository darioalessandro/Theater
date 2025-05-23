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
     Message used by BLECentral to encapsule a CBPeripheral advertisement packet
     */
    
    class BLEPeripheralObservation {
        
        public let peripheral: CBPeripheral
        public let advertisementData: [String : Any]
        public let RSSI: NSNumber
        public let timestamp : Date
        
        init(peripheral: CBPeripheral,advertisementData: [String : Any],RSSI: NSNumber,timestamp : Date) {
            self.peripheral = peripheral
            self.advertisementData = advertisementData
            self.RSSI = RSSI
            self.timestamp = timestamp
        }
    }
    
    typealias PeripheralObservations = [String : [BLEPeripheralObservation]]
    
    typealias PeripheralConnections = [UUID : ActorRef]    
    
    /**
    Namespace for Peripheral related messages
    */
    
    class Peripheral {
        /**
        Tries to connect to CBPeripheral
        */
        public class Connect : Actor.Message {
            public let peripheral : CBPeripheral
            
            public init(sender: ActorRef?, peripheral : CBPeripheral) {
                self.peripheral = peripheral
                super.init(sender: sender)
            }
        }
        
        /**
        Message sent from BLECentral to subscribers when it connects to peripheral
        */
        public class OnConnect : Actor.Message {
            
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
        
        public class OnDisconnect : Actor.Message {
            
            public let error : Error?
            
            public let peripheral : CBPeripheral
            
            public init(sender: ActorRef?, peripheral: CBPeripheral, error : Optional<Error>) {
                self.peripheral = peripheral
                self.error = error
                super.init(sender: sender)
            }
        }
        
        /**
        Actor.Message sent from BLECentral to force disconnecting peripheral
        */
        
        public class Disconnect : Actor.Message {
            public let peripheral : CBPeripheral
            
            public init(sender: ActorRef?, peripheral : CBPeripheral) {
                self.peripheral = peripheral
                super.init(sender: sender)
            }
        }
    }
    
    
    /**
    Use this message to tell BLECentral to start scanning, scanning success depends on the status of the BLE hardware, BLECentral will message all it's listeners when it actually starts scanning an BLECentral.StateChanged when it actually starts scanning.
    */
    
    class StartScanning : Actor.Message {
        
        public let services : Optional<[CBUUID]>
        
        public init(services : Optional<[CBUUID]>, sender : ActorRef?) {
            self.services = services
            super.init(sender: sender)
        }
    }
    
    /**
    Use AddListener to subscribe to BLECentral events such as @see BLECentralMsg#DevicesObservationUpdate.
    */
    
    class AddListener : Actor.Message {}
    
    /**
    Use RemoveListener to stop receiving BLECentral events such as #BLECentralMsg.DevicesObservationUpdate.
    */
    
    class RemoveListener : Actor.Message {}
    
    /**
    Tell BLECentral to stop scanning
    */
    
    class StopScanning : Actor.Message {}
    
    /**
    An StateChanged message will be sent to all #BLECentral.listeners when the underlying CBCentralManager changes it's state.
    */
    
    class StateChanged : Actor.Message {
        let state : CBManagerState
        
        init(sender : ActorRef, state : CBManagerState) {
            self.state = state
            super.init(sender: sender)
        }
    }
    
    /**
    DevicesObservationUpdate contains an immutable dictionary with all the devices that BLECentral saw and all the observations (#BLEPeripheral) since it was created, this is very useful when monitoring RSSI because it provides a time dimension, which is important to determine if the customer is moving towards the BLE device or away from it.
    */
    
    class DevicesObservationUpdate : Actor.Message {
        public let devices : [String : [BLEPeripheralObservation]]
        
        init(sender : ActorRef?, devices : [String : [BLEPeripheralObservation]]) {
            self.devices = devices
            super.init(sender: sender)
        }
    }
}

/**
This extension contains all the messages that BLEPeripheral produces
*/

public extension BLEPeripheral {
    
    typealias Subscriptions = [CBCentral : [CBCharacteristic]]
    
    /**
    BLEPeripheral broadcasts this message when a central subscribes or unsubscribes from CBCharacteristics
    */
    
    class SubscriptionsChanged : Actor.Message {
        let subscriptions : Subscriptions
        
        init(sender: ActorRef?, subscriptions : Subscriptions) {
            self.subscriptions = subscriptions
            super.init(sender: sender)
        }
    }
    
    /**
    Command used to signal BLEPeripheral to start advertising
    */
    
    class StartAdvertising : Actor.Message {
        public let advertisementData : [String : AnyObject]?
        
        public let svcs : [CBMutableService]
        
        public init(sender: ActorRef?, advertisementData : [String : AnyObject]?, svcs : [CBMutableService]) {
            self.svcs = svcs
            self.advertisementData = advertisementData
            super.init(sender: sender)
        }
    }
    
    /**
     Command used to signal BLEPeripheral to stop advertising
     */
    
    class StopAdvertising : Actor.Message {}
    
    /**
     Actor.Message broadcasted by BLEPeripheral when it starts advertising
    */
    
    class DidStartAdvertising : Actor.Message {
        public let svcs : [CBService]
        
        public init(sender: ActorRef?, svcs : [CBService]) {
            self.svcs = svcs
            super.init(sender: sender)
        }
    }
    
    /**
     Actor.Message broadcasted by BLEPeripheral when it stops advertising
     */
    
    class DidStopAdvertising : Actor.Message {}
    
    /**
     Message broadcasted by BLEPeripheral when it fails to start advertising
     */
    
    class FailedToStartAdvertising : Actor.Message {
        public let error : Error
        init(sender : ActorRef?, error : Error) {
            self.error = error
            super.init(sender: sender)
        }
    }
    
    /**
    Message broadcasted when a central subscribes to a characteristic
    */
    
    class CentralDidSubscribeToCharacteristic : Actor.Message {
        public let central: CBCentral
        public let characteristic: CBCharacteristic
        
        public init(sender: ActorRef?, central : CBCentral, characteristic : CBCharacteristic) {
            self.central = central
            self.characteristic = characteristic
            super.init(sender: sender)
        }
    }
    
    /**
     Message broadcasted when a central unsubscribes to a characteristic
     */
    
    class CentralDidUnsubscribeFromCharacteristic : Actor.Message {
        public let central: CBCentral
        public let characteristic: CBCharacteristic
        
        public init(sender: ActorRef?, central : CBCentral, characteristic : CBCharacteristic) {
            self.central = central
            self.characteristic = characteristic
            super.init(sender: sender)
        }

    }
    
    /**
     Message broadcasted when BLEPeripheral receives a read request, user is responsible for responding using RespondToRequest
     */
    
    class DidReceiveReadRequest : Actor.Message {
        public let request: CBATTRequest
        public init(sender: ActorRef?, request : CBATTRequest) {
            self.request = request
            super.init(sender: sender)
        }
    }
    
    /**
     Message used by the user to signal BLEPeripheral to respond to the CBATTRequest
     */
    
    class RespondToRequest : Actor.Message {
        public let result : CBATTError.Code
        public let request: CBATTRequest
        
        public init(sender: ActorRef?, request : CBATTRequest, result : CBATTError.Code) {
            self.result = result
            self.request = request
            super.init(sender: sender)
        }
        
    }
    
    class DidAddService : Actor.Message {
        public let svc : CBService
        
        public init(svc : CBService, sender: ActorRef?) {
            self.svc = svc
            super.init(sender: sender)
        }
    }
    
    /**
     Message broadcasted when BLEPeripheral receives a write request, user is responsible for responding
     */
    
    class DidReceiveWriteRequests : Actor.Message {
        public let requests: [CBATTRequest]
        
        public init(sender: ActorRef?, requests : [CBATTRequest]) {
            self.requests = requests
            super.init(sender: sender)
        }
    }
    
    /**
     Message broadcasted when BLEPeripheral changes it CBManagerState
    */
    
    class PeripheralManagerDidUpdateState : Actor.Message {
        
        public let state : CBManagerState
        
        public init(sender: ActorRef?, state : CBManagerState) {
            self.state = state
            super.init(sender: sender)
        }
    }
    
    /**
     Command to signal BLEPeripheral to remove a CBMutableService from it's GATT
     */
    
    class RemoveServices : Actor.Message {
        public let svcs : [CBMutableService]
        
        public init(sender: ActorRef?, svcs : [CBMutableService]) {
            self.svcs = svcs
            super.init(sender: sender)
        }
    }
    
    /**
     Remove all Services
    **/
     
    class RemoveAllServices : Actor.Message {}
    
    /**
     Set all services
    **/
     
    class SetServices : Actor.Message {
        public let svcs : [CBMutableService]
        
        public init(sender: ActorRef?, svcs : [CBMutableService]) {
            self.svcs = svcs
            super.init(sender: sender)
        }
    }
    
    /**
     Command to signal BLEPeripheral to update the value of a CBMutableCharacteristic in the given centrals
     */
    
    class UpdateCharacteristicValue : Actor.Message {
        public let char : CBMutableCharacteristic
        public let centrals : [CBCentral]?
        public let value : Data
        
        public init(sender: ActorRef?,
            char : CBMutableCharacteristic,
            centrals : [CBCentral]?,
            value : Data) {
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
    
    class AddListener : Actor.Message {}
    
    class SetPeripheral : Actor.Message {
        public let peripheral : CBPeripheral
        
        public init(sender: ActorRef?, peripheral : CBPeripheral) {
            self.peripheral = peripheral
            super.init(sender: sender)
        }
    }
    
    /**
        PeripheralDidUpdateName
    */
    
    class PeripheralDidUpdateName : Actor.Message {
        
        public let peripheral : CBPeripheral
        
        public init(sender: ActorRef?, peripheral : CBPeripheral) {
            self.peripheral = peripheral
            super.init(sender: sender)
        }
    }
    
    /**
     DidModifyServices
     */
    
    class DidModifyServices : Actor.Message {
        
        public let peripheral : CBPeripheral
        
        public let invalidatedServices : [CBService]
        
        public init(sender: ActorRef?, peripheral : CBPeripheral, invalidatedServices:[CBService]) {
            self.peripheral = peripheral
            self.invalidatedServices = invalidatedServices
            super.init(sender: sender)
        }
    }
    
    /**
     DidReadRSSI
     */
    
    class DidReadRSSI : Actor.Message {
        
        public let peripheral : CBPeripheral
        
        public let error : Error?
        
        public let RSSI : NSNumber
        
        public init(sender: ActorRef?,
            peripheral : CBPeripheral,
            error : Error?,
            RSSI : NSNumber) {
                self.error = error
                self.RSSI = RSSI
                self.peripheral = peripheral
                super.init(sender: sender)
        }
    }
    
    /**
    DidDiscoverNoServices
    */
     
    class DidDiscoverNoServices : Actor.Message {
        
        public let peripheral : CBPeripheral
        
        public let error : Error?
        
        public init(sender: ActorRef?,
            peripheral : CBPeripheral,
            error : Error?) {
                self.error = error
                self.peripheral = peripheral
                super.init(sender: sender)
        }
    }
    
    /**
     DidDiscoverServices
     */
    
    class DidDiscoverServices : Actor.Message {
        
        public let peripheral : CBPeripheral
        
        public let error : Error?
        
        public init(sender: ActorRef?,
            peripheral : CBPeripheral,
            error : Error?) {
                self.error = error
                self.peripheral = peripheral
                super.init(sender: sender)
        }
    }
    
    /**
     DiscoverServices
     */
    
    class DiscoverServices : Actor.Message {
        public let services : [CBUUID]
        
        public init(sender: ActorRef?,
            services : [CBUUID]) {
                self.services = services
                super.init(sender: sender)
        }
    }
    
    /**
     DidDiscoverIncludedServicesForService
     */
    
    class DidDiscoverIncludedServicesForService : Actor.Message {
        
        public let peripheral : CBPeripheral
        
        public let error : Error?
        
        public let service: CBService
        
        public init(sender: ActorRef?,
            peripheral : CBPeripheral,
            service : CBService,
            error : Error?) {
                self.service = service
                self.error = error
                self.peripheral = peripheral
                super.init(sender: sender)
        }
    }
    
    /**
     DidDiscoverCharacteristicsForService
     */
    
    class DidDiscoverCharacteristicsForService : Actor.Message {
        public let peripheral : CBPeripheral
        
        public let error : Error?
        
        public let service: CBService
        
        public init(sender: ActorRef?,
            peripheral : CBPeripheral,
            service : CBService,
            error : Error?) {
                self.service = service
                self.error = error
                self.peripheral = peripheral
                super.init(sender: sender)
        }
    }
    
    /**
     DidUpdateValueForCharacteristic
     */
    
    class DidUpdateValueForCharacteristic : Actor.Message {
        
        public let peripheral : CBPeripheral
        
        public let error : Error?
        
        public let characteristic: CBCharacteristic
        
        public init(sender: ActorRef?,
            peripheral : CBPeripheral,
            characteristic: CBCharacteristic,
            error : Error?) {
                self.characteristic = characteristic
                self.error = error
                self.peripheral = peripheral
                super.init(sender: sender)
        }
    }
    
    /**
     DidWriteValueForCharacteristic
     */
    
    class DidWriteValueForCharacteristic : Actor.Message {
        public let peripheral : CBPeripheral
        
        public let error : Error?
        
        public let characteristic: CBCharacteristic
        
        public init(sender: ActorRef?,
            peripheral : CBPeripheral,
            characteristic: CBCharacteristic,
            error : Error?) {
                self.characteristic = characteristic
                self.error = error
                self.peripheral = peripheral
                super.init(sender: sender)
        }
    }
    
    /**
     DidUpdateNotificationStateForCharacteristic
     */
    
    class DidUpdateNotificationStateForCharacteristic : Actor.Message {
        public let peripheral : CBPeripheral
        
        public let error : Error?
        
        public let characteristic: CBCharacteristic
        
        public init(sender: ActorRef?,
            peripheral : CBPeripheral,
            characteristic: CBCharacteristic,
            error : Error?) {
                self.characteristic = characteristic
                self.error = error
                self.peripheral = peripheral
                super.init(sender: sender)
        }
    }
    
    /**
     DidDiscoverDescriptorsForCharacteristic
     */
    
    class DidDiscoverDescriptorsForCharacteristic : Actor.Message {
        public let peripheral : CBPeripheral
        
        public let error : Error?
        
        public let characteristic: CBCharacteristic
        
        public init(sender: ActorRef?,
            peripheral : CBPeripheral,
            characteristic: CBCharacteristic,
            error : Error?) {
                self.characteristic = characteristic
                self.error = error
                self.peripheral = peripheral
                super.init(sender: sender)
        }
    }
    
    /**
     DidUpdateValueForDescriptor
     */
    
    class DidUpdateValueForDescriptor : Actor.Message {
        public let peripheral: CBPeripheral
        public let descriptor: CBDescriptor
        public let error: Error?
        
        public init(sender: ActorRef?,
            peripheral: CBPeripheral,
            descriptor: CBDescriptor,
            error: Error?) {
                self.peripheral = peripheral
                self.descriptor = descriptor
                self.error = error
                super.init(sender: sender)
        }
    }
    
    /**
     DidWriteValueForDescriptor
     */
    
    class DidWriteValueForDescriptor : Actor.Message {
        public let peripheral: CBPeripheral
        public let descriptor: CBDescriptor
        public let error: Error?
        
        public init(sender: ActorRef?,
            peripheral: CBPeripheral,
            descriptor: CBDescriptor,
            error: Error?) {
                self.peripheral = peripheral
                self.descriptor = descriptor
                self.error = error
                super.init(sender: sender)
        }
    }
}
