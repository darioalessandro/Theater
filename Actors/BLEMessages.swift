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

public class RemoveObservationController : Message {
    init () {super.init(sender: Optional.None)}
}

public class SetTableViewController: Message {
    
    let ctrl : UITableViewController
    
    init(ctrl : UITableViewController) {
        self.ctrl = ctrl
        super.init(sender : Optional.None)
    }
}

public class SetObservationsController: Message {
    
    let ctrl : UITableViewController
    
    init(ctrl : UITableViewController) {
        self.ctrl = ctrl
        super.init(sender : Optional.None)
    }
}

public class RemoveDeviceViewController : SetDeviceViewController {}

public class SetDeviceViewController : Message {
    
    let ctrl : DeviceViewController
    
    init(ctrl : DeviceViewController) {
        self.ctrl = ctrl
        super.init(sender : Optional.None)
    }
}
