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

public class RDeviceListController : Actor, UITableViewDataSource, UITableViewDelegate {
    
    var devices : [String : [BLEPeripheral]] = [String : [BLEPeripheral]]()
    var identifiers : [String] = [String]()
    weak var ctrl : Optional<UITableViewController> = Optional.None
    weak var observationsCtrl : Optional<UITableViewController> = Optional.None
    var selectedIdentifier : Optional<String> = Optional.None
    let central : ActorRef
    
    required public init(context : ActorSystem, ref : ActorRef) {
        self.central = context.actorOf(BLECentral)
        super.init(context: context, ref: ref)
        self.central ! AddListener(sender: this)
        self.central ! StartScanning()
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
        let cell = tableView.dequeueReusableCellWithIdentifier("device")!
        
        if let obsCtrl = self.observationsCtrl, selectedId = self.selectedIdentifier, observations = self.devices[selectedId] {
            if tableView.isEqual(obsCtrl.tableView) {
                let blePeripheral : BLEPeripheral = observations[indexPath.row]
                cell.textLabel?.text = "\(blePeripheral.timestamp) : \(blePeripheral.RSSI)"
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
    
    override public func receive(msg: Message) {
        switch(msg) {
            
        case is StopScanning:
            self.central ! StopScanning(sender: this)
            break;
            
        case is SetObservationsController:
            let w : SetObservationsController = msg as! SetObservationsController
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                self.observationsCtrl = w.ctrl
                self.observationsCtrl?.tableView.delegate = self
                self.observationsCtrl?.tableView.dataSource = self
                self.observationsCtrl?.title = self.selectedIdentifier
                self.observationsCtrl?.tableView.reloadData()
            })
            break;
        case is RemoveObservationController:
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                self.observationsCtrl?.tableView.delegate = nil
                self.observationsCtrl?.tableView.dataSource = nil
                self.observationsCtrl = Optional.None
                self.selectedIdentifier = Optional.None
            })
            break;
            
        case is SetTableViewController :
            let w : SetTableViewController = msg as! SetTableViewController
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                self.ctrl = w.ctrl
                self.ctrl?.tableView.delegate = self
                self.ctrl?.tableView.dataSource = self
                self.ctrl?.tableView.reloadData()
            })
            break;
            
        case is DevicesObservationUpdate:
            let observation : DevicesObservationUpdate = msg as! DevicesObservationUpdate
            self.devices = observation.devices
            self.identifiers = Array(self.devices.keys)
            let sections = NSIndexSet(index: 0)
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                
                self.ctrl?.tableView.reloadSections(sections, withRowAnimation: .None)
                
                if let obsCtrl = self.observationsCtrl, _ = self.selectedIdentifier {
                    obsCtrl.tableView.reloadSections(sections, withRowAnimation: .None)
                }
            })
            break;
        case is Harakiri:
            central ! Harakiri(sender: this)
            super.receive(msg)
            break;
            
        default:
            super.receive(msg)
        }
    }
}