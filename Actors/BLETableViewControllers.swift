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
        reactive ! SetTableViewController(ctrl: self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        reactive ! RemoveObservationController()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let ctrl = segue.destinationViewController
        
        switch(ctrl) {
            case is ObservationsViewController:
                reactive ! SetObservationsController(ctrl: ctrl as! UITableViewController)

            default :
                print("I have nothing to do")
        }
    }
    
    deinit {
        reactive ! BLECentralMsg.StopScanning(sender: Optional.None)
        reactive ! Harakiri(sender: Optional.None)
    }
}

class ObservationsViewController : UITableViewController {
    
    let reactive : Optional<ActorRef> = AppActorSystem.shared.selectActor("BLEControllersActor")
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let ctrl = segue.destinationViewController
        
        switch(ctrl) {
        case is DeviceViewController:
            reactive! ! SetDeviceViewController(ctrl: ctrl as! DeviceViewController)
            
        default :
            print("I have nothing to do")
        }
    }
    
}

class DeviceViewController : UITableViewController {
    
    @IBOutlet weak var stateRow: UITableViewCell!
    let reactive : Optional<ActorRef> = AppActorSystem.shared.selectActor("BLEControllersActor")
    
    internal override func viewWillDisappear(animated: Bool) {
        if(self.isBeingDismissed() || self.isMovingFromParentViewController()){
            reactive! ! RemoveDeviceViewController(ctrl : self)
        }
    }
    
}
