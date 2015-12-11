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
    class Timeout : Message {
        let uuid : NSUUID
        
        init(sender: Optional<ActorRef>, uuid : NSUUID) {
            self.uuid = uuid
            super.init(sender:sender)
        }
    }
    
    class Advertise {
        class OneSvc : MessageWithButtonIndex {}
        class TwoSvcs : MessageWithButtonIndex {}
        class ThreeSvcs : MessageWithButtonIndex {}
        
        class MessageWithButtonIndex : Message {
            let idx : NSInteger
            
            init(sender: Optional<ActorRef> , idx : NSInteger) {
                self.idx = idx
                super.init(sender : sender)
            }
        }
    }
    
    struct States {
        let oneSvc = "oneSvc"
        let twoSvcs = "twoSvcs"
        let threeSvcs = "threeSvcs"
        let transitioningToState = "transitioningToState"
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
        ^{ctrl.statusLabel.text = "not advertising"}
        return idle(ctrl)
    }
    
    func idle(ctrl : BLEAdvertiserCtrl) -> Receive {
        return {[unowned self](msg : Message) in
            switch(msg) {
            case let m as Advertise.OneSvc:
                let svcs = self.servicesFromCBUUIDs(self.svcs.oneSvc)

                self.peripheral ! BLEPeripheral.StartAdvertising(sender: self.this, advertisementData:self.advertisementDataWithSvcs(self.svcs.oneSvc), svcs: svcs)
                self.become(self.states.transitioningToState, state: self.transitioningToState(ctrl, wishedServices: svcs, finalStateName: self.states.oneSvc, finalState:{return self.oneSvc(ctrl, selectedSegment: 0)}, sendingTabIndex: m.idx))
                
            case let m as Advertise.TwoSvcs:
                let svcs = self.servicesFromCBUUIDs(self.svcs.twoSvcs)
                self.peripheral ! BLEPeripheral.SetServices(sender: self.this, svcs:svcs)
                //self.peripheral ! BLEPeripheral.StartAdvertising(sender: self.this, advertisementData:self.advertisementDataWithSvcs(self.svcs.twoSvcs))
                let state = self.transitioningToState(ctrl, wishedServices: svcs, finalStateName: self.states.twoSvcs, finalState: {return self.twoSvcs(ctrl, selectedSegment: 1)}, sendingTabIndex: m.idx)
                self.become(self.states.transitioningToState, state: state)
                
            case let m as Advertise.ThreeSvcs:
                let svcs = self.servicesFromCBUUIDs(self.svcs.threeSvcs)

                self.peripheral ! BLEPeripheral.StartAdvertising(sender: self.this, advertisementData:self.advertisementDataWithSvcs(self.svcs.threeSvcs), svcs:svcs)
                self.become(self.states.transitioningToState, state: self.transitioningToState(ctrl, wishedServices: svcs, finalStateName: self.states.threeSvcs, finalState:{ return self.threeSvcs(ctrl, selectedSegment: 2)}, sendingTabIndex: m.idx))
            default:
                self.defaultHandler(ctrl, msg: msg)
            }
        }
    }
    
    var cmdQueue : [Message] = []
    
    func transitioningToState(ctrl: BLEAdvertiserCtrl, wishedServices : [CBMutableService], finalStateName : String, finalState : () -> Receive, sendingTabIndex: NSInteger) -> Receive {
        let timeoutUUID = NSUUID()
        self.scheduleOnce(5) {
            self.this ! Timeout(sender:self.this, uuid:timeoutUUID)
        }
        return {[unowned self](msg : Message) in
            switch(msg) {
            case is Advertise.OneSvc,
                 is Advertise.TwoSvcs,
                 is Advertise.ThreeSvcs:
                ^{
                    ctrl.statusLabel.text = "queuing cmd"
                }
                self.cmdQueue.insert(msg, atIndex: 0)
                
                case let m as BLEPeripheral.DidStartAdvertising:
                    if m.svcs == wishedServices {
                        ^{ctrl.statusLabel.text = "transitioning to state \(finalStateName)"}
                        self.become(finalStateName, state: finalState())
                    } else {
                        ^{  ctrl.currentSegmentedIdx = sendingTabIndex
                            ctrl.statusLabel.text = "epic fail, back to previous state"}
                        self.unbecome()
                    }
                    if let msg = self.cmdQueue.popLast() {self.this ! msg}
                
                case let m as BLEPeripheral.FailedToStartAdvertising:
                    ^{  ctrl.currentSegmentedIdx = sendingTabIndex
                        ctrl.statusLabel.text = "epic fail, back to previous state \(m.error.debugDescription)"}
                    self.unbecome()
                    if let msg = self.cmdQueue.popLast() {self.this ! msg}
                
                case let t as Timeout:
                    if t.uuid == timeoutUUID {
                        ^{  ctrl.currentSegmentedIdx = sendingTabIndex
                            ctrl.statusLabel.text = "timeout, back to previous state "}
                        self.unbecome()
                        if let msg = self.cmdQueue.popLast() {self.this ! msg}
                    }
                
                default:
                    print("not handled, I am busy")
            }
        }
    }
    
    func threeSvcs(ctrl: BLEAdvertiserCtrl, selectedSegment:NSInteger) -> Receive {
        ^{ctrl.currentSegmentedIdx = selectedSegment}
        return {self.idle(ctrl)($0)}
    }
    
    func twoSvcs(ctrl: BLEAdvertiserCtrl, selectedSegment:NSInteger) -> Receive {
        ^{ctrl.currentSegmentedIdx = selectedSegment}
        return {self.idle(ctrl)($0)}
    }
    
    func oneSvc(ctrl: BLEAdvertiserCtrl, selectedSegment:NSInteger) -> Receive {
        ^{ctrl.currentSegmentedIdx = selectedSegment}
        return {self.idle(ctrl)($0)}
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
    
    let bleAdvertiser : ActorRef = RemoteCamSystem.shared.actorOf(BLEAdvertiser.self)
    
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    private var oldSegmentedIdx = 0
    
    var currentSegmentedIdx = 0 {
        didSet {
            self.oldSegmentedIdx = oldValue
            self.segmentedControl.selectedSegmentIndex = self.currentSegmentedIdx
        }
    }
    
    @IBAction func onSegmentedControlClick(sender: UISegmentedControl) {
        
        self.currentSegmentedIdx = sender.selectedSegmentIndex
        
        switch(sender.selectedSegmentIndex) {
            case 0:
                bleAdvertiser ! BLEAdvertiser.Advertise.OneSvc(sender: nil, idx : self.oldSegmentedIdx)
            case 1:
            bleAdvertiser ! BLEAdvertiser.Advertise.TwoSvcs(sender: nil, idx : self.oldSegmentedIdx)
            default:
            bleAdvertiser ! BLEAdvertiser.Advertise.ThreeSvcs(sender: nil, idx : self.oldSegmentedIdx)
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
        bleAdvertiser ! BLEAdvertiser.Advertise.OneSvc(sender: nil, idx : 0)
    }
    
}