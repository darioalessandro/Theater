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
    
    public class OnClick : Actor.Message {}
    
    public class ToggleAdvertising : Actor.Message {}
}

public class PeripheralActor : ViewCtrlActor<PeripheralViewController>, WithListeners {
    
    public var listeners : [ActorRef] = []
    
    var onClickCharacteristic = CBMutableCharacteristic(type:  BLEData().characteristic, properties: [.Read , .Notify], value: nil, permissions: [.Readable])
    
    struct States {
        let connected = "connected"
        let advertising = "advertising"
    }
    
    private let states : States = States()
    
    let advertisementData : [String : AnyObject] = [CBAdvertisementDataIsConnectable : true,
                                                    CBAdvertisementDataLocalNameKey : "TheaterDemo",
                                                    CBAdvertisementDataServiceUUIDsKey : [BLEData().svc]]
    
    private let peripheral : ActorRef = AppActorSystem.shared.actorOf(BLEPeripheral.self, name: "BLEPeripheral")
    
    required public init(context: ActorSystem, ref: ActorRef) {
        super.init(context: context, ref: ref)
    }
    
    override public func withCtrl(ctrl : PeripheralViewController) -> Receive {
        return {[unowned self] (msg : Actor.Message) in
            switch (msg) {
                case is ToggleAdvertising:
                    let svc = CBMutableService(type: BLEData().svc, primary: true)
                    svc.characteristics = [self.onClickCharacteristic]
                    self.peripheral ! BLEPeripheral.AddServices(sender : self.this, svcs:[svc])
                    self.peripheral ! BLEPeripheral.StartAdvertising(sender:self.this, advertisementData:self.advertisementData)
                    self.addListener(msg.sender)
                
                case is BLEPeripheral.DidStartAdvertising:
                    self.become(self.states.advertising, state: self.advertising(ctrl))
                    ^{ctrl.advertisingButton.setTitle("Advertising", forState: .Normal)}
                
                case is BLEPeripheral.DidStopAdvertising:
                    ^{ctrl.advertisingButton.setTitle("Idle", forState: .Normal)}
                
                default :
                    self.receive(msg)
            }
        }
    }
    
    func advertising(ctrl : PeripheralViewController) -> Receive {
        return {[unowned self] (msg : Actor.Message) in
            switch (msg) {
                case is ToggleAdvertising:
                    self.peripheral ! BLEPeripheral.StopAdvertising(sender: self.this)
                    self.unbecome()
                    ^{ctrl.advertisingButton.setTitle("Idle", forState: .Normal)}
                
                case is OnClick:
                    if let data = NSDate.init().debugDescription.dataUsingEncoding(NSUTF8StringEncoding) {
                     self.peripheral ! BLEPeripheral.UpdateCharacteristicValue(sender: self.this, char: self.onClickCharacteristic, centrals: nil, value: data)
                    }
                
                case let m as BLEPeripheral.CentralDidSubscribeToCharacteristic:
                    self.become(self.states.connected, state: self.connected(ctrl, central : m.central))
                    ^{
                        ctrl.statusCell.detailTextLabel!.text = "connected to \(m.central.identifier.UUIDString)"
                    }
                
                default :
                    self.withCtrl(ctrl)(msg)
            }
        }
    }
    
    public func connected(ctrl : PeripheralViewController, central : CBCentral) -> Receive {
        return {[unowned self](msg : Actor.Message) in
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
                    ^{
                        ctrl.statusCell.detailTextLabel!.text = "disconnected"
                    }
                
                default:
                    self.advertising(ctrl)(msg)
            }
        }
    }
    
    deinit {
        self.peripheral ! Harakiri(sender: this)
    }
    
}
