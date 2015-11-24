//
//  BLEAdvertiserWithStatesActor.swift
//  Actors
//
//  Created by Dario Lencina on 11/23/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import Theater
import CoreBluetooth

extension BLEAdvertiser {
    class Advertise {
        class OneSvc : Message {}
        class TwoSvcs : Message {}
        class ThreeSvcs : Message {}
    }
    
    struct States {
        let oneSvc = "oneSvc"
        let twoSvcs = "twoSvcs"
        let threeSvcs = "threeSvcs"
    }
    
    struct Services {
        let oneSvc : [CBUUID] = [CBUUID(string: "71DA3FD1-7E10-41C1-B16F-4430B506CDE6")]
        
        let twoSvcs : [CBUUID] = [CBUUID(string: "71DA3FD1-7E10-41C1-B16F-4430B506CDE7"),
                                 CBUUID(string: "71DA3FD1-7E10-41C1-B16F-4430B506CDE8")]
        
        let threeSvcs : [CBUUID] = [CBUUID(string: "71DA3FD1-7E10-41C1-B16F-4430B506CDE9"),
                                   CBUUID(string:  "71DA3FD1-7E10-41C1-B16F-4430B506CDE1"),
                                   CBUUID(string:  "71DA3FD1-7E10-41C1-B16F-4430B506CDE2")]
    }
}

class BLEAdvertiser : ViewCtrlActor<BLEAdvertiserCtrl> {
    
    let svcs = Services()
    
    let states = States()

    lazy var peripheral : ActorRef =  self.context.actorOf(BLEPeripheral.self)
    
    required init(context: ActorSystem, ref: ActorRef) {
        super.init(context: context, ref: ref)
    }
    
    func advertisementDataWithSvcs(svcs : [CBUUID]) -> [String : AnyObject] {
        return [CBAdvertisementDataIsConnectable : true,
                CBAdvertisementDataLocalNameKey : "\(svcs.count)svcs",
                CBAdvertisementDataServiceUUIDsKey : [svcs.first!]]
    }
    
    func servicesFromCBUUIDs(svcs : [CBUUID]) -> [CBMutableService] {
        return svcs.map({ (cbuuid) -> CBMutableService in
            let svc = CBMutableService(type: cbuuid, primary: true)
            svc.characteristics = [CBMutableCharacteristic(type:  CBUUID(NSUUID: NSUUID()), properties: [.Read , .Notify], value: nil, permissions: [.Readable])]
            return svc
        })
    }
    
    override func receiveWithCtrl(ctrl: BLEAdvertiserCtrl) -> Receive {
        return {[unowned self](msg : Message) in
            switch(msg) {
                case is Advertise.OneSvc:
                    self.become(self.states.oneSvc, state: self.oneSvc(ctrl), discardOld: true)
                
                case is Advertise.TwoSvcs:
                    self.become(self.states.twoSvcs, state: self.twoSvcs(ctrl), discardOld: true)
                
                case is Advertise.ThreeSvcs:
                    self.become(self.states.threeSvcs, state: self.threeSvcs(ctrl), discardOld: true)
                default:
                    self.defaultHandler(ctrl, msg: msg)
            }
        }
    }
    
    func threeSvcs(ctrl: BLEAdvertiserCtrl) -> Receive {
        peripheral ! BLEPeripheral.RemoveAllServices(sender:self.this)
        peripheral ! BLEPeripheral.AddServices(sender: self.this, svcs: servicesFromCBUUIDs(self.svcs.threeSvcs))
        peripheral ! BLEPeripheral.StartAdvertising(sender: this, advertisementData:self.advertisementDataWithSvcs(self.svcs.threeSvcs))
        
        return {[unowned self](msg : Message) in
            switch(msg) {
            case is Advertise.OneSvc:
                self.become(self.states.oneSvc, state: self.oneSvc(ctrl), discardOld: true)
                
            case is Advertise.TwoSvcs:
                self.become(self.states.twoSvcs, state: self.twoSvcs(ctrl), discardOld: true)
                
            default:
                self.defaultHandler(ctrl, msg: msg)
            }

        }
    }
    
    func twoSvcs(ctrl: BLEAdvertiserCtrl) -> Receive {
        peripheral ! BLEPeripheral.RemoveAllServices(sender:self.this)
        peripheral ! BLEPeripheral.AddServices(sender: self.this, svcs: servicesFromCBUUIDs(self.svcs.twoSvcs))
        peripheral ! BLEPeripheral.StartAdvertising(sender: this, advertisementData:self.advertisementDataWithSvcs(self.svcs.twoSvcs))
        
        return {[unowned self](msg : Message) in
            switch(msg) {
            case is Advertise.OneSvc:
                self.become(self.states.oneSvc, state: self.oneSvc(ctrl), discardOld: true)
                
            case is Advertise.ThreeSvcs:
                self.become(self.states.threeSvcs, state: self.threeSvcs(ctrl), discardOld: true)
            default:
                self.defaultHandler(ctrl, msg: msg)
            }

        }
    }
    
    func oneSvc(ctrl: BLEAdvertiserCtrl) -> Receive {
        peripheral ! BLEPeripheral.RemoveAllServices(sender:self.this)
        peripheral ! BLEPeripheral.AddServices(sender: self.this, svcs: servicesFromCBUUIDs(self.svcs.oneSvc))
        peripheral ! BLEPeripheral.StartAdvertising(sender: this, advertisementData:self.advertisementDataWithSvcs(self.svcs.oneSvc))
        
        return {[unowned self](msg : Message) in
            switch(msg) {
            case is Advertise.TwoSvcs:
                self.become(self.states.twoSvcs, state: self.twoSvcs(ctrl), discardOld: true)
                
            case is Advertise.ThreeSvcs:
                self.become(self.states.threeSvcs, state: self.threeSvcs(ctrl), discardOld: true)
            default:
                self.defaultHandler(ctrl, msg: msg)
            }
        }
    }
    
    func defaultHandler(ctrl: BLEAdvertiserCtrl, msg: Actor.Message) {
        switch(msg) {
            case is BLEPeripheral.DidStartAdvertising:
                ^{ctrl.statusLabel.text = "DidStartAdvertising"}
            
            case let m as BLEPeripheral.PeripheralManagerDidUpdateState:
                ^{ctrl.statusLabel.text = "changed state \(m.state.rawValue)"}
            
            case let m as BLEPeripheral.FailedToStartAdvertising:
                ^{ctrl.statusLabel.text = m.error.debugDescription}
            default:
                self.receive(msg)
        }
    }
    
    deinit {
        self.peripheral ! Harakiri(sender: this)
    }
}

class BLEAdvertiserCtrl : UIViewController {
    
    let bleAdvertiser : ActorRef = AppActorSystem.shared.actorOf(BLEAdvertiser.self)
    
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBAction func onSegmentedControlClick(sender: UISegmentedControl) {
        switch(sender.selectedSegmentIndex) {
            case 0:
            bleAdvertiser ! BLEAdvertiser.Advertise.OneSvc(sender: nil)
            case 1:
            bleAdvertiser ! BLEAdvertiser.Advertise.TwoSvcs(sender: nil)
            default:
            bleAdvertiser ! BLEAdvertiser.Advertise.ThreeSvcs(sender: nil)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        if(self.isBeingDismissed() || self.isMovingFromParentViewController()){
            bleAdvertiser ! Actor.Harakiri(sender : nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bleAdvertiser ! SetViewCtrl(ctrl: self)
        bleAdvertiser ! BLEAdvertiser.Advertise.OneSvc(sender: nil)
    }
    
}