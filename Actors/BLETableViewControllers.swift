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
    
    let reactive : ActorRef = AppActorSystem.shared.actorOf(RDeviceListController)
    
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
            break
            default :
                print("I have nothing to do")
        }
    }
    
    deinit {
        reactive ! StopScanning(sender: Optional.None)
        reactive ! Harakiri(sender: Optional.None)
    }
}

class ObservationsViewController : UITableViewController {
    
}
