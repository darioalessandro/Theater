//
//  DeviceListController.swift
//  Actors
//
//  Created by Dario Lencina on 9/28/15.
//  Copyright © 2015 dario. All rights reserved.
//

import UIKit
import Theater

class DeviceListController: UITableViewController {
    
    let reactive : ActorRef = AppActorSystem.shared.actorOf(BLEControllersActor.self, name: "BLEControllersActor")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reactive ! SetDeviceListController(ctrl: self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        reactive ! BLECentralMsg.StartScanning(services: Optional.None, sender: Optional.None)
    }
    
    deinit {
        reactive ! BLECentralMsg.StopScanning(sender: Optional.None)
        reactive ! Harakiri(sender: Optional.None)
    }
}

class ObservationsViewController : UITableViewController {
    
    let reactive : Optional<ActorRef> = AppActorSystem.shared.selectActor("BLEControllersActor")
    
    internal override func viewDidLoad() {
        super.viewDidLoad()
        reactive! ! SetObservationsController(ctrl: self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        reactive! ! BLECentralMsg.StartScanning(services: Optional.None, sender: Optional.None)
    }
    
    internal override func viewWillDisappear(animated: Bool) {
        if(self.isBeingDismissed() || self.isMovingFromParentViewController()){
            reactive! ! RemoveObservationController()
        }
    }
    
}

class DeviceViewController : UITableViewController {
    
    @IBOutlet weak var stateRow: UITableViewCell!
    let reactive : Optional<ActorRef> = AppActorSystem.shared.selectActor("BLEControllersActor")
    
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
