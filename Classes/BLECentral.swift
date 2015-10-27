//
//  BLECentral.swift
//  Actors
//
//  Created by Dario Lencina on 9/27/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import CoreBluetooth


/**
BLECentral is a wrapper for CBCentralManager which allows developers to interact with CoreBluetooth using actors as opposed to the callback oriented approach of Apple.
*/

public class BLECentral : Actor, CBCentralManagerDelegate, WithListeners {
    
    private struct States {
        let scanning : String = "scanning"
        let notScanning : String = "notScanning"
        let connecting = "connecting"
        let connected = "connected"
    }
    
    private let states = States()
    
    private let bleOptions = [CBCentralManagerScanOptionAllowDuplicatesKey : NSNumber(bool: true)]
    
    private var devices : [String : [BLEPeripheralObservation]] = [String : [BLEPeripheralObservation]]()
    
    private let bleQueue = NSOperationQueue.init()
    
    private let central : CBCentralManager
    
    private var shouldWait = false
    
    //TODO expose this variable
    
    private var threshold : Double = 5
    
    public var listeners : [ActorRef] = []
    
    private var shouldScan : Bool = false
    
    /**
    This is the constructor used by the ActorSystem, do not call it directly
    */
    
    public required init(context: ActorSystem, ref: ActorRef) {
        self.central = CBCentralManager.init(delegate: nil, queue: self.bleQueue.underlyingQueue)
        super.init(context: context, ref: ref)
        self.central.delegate = self
    }
    
    private func connected(peripheral : CBPeripheral) -> Receive {
        return {[unowned self](msg : Message) in
            switch(msg) {
                case let m as Peripheral.OnDisconnect:
                    self.broadcast(m)
                    self.popToState(self.states.notScanning)
                    
                case let m as Peripheral.Disconnect:
                    self.central.cancelPeripheralConnection(m.peripheral)
                    
                default:
                    print("ignoring")
            }
        }
    }
    
    private func connecting(peripheral : CBPeripheral) -> Receive {

        self.central.connectPeripheral(peripheral, options: [CBConnectPeripheralOptionNotifyOnConnectionKey : true,
            CBConnectPeripheralOptionNotifyOnDisconnectionKey : true,
            CBConnectPeripheralOptionNotifyOnNotificationKey : true])
        
        return {[unowned self](msg : Message) in
            switch(msg) {
                case let m as Peripheral.OnConnect:
                    self.become(self.states.connected, state: self.connected(m.peripheral))
                    self.broadcast(m)
                
                case let m as Peripheral.OnDisconnect:
                    self.broadcast(m)
                    self.popToState(self.states.notScanning)
                
                default:
                    print("ignoring")
            }
        }
    }
    
    private func scanning(services : Optional<[CBUUID]>) -> Receive {
        self.shouldWait = false
        
        return {[unowned self] (msg : Message) in
            switch (msg) {
                case is StateChanged:
                    if self.central.state == CBCentralManagerState.PoweredOn {
                        self.this ! StartScanning(services: services, sender: self.this)
                    }
                
                case is StartScanning:
                    if let services = services {
                        self.central.scanForPeripheralsWithServices(services, options: self.bleOptions)
                    } else {
                        self.central.scanForPeripheralsWithServices(nil, options: self.bleOptions)
                    }
                    print("Started")
                
                case is StopScanning:
                    self.shouldScan = false
                    self.central.stopScan()
                    print("stopped")
                    self.become(self.states.notScanning, state: self.notScanning)
                    
                case let m as Peripheral.Connect:
                    self.unbecome()
                    self.become(self.states.connecting, state: self.connecting(m.peripheral))
                    
                default:
                    self.notScanning(msg)
            }
        }
    }
    
    lazy private var notScanning : Receive = {[unowned self](msg : Message) in
        switch (msg) {
            case let m as Peripheral.Connect:
                self.become(self.states.connecting, state: self.connecting(m.peripheral))
                
            case let m as StartScanning:
                self.become(self.states.scanning, state: self.scanning(m.services))

            case is StopScanning:
                print("not scanning")

            case let m as RemoveListener:
                self.removeListener(m.sender)

            case let m as AddListener:
                self.addListener(m.sender)

            case is Harakiri:
                self.context.stop(self.this)

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
        
        let stateChanged = StateChanged(sender: this, state: central.state)
        
        this ! stateChanged
        
        listeners.forEach { (listener) in listener ! stateChanged }
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
        
        let bleDevice = BLEPeripheralObservation(peripheral: peripheral, advertisementData: advertisementData, RSSI: RSSI, timestamp: NSDate.init())
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
        
        self.scheduleOnce(1,block: { () in
            self.shouldWait = false
        })
        
        listeners.forEach { (listener) -> () in
            listener ! DevicesObservationUpdate(sender: this, devices: self.devices)
        }
    }
    
    /**
    CBCentralManagerDelegate methods, BLECentral hides this methods so that messages can interact with BLE devices using actors
    */
    
    @objc public func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        this ! Peripheral.OnConnect(sender: this, peripheral: peripheral)
    }
    
    /**
    CBCentralManagerDelegate methods, BLECentral hides this methods so that messages can interact with BLE devices using actors
    */
    
    @objc public func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        this ! Peripheral.OnDisconnect(sender: this, peripheral: peripheral, error: error)
    }
    
    /**
    CBCentralManagerDelegate methods, BLECentral hides this methods so that messages can interact with BLE devices using actors
    */

    @objc public func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        this ! Peripheral.OnDisconnect(sender: this, peripheral: peripheral, error: error)
    }
    
    deinit {
        self.central.delegate = nil
        print("called deinit in BLECentral \(this.path.asString)")
    }
    
}