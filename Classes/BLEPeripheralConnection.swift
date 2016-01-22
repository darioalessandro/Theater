//
//  BLEPeripheralConnection.swift
//  Actors
//
//  Created by Dario Lencina on 10/26/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import CoreBluetooth

/**
    BLECentral returns a BLEPeripheralConnection OnConnect, the idea is to simplify and provide a more organized
     way to interact with CBPeripherals
*/

public class BLEPeripheralConnection : Actor, WithListeners, CBPeripheralDelegate {
    
    /**
     
    Actors that care about this peripheral connection
    
     */
    
    public var listeners : [ActorRef] = [ActorRef]()
    
    func connected(peripheral : CBPeripheral) -> Receive {
        peripheral.delegate = self
        return { [unowned self] (msg : Actor.Message) in
        switch(msg) {
            
            case let m as DiscoverServices:
                peripheral.discoverServices(m.services)
            
            case is AddListener:
                self.addListener(msg.sender)
            
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
                print("ignored")
        }
        }
    }
    
    /**
    
    This is the message handler when there's no peripheral
     
     - parameter msg : incoming message
     
    */
    
    override public func receive(msg: Actor.Message) {
        switch(msg) {
            
            case let p as SetPeripheral:
                self.become("connected", state: self.connected(p.peripheral))
            
            default:
                super.receive(msg)
        }
    }
    
    /**
    CBPeripheralDelegate forwarded message, this method is exposed through an Actor.Message subclass
    */
    
    public func peripheralDidUpdateName(peripheral: CBPeripheral){
        this ! PeripheralDidUpdateName(sender: this, peripheral: peripheral)
    }

    /**
     CBPeripheralDelegate forwarded message, this method is exposed through an Actor.Message subclass
     */
    
    public func peripheral(peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]){
        this ! DidModifyServices(sender: this, peripheral: peripheral, invalidatedServices: invalidatedServices)
    }
    
    /**
     CBPeripheralDelegate forwarded message, this method is exposed through an Actor.Message subclass
     */
    
    public func peripheral(peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: NSError?){
        this ! DidReadRSSI(sender: this, peripheral: peripheral, error: error, RSSI: RSSI)
    }
    
    /**
     CBPeripheralDelegate forwarded message, this method is exposed through an Actor.Message subclass
     */
    
    public func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?){
        if let svcs = peripheral.services {
            if svcs.count > 0  {
                peripheral.services?.forEach {
                    print("didDiscoverServices \($0.UUID)")
                }
                
                peripheral.services?.forEach({ (service : CBService) in
                    peripheral.discoverCharacteristics(nil, forService: service)
                })
                this ! DidDiscoverServices(sender: this, peripheral: peripheral, error: error)
            } else {
                this ! DidDiscoverNoServices(sender: this, peripheral: peripheral, error: error)
            }
        } else {
            this ! DidDiscoverNoServices(sender: this, peripheral: peripheral, error: error)
        }
    }
    
    /**
     CBPeripheralDelegate forwarded message, this method is exposed through an Actor.Message subclass
     */
    
    public func peripheral(peripheral: CBPeripheral, didDiscoverIncludedServicesForService service: CBService, error: NSError?){
        this ! DidDiscoverIncludedServicesForService(sender: this, peripheral: peripheral, service: service, error: error)
    }
    
    /**
     CBPeripheralDelegate forwarded message, this method is exposed through an Actor.Message subclass
     */
    
    public func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?){
        this ! DidDiscoverCharacteristicsForService(sender: this, peripheral: peripheral, service: service, error: error)
    }
    
    /**
     CBPeripheralDelegate forwarded message, this method is exposed through an Actor.Message subclass
     */
    
    public func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?){
        this ! DidUpdateValueForCharacteristic(sender: this, peripheral: peripheral, characteristic: characteristic, error: error)
    }
    
    /**
     CBPeripheralDelegate forwarded message, this method is exposed through an Actor.Message subclass
     */
    
    public func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?){
        this ! DidWriteValueForCharacteristic(sender: this, peripheral: peripheral, characteristic: characteristic, error: error)
    }
    
    /**
     CBPeripheralDelegate forwarded message, this method is exposed through an Actor.Message subclass
     */
    
    public func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?){
        this ! DidUpdateNotificationStateForCharacteristic(sender: this, peripheral: peripheral, characteristic: characteristic, error: error)
    }
    
    /**
     CBPeripheralDelegate forwarded message, this method is exposed through an Actor.Message subclass
     */
    
    public func peripheral(peripheral: CBPeripheral, didDiscoverDescriptorsForCharacteristic characteristic: CBCharacteristic, error: NSError?){
        this ! DidDiscoverDescriptorsForCharacteristic(sender: this, peripheral: peripheral, characteristic: characteristic, error: error)
    }
    
    /**
     CBPeripheralDelegate forwarded message, this method is exposed through an Actor.Message subclass
     */

    public func peripheral(peripheral: CBPeripheral, didUpdateValueForDescriptor descriptor: CBDescriptor, error: NSError?){
        this ! DidUpdateValueForDescriptor(sender: this, peripheral: peripheral, descriptor: descriptor, error: error)
    }
    
    /**
     CBPeripheralDelegate forwarded message, this method is exposed through an Actor.Message subclass
     */
    
    public func peripheral(peripheral: CBPeripheral, didWriteValueForDescriptor descriptor: CBDescriptor, error: NSError?){
        this ! DidWriteValueForDescriptor(sender: this, peripheral: peripheral, descriptor: descriptor, error: error)
    }
    
    deinit {
        print("bye")
    }
    
}