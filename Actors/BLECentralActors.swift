//
//  BLEActors.swift
//  Actors
//
//  Created by Dario Lencina on 9/29/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import UIKit
import Theater
import CoreBluetooth
import AudioToolbox

public class BLEControllersActor : Actor, UITableViewDataSource, UITableViewDelegate, CBPeripheralDelegate {
    
    public struct States {
        let connected = "connected"
    }
    
    let states = States()
    
    var devices : BLECentral.PeripheralObservations = BLECentral.PeripheralObservations()
    var identifiers : [String] = [String]()
    weak var ctrl : Optional<UITableViewController> = Optional.None
    weak var deviceViewCtrl : Optional<DeviceViewController> = Optional.None
    weak var observationsCtrl : Optional<UITableViewController> = Optional.None
    var selectedIdentifier : Optional<String> = Optional.None
    let central : ActorRef
    
    required public init(context : ActorSystem, ref : ActorRef) {
        self.central = context.actorOf(BLECentral)
        super.init(context: context, ref: ref)
        self.central ! BLECentral.AddListener(sender: this)
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let deviceViewCtrl = self.deviceViewCtrl {
            if tableView.isEqual(deviceViewCtrl.tableView) {
                return deviceViewCtrl.tableView(tableView, numberOfRowsInSection:section)
            }
        }
        
        if let obsCtrl = self.observationsCtrl,
            selectedId = self.selectedIdentifier,
            observations = self.devices[selectedId] {
                
                if tableView.isEqual(obsCtrl.tableView) {
                    return observations.count
                }
        }
        return self.identifiers.count
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if let obsCtrl = self.observationsCtrl,
            _ = self.selectedIdentifier {
                if tableView.isEqual(obsCtrl.tableView) {
                    return
                }
        }
        
        self.selectedIdentifier = identifiers[indexPath.row]
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let deviceViewCtrl = self.deviceViewCtrl {
            if tableView.isEqual(deviceViewCtrl.tableView) {
                return deviceViewCtrl.tableView(tableView, cellForRowAtIndexPath:indexPath)
            }
        }
            
        let cell = tableView.dequeueReusableCellWithIdentifier("device")!
        
        if let obsCtrl = self.observationsCtrl, selectedId = self.selectedIdentifier, observations = self.devices[selectedId] {
            if tableView.isEqual(obsCtrl.tableView) {
                let blePeripheral = observations[indexPath.row]
                cell.textLabel?.text = "\(blePeripheral.timestamp) : \(blePeripheral.RSSI)"
                cell.detailTextLabel?.text = blePeripheral.advertisementData.debugDescription
            } else {
                let identifier = self.identifiers[indexPath.row]
                cell.textLabel?.text = self.identifiers[indexPath.row]
                cell.detailTextLabel?.text = "observations = \(self.devices[identifier]?.count)"
            }
        } else {
            let identifier = self.identifiers[indexPath.row]
            cell.textLabel?.text = self.identifiers[indexPath.row]
            cell.detailTextLabel?.text = "observations = \(self.devices[identifier]?.count)"
        }
        return cell
    }
    
    func connected(peripheral : CBPeripheral) -> Receive {
        return {[unowned self](msg : Message) in
            switch(msg) {
                
                case is BLEPeripheralConnection.DidUpdateValueForCharacteristic:
                     AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                    if let ctrl : UIViewController = self.deviceViewCtrl {
                        let alert = UIAlertController(title: "onClick \(peripheral.name)", message: nil,                         preferredStyle: .Alert)
                        ^{
                        ctrl.presentViewController(alert, animated:true,  completion: nil)
                        }
                        self.scheduleOnce(3, block: {() in
                            ^{
                                alert.dismissViewControllerAnimated(true, completion: nil)
                            }
                        })
                    }
                
                case let m as BLEPeripheralConnection.DidDiscoverCharacteristicsForService:
                    let chars = m.service.characteristics!.filter({ (char) -> Bool in
                        return char.UUID == BLEData().characteristic
                    })
                
                    if let char : CBCharacteristic = chars.first {
                        peripheral.setNotifyValue(true, forCharacteristic: char)
                    }
                
                case let m as BLECentral.Peripheral.OnConnect:
                    if let d = self.deviceViewCtrl {
                        ^{d.stateRow.detailTextLabel?.text = "Connected"}
                    }
                    m.peripheralConnection! ! BLEPeripheralConnection.AddListener(sender : self.this)
                    m.peripheralConnection! ! BLEPeripheralConnection.DiscoverServices(sender: self.this, services: [BLEData().svc])
                
                
                case is RemoveDeviceViewController:
                    ^{ () in
                        self.deviceViewCtrl?.tableView.delegate = nil
                        self.deviceViewCtrl?.tableView.dataSource = nil
                        self.deviceViewCtrl = nil
                    }
                    self.unbecome()                    
                    self.central ! BLECentral.Peripheral.Disconnect(sender : self.this, peripheral : peripheral)
                    
                case let m as BLECentral.Peripheral.OnDisconnect:
                    if let d = self.deviceViewCtrl {
                        ^{d.stateRow.detailTextLabel?.text = "Disconnected"}
                        self.scheduleOnce(1,block: { () in
                           self.central ! BLECentral.Peripheral.Connect(sender: self.this, peripheral : m.peripheral)
                        })
                    }
                
                default:
                    print("ignoring")
            }
        }
    }
    
    override public func receive(msg: Message) {
        switch(msg) {
            
        case let m as BLECentral.StartScanning:
            self.central ! BLECentral.StartScanning(services: m.services, sender: self.this)
            
        case is BLECentral.StopScanning:
            self.central ! BLECentral.StopScanning(sender: this)
            
        case let w as SetObservationsController:
            ^{ () in
                self.observationsCtrl = w.ctrl
                self.observationsCtrl?.tableView.delegate = self
                self.observationsCtrl?.tableView.dataSource = self
                self.observationsCtrl?.title = self.selectedIdentifier
                self.observationsCtrl?.tableView.reloadData()
            }

        case is RemoveObservationController:
            ^{ () in
                self.observationsCtrl?.tableView.delegate = nil
                self.observationsCtrl?.tableView.dataSource = nil
                self.observationsCtrl = Optional.None
                self.selectedIdentifier = Optional.None
            }
            
        case let w as SetDeviceListController:
            ^{ () in
                self.ctrl = w.ctrl
                self.ctrl?.tableView.delegate = self
                self.ctrl?.tableView.dataSource = self
                self.ctrl?.tableView.reloadData()
            }
            
        case let w as SetDeviceViewController:
            ^{ () in
                self.deviceViewCtrl = w.ctrl
                self.deviceViewCtrl?.tableView.delegate = self
                self.deviceViewCtrl?.tableView.dataSource = self
                self.deviceViewCtrl?.tableView.reloadData()
            }
            
            if let selected = self.selectedIdentifier,
                peripherals = self.devices[selected],
                peripheral = peripherals.first {
                    self.central ! BLECentral.Peripheral.Connect(sender: Optional.Some(self.this), peripheral: peripheral.peripheral)
            }
            
        case let m as BLECentral.Peripheral.OnConnect:
            if let d = self.deviceViewCtrl {
                ^{
                    d.stateRow.detailTextLabel?.text = "Connected"
                }
            }
            self.become(self.states.connected, state: self.connected(m.peripheral))
            self.this ! m
            
        case let observation as BLECentral.DevicesObservationUpdate:
            self.devices = observation.devices
            self.identifiers = Array(self.devices.keys)
            let sections = NSIndexSet(index: 0)
            ^{ () in
                self.ctrl?.tableView.reloadSections(sections, withRowAnimation: .None)                
                if let obsCtrl = self.observationsCtrl, _ = self.selectedIdentifier {
                    obsCtrl.tableView.reloadSections(sections, withRowAnimation: .None)
                }
            }
            
        case is Harakiri:
            central ! Harakiri(sender: this)
            super.receive(msg)
            
        default:
            super.receive(msg)
        }
    }
    
}