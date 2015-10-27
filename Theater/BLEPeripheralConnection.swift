//
//  BLEPeripheralConnection.swift
//  Actors
//
//  Created by Dario Lencina on 10/26/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import CoreBluetooth

public extension BLEPeripheralConnection {
    
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
    
    public class DidDiscoverCharacteristicsForService : DidDiscoverIncludedServicesForService {}
    
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
    
    public class DidWriteValueForCharacteristic : DidUpdateValueForCharacteristic {}
    
    public class DidUpdateNotificationStateForCharacteristic : DidUpdateValueForCharacteristic {}
    
    public class DidDiscoverDescriptorsForCharacteristic : DidUpdateValueForCharacteristic {}
    
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

public class BLEPeripheralConnection : Actor, WithListeners, CBPeripheralDelegate {
    
    public var listeners : [ActorRef] = [ActorRef]()
    
    override public func receive(msg: Message) {
        switch(msg) {
            case is PeripheralDidUpdateName:
                self.broadcast(msg)
            
            case is DidModifyServices:
                self.broadcast(msg)
                    
            case is DidReadRSSI:
                self.broadcast(msg)
                    
            case is DidDiscoverServices:
               self.broadcast(msg)
            
            case is DidDiscoverIncludedServicesForService:
                self.broadcast(msg)
                    
            case is DidDiscoverCharacteristicsForService:
                self.broadcast(msg)
                    
            case is DidUpdateValueForCharacteristic:
                self.broadcast(msg)
                    
            case is DidWriteValueForCharacteristic:
                self.broadcast(msg)
            
            case is DidUpdateNotificationStateForCharacteristic:
                self.broadcast(msg)
            
            case is DidDiscoverDescriptorsForCharacteristic:
                self.broadcast(msg)
            
            case is DidUpdateValueForDescriptor:
                self.broadcast(msg)
            
            case is DidWriteValueForDescriptor:
                self.broadcast(msg)
            
            default:
                super.receive(msg)
        }
    }
    
    public func peripheralDidUpdateName(peripheral: CBPeripheral){
        this ! PeripheralDidUpdateName(sender: this, peripheral: peripheral)
    }

    /*!
    *  @method peripheral:didModifyServices:
    *
    *  @param peripheral			The peripheral providing this update.
    *  @param invalidatedServices	The services that have been invalidated
    *
    *  @discussion			This method is invoked when the @link services @/link of <i>peripheral</i> have been changed.
    *						At this point, the designated <code>CBService</code> objects have been invalidated.
    *						Services can be re-discovered via @link discoverServices: @/link.
    */
    public func peripheral(peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]){
        this ! DidModifyServices(sender: this, peripheral: peripheral, invalidatedServices: invalidatedServices)
    }
    
    /*!
    *  @method peripheral:didReadRSSI:error:
    *
    *  @param peripheral	The peripheral providing this update.
    *  @param RSSI			The current RSSI of the link.
    *  @param error		If an error occurred, the cause of the failure.
    *
    *  @discussion			This method returns the result of a @link readRSSI: @/link call.
    */
    public func peripheral(peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: NSError?){
        this ! DidReadRSSI(sender: this, peripheral: peripheral, error: error, RSSI: RSSI)
    }
    
    /*!
    *  @method peripheral:didDiscoverServices:
    *
    *  @param peripheral	The peripheral providing this information.
    *	@param error		If an error occurred, the cause of the failure.
    *
    *  @discussion			This method returns the result of a @link discoverServices: @/link call. If the service(s) were read successfully, they can be retrieved via
    *						<i>peripheral</i>'s @link services @/link property.
    *
    */
    public func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?){
        this ! DidDiscoverServices(sender: this, peripheral: peripheral, error: error)
    }
    
    /*!
    *  @method peripheral:didDiscoverIncludedServicesForService:error:
    *
    *  @param peripheral	The peripheral providing this information.
    *  @param service		The <code>CBService</code> object containing the included services.
    *	@param error		If an error occurred, the cause of the failure.
    *
    *  @discussion			This method returns the result of a @link discoverIncludedServices:forService: @/link call. If the included service(s) were read successfully,
    *						they can be retrieved via <i>service</i>'s <code>includedServices</code> property.
    */
    public func peripheral(peripheral: CBPeripheral, didDiscoverIncludedServicesForService service: CBService, error: NSError?){
        this ! DidDiscoverIncludedServicesForService(sender: this, peripheral: peripheral, service: service, error: error)
    }
    
    /*!
    *  @method peripheral:didDiscoverCharacteristicsForService:error:
    *
    *  @param peripheral	The peripheral providing this information.
    *  @param service		The <code>CBService</code> object containing the characteristic(s).
    *	@param error		If an error occurred, the cause of the failure.
    *
    *  @discussion			This method returns the result of a @link discoverCharacteristics:forService: @/link call. If the characteristic(s) were read successfully,
    *						they can be retrieved via <i>service</i>'s <code>characteristics</code> property.
    */
    public func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?){
        this ! DidDiscoverCharacteristicsForService(sender: this, peripheral: peripheral, service: service, error: error)
    }
    
    /*!
    *  @method peripheral:didUpdateValueForCharacteristic:error:
    *
    *  @param peripheral		The peripheral providing this information.
    *  @param characteristic	A <code>CBCharacteristic</code> object.
    *	@param error			If an error occurred, the cause of the failure.
    *
    *  @discussion				This method is invoked after a @link readValueForCharacteristic: @/link call, or upon receipt of a notification/indication.
    */
    public func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?){
        this ! DidUpdateValueForCharacteristic(sender: this, peripheral: peripheral, characteristic: characteristic, error: error)
    }
    
    /*!
    *  @method peripheral:didWriteValueForCharacteristic:error:
    *
    *  @param peripheral		The peripheral providing this information.
    *  @param characteristic	A <code>CBCharacteristic</code> object.
    *	@param error			If an error occurred, the cause of the failure.
    *
    *  @discussion				This method returns the result of a {@link writeValue:forCharacteristic:type:} call, when the <code>CBCharacteristicWriteWithResponse</code> type is used.
    */
    public func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?){
        this ! DidWriteValueForCharacteristic(sender: this, peripheral: peripheral, characteristic: characteristic, error: error)
    }
    
    /*!
    *  @method peripheral:didUpdateNotificationStateForCharacteristic:error:
    *
    *  @param peripheral		The peripheral providing this information.
    *  @param characteristic	A <code>CBCharacteristic</code> object.
    *	@param error			If an error occurred, the cause of the failure.
    *
    *  @discussion				This method returns the result of a @link setNotifyValue:forCharacteristic: @/link call.
    */
    
    public func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?){
        this ! DidUpdateNotificationStateForCharacteristic(sender: this, peripheral: peripheral, characteristic: characteristic, error: error)
    }
    
    /*!
    *  @method peripheral:didDiscoverDescriptorsForCharacteristic:error:
    *
    *  @param peripheral		The peripheral providing this information.
    *  @param characteristic	A <code>CBCharacteristic</code> object.
    *	@param error			If an error occurred, the cause of the failure.
    *
    *  @discussion				This method returns the result of a @link discoverDescriptorsForCharacteristic: @/link call. If the descriptors were read successfully,
    *							they can be retrieved via <i>characteristic</i>'s <code>descriptors</code> property.
    */
    
    public func peripheral(peripheral: CBPeripheral, didDiscoverDescriptorsForCharacteristic characteristic: CBCharacteristic, error: NSError?){
        this ! DidDiscoverDescriptorsForCharacteristic(sender: this, peripheral: peripheral, characteristic: characteristic, error: error)
    }
    
    /*!
    *  @method peripheral:didUpdateValueForDescriptor:error:
    *
    *  @param peripheral		The peripheral providing this information.
    *  @param descriptor		A <code>CBDescriptor</code> object.
    *	@param error			If an error occurred, the cause of the failure.
    *
    *  @discussion				This method returns the result of a @link readValueForDescriptor: @/link call.
    */

    public func peripheral(peripheral: CBPeripheral, didUpdateValueForDescriptor descriptor: CBDescriptor, error: NSError?){
        this ! DidUpdateValueForDescriptor(sender: this, peripheral: peripheral, descriptor: descriptor, error: error)
    }
    
    /*!
    *  @method peripheral:didWriteValueForDescriptor:error:
    *
    *  @param peripheral		The peripheral providing this information.
    *  @param descriptor		A <code>CBDescriptor</code> object.
    *	@param error			If an error occurred, the cause of the failure.
    *
    *  @discussion				This method returns the result of a @link writeValue:forDescriptor: @/link call.
    */
    
    public func peripheral(peripheral: CBPeripheral, didWriteValueForDescriptor descriptor: CBDescriptor, error: NSError?){
        this ! DidWriteValueForDescriptor(sender: this, peripheral: peripheral, descriptor: descriptor, error: error)
    }
    
}