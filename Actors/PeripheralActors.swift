//
//  PeripheralActor.swift
//  Actors
//
//  Created by Dario Lencina on 10/24/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import Theater
import CoreBluetooth

public extension PeripheralActor {
    public class SetPeripheralViewController : Message {
        public let ctrl : PeripheralViewController
        
        init(sender: Optional<ActorRef>, ctrl : PeripheralViewController) {
            self.ctrl = ctrl
            super.init(sender: sender)
        }
    }
    
    public class OnClick : Message {}
    
    public class ToggleAdvertising : Message {}
}

public class PeripheralActor : Actor, WithListeners {
    
    public var listeners : [ActorRef] = []
    
    var onClickCharacteristic = CBMutableCharacteristic(type:  BLEData().characteristic, properties: [.Read , .Notify], value: nil, permissions: [.Readable])
    
    struct States {
        let idle = "idle"
        let connected = "connected"
        let advertising = "advertising"
    }
    
    weak private var ctrl : PeripheralViewController?
    
    private let states : States = States()
    
    let advertisementData : [String : AnyObject] = [CBAdvertisementDataIsConnectable : true,
                                                    CBAdvertisementDataLocalNameKey : "TheaterDemo",
                                                    CBAdvertisementDataServiceUUIDsKey : [BLEData().svc]]
    
    private let peripheral : ActorRef = AppActorSystem.shared.actorOf(BLEPeripheral.self, name: "BLEPeripheral")
    
    required public init(context: ActorSystem, ref: ActorRef) {
        super.init(context: context, ref: ref)
    }
    
    override public func preStart() -> Void {
        become(states.idle, state: self.idle)
    }
    
    public override func receive(msg : Message) -> Void {
        switch(msg) {
        case let v as SetPeripheralViewController:
            self.ctrl = v.ctrl
        default:
            super.receive(msg)
        }
    }
    
    lazy var idle : Receive = {[unowned self](msg : Message) in
        switch (msg) {
            case is ToggleAdvertising:
                var svc = CBMutableService(type: BLEData().svc, primary: true)
                svc.characteristics = [self.onClickCharacteristic]
                self.peripheral ! BLEPeripheral.AddServices(sender : self.this, svcs:[svc])
                self.peripheral ! BLEPeripheral.StartAdvertising(sender:self.this, advertisementData:self.advertisementData)
                self.addListener(msg.sender)
            
            case is BLEPeripheral.DidStartAdvertising:
                self.become(self.states.advertising, state: self.advertising)
                ^{self.ctrl!.advertisingButton.setTitle("Advertising", forState: .Normal)}
            
            case is BLEPeripheral.DidStopAdvertising:
                self.popToState(self.states.idle)
                ^{self.ctrl!.advertisingButton.setTitle("Idle", forState: .Normal)}
            
            default :
                self.receive(msg)
        }
    }
    
    lazy var advertising : Receive = {[unowned self](msg : Message) in
        switch (msg) {
            case is ToggleAdvertising:
                self.peripheral ! BLEPeripheral.StopAdvertising(sender: self.this)
                self.unbecome()
                ^{self.ctrl!.advertisingButton.setTitle("Idle", forState: .Normal)}
            
            case is OnClick:
                if let data = NSDate.init().debugDescription.dataUsingEncoding(NSUTF8StringEncoding) {
                 self.peripheral ! BLEPeripheral.UpdateCharacteristicValue(sender: self.this, char: self.onClickCharacteristic, centrals: nil, value: data)
                }
            
            case let m as BLEPeripheral.CentralDidSubscribeToCharacteristic:
                self.become(self.states.connected, state: self.connected(m.central))
                ^{if let ctrl = self.ctrl {
                    ctrl.statusCell.detailTextLabel!.text = "connected to \(m.central.identifier.UUIDString)"
                    }}
            
            default :
                self.idle(msg)
        }
    }
    
    func connected(central : CBCentral) -> Receive {
        return {[unowned self](msg : Message) in
            switch(msg) {
                case is OnClick :
                    if let data = NSDate.init().debugDescription.dataUsingEncoding(NSUTF8StringEncoding) {
                        self.peripheral ! BLEPeripheral.UpdateCharacteristicValue(sender: self.this, char: self.onClickCharacteristic, centrals: [central], value: data)
                    }
        
                case let m as BLEPeripheral.DidReceiveReadRequest:
                    m.request.value = self.onClickCharacteristic.value
                    self.peripheral ! BLEPeripheral.RespondToRequest(sender: self.this, request: m.request, result: .Success)
                
                case is BLEPeripheral.CentralDidUnsubscribeFromCharacteristic:
                    self.unbecome()
                    ^{if let ctrl = self.ctrl {
                        ctrl.statusCell.detailTextLabel!.text = "disconnected"
                    }}
                
                default:
                    self.advertising(msg)
            }
        }
    }
    
    deinit {
        self.peripheral ! Harakiri(sender: this)
    }
    
}
