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

public class PeripheralMsg {
    public class StartAdvertising : Message {}
    public class StopAdvertising : Message {}
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

public class PeripheralActor : Actor, CBPeripheralManagerDelegate, WithListeners {
    
    public var listeners : [ActorRef] = []
    
    var onClickCharacteristic = CBMutableCharacteristic(type:  BLEData().characteristic, properties: [.Read , .Notify], value: nil, permissions: [.Readable])
    
    var centrals : [CBCentral] = []
    
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
    
    private let peripheral : CBPeripheralManager = CBPeripheralManager()
    
    required public init(context: ActorSystem, ref: ActorRef) {
        super.init(context: context, ref: ref)
        peripheral.delegate = self
    }
    
    override public func preStart() -> Void {
        become(states.idle, state: self.idle)
    }
    
    lazy var idle : Receive = {[unowned self](msg : Message) in
        switch (msg) {
            case is PeripheralMsg.ToggleAdvertising:
                var svc = CBMutableService(type: BLEData().svc, primary: true)
                svc.characteristics = [self.onClickCharacteristic]
                self.peripheral.addService(svc)
                self.peripheral.startAdvertising(self.advertisementData)
                self.addListener(msg.sender)
            default :
                self.receive(msg)
        }
    }
    
    lazy var connected : Receive = {[unowned self](msg : Message) in
        switch (msg) {
        default :
            self.receive(msg)
        }
    }
    
    lazy var advertising : Receive = {[unowned self](msg : Message) in
        switch (msg) {
            case is PeripheralMsg.ToggleAdvertising:
                self.peripheral.stopAdvertising()
                self.peripheral.removeAllServices()
                self.unbecome()
                ^{self.ctrl!.advertisingButton.setTitle("Idle", forState: .Normal)}
            
            case is PeripheralMsg.OnClick:
                 var data = NSDate.init().debugDescription.dataUsingEncoding(NSUTF8StringEncoding)
                self.peripheral.updateValue(data!, forCharacteristic: self.onClickCharacteristic, onSubscribedCentrals: self.centrals)
            
            default :
                self.receive(msg)
        }
    }
    
    public override func receive(msg : Message) -> Void {
        switch(msg) {
            case let v as PeripheralMsg.SetPeripheralViewController:
                self.ctrl = v.ctrl
            default:
                super.receive(msg)
        }
    }
    
    public func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        switch(peripheral.state) {
            case .PoweredOff:
                print("off")
            case .PoweredOn:
                print("on")
            case .Resetting:
                print("resetting")
            default:
                print("ignoring")
        }
        
        
    }
    
    public func peripheralManager(peripheral: CBPeripheralManager, willRestoreState dict: [String : AnyObject]) {
        print("willRestoreState")
    }
    
    public func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        print("central subscribed")
        centrals.append(central)
    }
    
    public func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
        print("removed central")
        if let i = centrals.indexOf(central) {
            centrals.removeAtIndex(i)
        }
    }
    
    public func peripheralManager(peripheral: CBPeripheralManager, didReceiveReadRequest request: CBATTRequest) {
        request.value = self.onClickCharacteristic.value
        self.peripheral.respondToRequest(request, withResult: .Success)
    }
    
    public func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager, error: NSError?) {
        if let ctrl = self.ctrl {
            ^{
                if let error = error {
                    ctrl.advertisingButton.setTitle(error.domain, forState: .Normal)
                    self.popToState(self.states.idle)
                } else {
                    ctrl.advertisingButton.setTitle("Advertising", forState: .Normal)
                    self.become(self.states.advertising, state: self.advertising)
                }
            }
        }
    }
    
    deinit {
        self.peripheral.stopAdvertising()
    }
    
}
