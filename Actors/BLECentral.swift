//
//  BLECentral.swift
//  Actors
//
//  Created by Dario Lencina on 9/27/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import CoreBluetooth

public class StartScanning : Message {
    public init() {
        super.init(sender: Optional.None)
    }
}

public class BLEPeripheral {
    public let peripheral: CBPeripheral
    public let advertisementData: [String : AnyObject]
    public let RSSI: NSNumber
    public let timestamp : NSDate
    
    init(peripheral: CBPeripheral,advertisementData: [String : AnyObject],RSSI: NSNumber,timestamp : NSDate) {
        self.peripheral = peripheral
        self.advertisementData = advertisementData
        self.RSSI = RSSI
        self.timestamp = timestamp
    }
}

public class AddListener : Message {}

public class RemoveListener : Message {}

public class StopScanning : Message {}

public class StateChanged : Message {
    let state : CBCentralManagerState
    
    init(sender : ActorRef, state : CBCentralManagerState) {
        self.state = state
        super.init(sender: sender)
    }
}

public class DevicesObservationUpdate : Message {
    public let devices : [String : [BLEPeripheral]]
    
    init(sender : Optional<ActorRef>, devices : [String : [BLEPeripheral]]) {
        self.devices = devices
        super.init(sender: sender)
    }
}

public class BLECentral : Actor, CBCentralManagerDelegate {
    
    private var devices : [String : [BLEPeripheral]]
    
    private let bleQueue = NSOperationQueue.init()
    
    private let central : CBCentralManager
    
    public required init(context: ActorSystem, ref: ActorRef) {
        self.central = CBCentralManager.init(delegate: nil, queue: bleQueue.underlyingQueue)
        self.devices = [String : [BLEPeripheral]]()
        super.init(context: context, ref: ref)
        self.central.delegate = self
    }
    
    private var listeners : [ActorRef] = []
    
    private var shouldScan : Bool = false
    
    private func addListener(sender : Optional<ActorRef>) {
        guard let listener = sender else {
            print("no listener")
            return
        }

        if (listeners.contains({ actor -> Bool in  return listener.path.asString == actor.path.asString}) == false) {
            listeners.append(listener)
        }
    }
    
    private func removeListener(sender : Optional<ActorRef>) {
        guard let listener = sender else {
            print("no listener")
            return
        }

        if let n = listeners.indexOf({ actor -> Bool in  return listener.path.asString == actor.path.asString}) {
            listeners.removeFirst(n)
        }
    }
    
    override public func receive(msg: Message) {
        switch (msg) {
            case is StartScanning:
                shouldScan = true
                if self.central.state == CBCentralManagerState.PoweredOn {
                    self.central.scanForPeripheralsWithServices(nil, options: nil)
                    print("Started")
                }
                break;
            case is StopScanning:
                shouldScan = false
                self.central.stopScan()
                print("stopped")
                break;
            case is RemoveListener:
                let m = msg as! RemoveListener
                self.removeListener(m.sender)
                break;
            case is AddListener:
                let m = msg as! AddListener
                self.addListener(m.sender)
                break;
            default:
                super.receive(msg)
        }
    }
    
    @objc public func centralManagerDidUpdateState(central: CBCentralManager) {
        
        switch(central.state) {
        case .PoweredOn:
            if self.shouldScan {
                self.central.scanForPeripheralsWithServices(nil, options: nil)
            } else {
                self.central.stopScan()
            }
            
        default:
            print("doing nothing")
        }
        
        listeners.forEach { (listener) -> () in
            listener ! StateChanged(sender: this, state: central.state)
        }
    }
    
    @objc public func centralManager(central: CBCentralManager, willRestoreState dict: [String : AnyObject]) {
        
    }
    
    @objc public func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        let bleDevice = BLEPeripheral(peripheral: peripheral, advertisementData: advertisementData, RSSI: RSSI, timestamp: NSDate.init())
        if var historyOfDevice = self.devices[peripheral.identifier.UUIDString] {
            historyOfDevice.insert(bleDevice, atIndex: 0)
            self.devices[peripheral.identifier.UUIDString] = historyOfDevice
        } else {
            self.devices[peripheral.identifier.UUIDString] = [bleDevice]
        }
        
        listeners.forEach { (listener) -> () in
            listener ! DevicesObservationUpdate(sender: this, devices: self.devices)
        }
    }
    
    @objc public func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        
    }
    
    @objc public func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        
    }

    @objc public func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        
    }
    
}