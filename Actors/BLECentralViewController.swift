//
//  DeviceListController.swift
//  Actors
//
//  Created by Dario Lencina on 9/28/15.
//  Copyright © 2015 dario. All rights reserved.
//

import UIKit
import Theater
import AudioToolbox

class DeviceListController: UITableViewController {
    
    let reactive : ActorRef = RemoteCamSystem.shared.actorOf(BLEControllersActor.self, name: "BLEControllersActor")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reactive ! SetDeviceListController(ctrl: self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        reactive ! BLECentral.StartScanning(services: [BLEData().svc], sender: Optional.None)
    }
    
    deinit {
        reactive ! BLECentral.StopScanning(sender: Optional.None)
        reactive ! Actor.Harakiri(sender: Optional.None)
    }
}

class ObservationsViewController : UITableViewController {
    
    let reactive : Optional<ActorRef> = RemoteCamSystem.shared.selectActor("BLEControllersActor")
    
    internal override func viewDidLoad() {
        super.viewDidLoad()
        reactive! ! SetObservationsController(ctrl: self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        reactive! ! BLECentral.StartScanning(services: [BLEData().svc], sender: Optional.None)
    }
    
    internal override func viewWillDisappear(animated: Bool) {
        if(self.isBeingDismissed() || self.isMovingFromParentViewController()){
            reactive! ! RemoveObservationController()
        }
    }
    
}

class DeviceViewController : UITableViewController {
    
    @IBOutlet weak var stateRow: UITableViewCell!
    let reactive : Optional<ActorRef> = RemoteCamSystem.shared.selectActor("BLEControllersActor")
    
    internal override func viewDidLoad() {
        super.viewDidLoad()
        reactive! ! SetDeviceViewController(ctrl: self)
    }
    
    internal override func viewWillDisappear(animated: Bool) {
        if(self.isBeingDismissed() || self.isMovingFromParentViewController()){
            reactive! ! RemoveDeviceViewController(ctrl : self)
        }
    }
    
}
