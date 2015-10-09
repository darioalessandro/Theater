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
    
    private let bleOptions = [CBCentralManagerScanOptionAllowDuplicatesKey : NSNumber(bool: true)]
    
    private var devices : [String : [BLEPeripheral]]
    
    private let bleQueue = NSOperationQueue.init()
    
    private let central : CBCentralManager
    
    private var shouldWait = false
    
    private var threshold : Double = 5
    
    private var listeners : [ActorRef] = []
    
    private var shouldScan : Bool = false
    
    public required init(context: ActorSystem, ref: ActorRef) {
        self.central = CBCentralManager.init(delegate: nil, queue: self.bleQueue.underlyingQueue)
        self.devices = [String : [BLEPeripheral]]()
        super.init(context: context, ref: ref)
        self.central.delegate = self
    }
    
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
    
    lazy var scanning : Receive = {[unowned self] (msg : Message) in
            switch (msg) {
            case is StartScanning:
                print("already scanning")
                break
            case is StopScanning:
                self.shouldScan = false
                self.central.stopScan()
                print("stopped")
                self.become("notscanning", state: self.notScanning)
                break
            default:
                self.notScanning(msg)
            }
        }
    
    lazy var notScanning : Receive = {[unowned self](msg : Message) in
        switch (msg) {
        case is StartScanning:
            self.shouldScan = true
            self.shouldWait = false
            if self.central.state == CBCentralManagerState.PoweredOn {
                self.central.scanForPeripheralsWithServices(nil, options: self.bleOptions)
                print("Started")
                self.become("scanning", state: self.scanning)
            }
            break
        case is StopScanning:
            print("not scanning")
            break
        case let m where msg is RemoveListener:
            self.removeListener(m.sender)
            break
        case let m where msg is AddListener:
            self.addListener(m.sender)
            break
        case is Harakiri:
            self.context.stop(self.this)
            break
        default:
            print("not handled")
        }
    }
    
    override public func receive(msg : Message) -> Void {
        self.become("notscanning", state: self.notScanning)
        self.this ! msg
        
    }
    
    @objc public func centralManagerDidUpdateState(central: CBCentralManager) {
        
        switch(central.state) {
        case .PoweredOn:
            if self.shouldScan {
                self.central.scanForPeripheralsWithServices(nil, options: bleOptions)
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
        if var historyOfDevice = self.devices[peripheral.identifier.UUIDString], let lastObv = historyOfDevice.first {
            let areRSSIDifferent = abs(lastObv.RSSI.doubleValue - bleDevice.RSSI.doubleValue) > 20
            let isThereEnoughTimeBetweenSamples = Double(bleDevice.timestamp.timeIntervalSinceDate(lastObv.timestamp)) > threshold
            if  areRSSIDifferent || isThereEnoughTimeBetweenSamples {
                historyOfDevice.insert(bleDevice, atIndex: 0)
                self.devices[peripheral.identifier.UUIDString] = historyOfDevice
            }
        } else {
            self.devices[peripheral.identifier.UUIDString] = [bleDevice]
        }
        
        if shouldWait { return }
        
        shouldWait = true
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
            self.shouldWait = false
        })
        
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
    
    deinit {
        self.central.delegate = nil
        print("called deinit in BLECentral \(this.path.asString)")
    }
    
}