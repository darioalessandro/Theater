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
        public let devices : [String : [BLEPeripheral]]
        
        init(sender : Optional<ActorRef>, devices : [String : [BLEPeripheral]]) {
            self.devices = devices
            super.init(sender: sender)
        }
    }
    
}