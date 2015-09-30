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

class RemoveObservationController : Message {
    init () {super.init(sender: Optional.None)}
}

class SetTableViewController: Message {
    
    let ctrl : UITableViewController
    
    init(ctrl : UITableViewController) {
        self.ctrl = ctrl
        super.init(sender : Optional.None)
    }
}

class SetObservationsController: Message {
    
    let ctrl : UITableViewController
    
    init(ctrl : UITableViewController) {
        self.ctrl = ctrl
        super.init(sender : Optional.None)
    }
}