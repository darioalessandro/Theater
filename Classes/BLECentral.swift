//
//  BLECentral.swift
//  Actors
//
//  Created by Dario Lencina on 9/27/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import CoreBluetooth



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

/**
BLECentral related messages
*/

public class BLECentralMsg {
    
/**
Use this message to tell BLECentral to start scanning, scanning success depends on the status of the BLE hardware, BLECentral will message all it's listeners when it actually starts scanning an #BLECentralMsg.StateChanged when it actually starts scanning.
*/

    public class StartScanning : Message {
        public init() {
            super.init(sender: Optional.None)
        }
    }
    
/**
Use AddListener to subscribe to BLECentral events such as #BLECentralMsg.DevicesObservationUpdate.
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

/**
BLECentral is a wrapper for CBCentralManager which allows developers to interact with CoreBluetooth using actors as opposed to the callback oriented approach of Apple.
*/

public class BLECentral : Actor, CBCentralManagerDelegate {
    
    private struct States {
        let scanning : String = "scanning"
        let notScanning : String = "notScanning"
    }
    
    private let states = States()
    
    private let bleOptions = [CBCentralManagerScanOptionAllowDuplicatesKey : NSNumber(bool: true)]
    
    private var devices : [String : [BLEPeripheral]]
    
    private let bleQueue = NSOperationQueue.init()
    
    private let central : CBCentralManager
    
    private var shouldWait = false
    
    //TODO expose this variable
    
    private var threshold : Double = 5
    
    private var listeners : [ActorRef] = []
    
    private var shouldScan : Bool = false
    
    /**
    This is the constructor used by the ActorSystem, do not call it directly
    */
    
    public required init(context: ActorSystem, ref: ActorRef) {
        self.central = CBCentralManager.init(delegate: nil, queue: self.bleQueue.underlyingQueue)
        self.devices = [String : [BLEPeripheral]]()
        super.init(context: context, ref: ref)
        self.central.delegate = self
    }
    
    private func addListener(sender : Optional<ActorRef>) {
        guard let listener = sender else {
            print("no listener for event")
            return
        }

        if (listeners.contains({ actor -> Bool in
            return listener.path.asString == actor.path.asString}) == false) {
            listeners.append(listener)
        }
    }
    
    private func removeListener(sender : Optional<ActorRef>) {


        if let listener = sender,
            n = listeners.indexOf({ actor -> Bool in  return listener.path.asString == actor.path.asString}) {
            listeners.removeFirst(n)
        }
    }
    
    lazy private var scanning : Receive = {[unowned self] (msg : Message) in
            switch (msg) {
            case is BLECentralMsg.StartScanning:
                print("already scanning")
                break
            case is BLECentralMsg.StopScanning:
                self.shouldScan = false
                self.central.stopScan()
                print("stopped")
                self.become(self.states.notScanning, state: self.notScanning)
                break
            default:
                self.notScanning(msg)
            }
        }
    
    lazy private var notScanning : Receive = {[unowned self](msg : Message) in
        switch (msg) {
        case is BLECentralMsg.StartScanning:
            self.shouldScan = true
            self.shouldWait = false
            if self.central.state == CBCentralManagerState.PoweredOn {
                self.central.scanForPeripheralsWithServices(nil, options: self.bleOptions)
                print("Started")
                self.become(self.states.scanning, state: self.scanning)
            }
            break
        case is BLECentralMsg.StopScanning:
            print("not scanning")
            break
        case let m where msg is BLECentralMsg.RemoveListener:
            self.removeListener(m.sender)
            break
        case let m where msg is BLECentralMsg.AddListener:
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
        self.become(self.states.notScanning, state: self.notScanning)
        self.this ! msg
        
    }
    
    /**
    CBCentralManagerDelegate methods, BLECentral hides this methods so that messages can interact with BLE devices using actors
    */
    
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
            listener ! BLECentralMsg.StateChanged(sender: this, state: central.state)
        }
    }
    
    /**
    CBCentralManagerDelegate methods, BLECentral hides this methods so that messages can interact with BLE devices using actors
    */
    
    @objc public func centralManager(central: CBCentralManager, willRestoreState dict: [String : AnyObject]) {
        
    }
    
    /**
    CBCentralManagerDelegate methods, BLECentral hides this methods so that messages can interact with BLE devices using actors
    */
    
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
            listener ! BLECentralMsg.DevicesObservationUpdate(sender: this, devices: self.devices)
        }
    }
    
    /**
    CBCentralManagerDelegate methods, BLECentral hides this methods so that messages can interact with BLE devices using actors
    */
    
    @objc public func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        
    }
    
    /**
    CBCentralManagerDelegate methods, BLECentral hides this methods so that messages can interact with BLE devices using actors
    */
    
    @objc public func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        
    }
    
    /**
    CBCentralManagerDelegate methods, BLECentral hides this methods so that messages can interact with BLE devices using actors
    */

    @objc public func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        
    }
    
    deinit {
        self.central.delegate = nil
        print("called deinit in BLECentral \(this.path.asString)")
    }
    
}