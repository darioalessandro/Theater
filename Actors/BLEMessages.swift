//
//  BLEMessages.swift
//  Actors
//
//  Created by Dario Lencina on 9/29/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import UIKit
import Theater
import CoreBluetooth

public struct BLEData {
    let svc = CBUUID(string: "71DA3FD1-7E10-41C1-B16F-4430B506CDE7")
    let characteristic = CBUUID(string: "71DA3FD1-7E10-41C1-B16F-4430B506CDE2")
}

public class RemoveObservationController : Actor.Message {
    init () {super.init(sender: Optional.None)}
}

public class SetDeviceListController: Actor.Message {
    
    let ctrl : UITableViewController
    
    init(ctrl : UITableViewController) {
        self.ctrl = ctrl
        super.init(sender : Optional.None)
    }
}

public class SetObservationsController: Actor.Message {
    
    let ctrl : UITableViewController
    
    init(ctrl : UITableViewController) {
        self.ctrl = ctrl
        super.init(sender : Optional.None)
    }
}

public class RemoveDeviceViewController : SetDeviceViewController {}

public class SetDeviceViewController : Actor.Message {
    
    let ctrl : DeviceViewController
    
    init(ctrl : DeviceViewController) {
        self.ctrl = ctrl
        super.init(sender : Optional.None)
    }
}
