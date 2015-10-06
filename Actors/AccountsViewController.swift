//
//  AccountsViewController.swift
//  Actors
//
//  Created by Dario on 10/5/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import Theater

class HookupViewController: Message {
    let ctrl : AccountsViewController
    
    init(ctrl : AccountsViewController) {
        self.ctrl = ctrl
        super.init(sender: Optional.None)
    }
}

public class AccountsViewController : UIViewController {
    
    let  bank : ActorRef = AppActorSystem.shared.actorOf(Bank)
    
    @IBOutlet weak var bToA: UIButton!
    @IBOutlet weak var accountABalance: UILabel!
    @IBOutlet weak var aToB: UIButton!
    @IBOutlet weak var accountBBalance: UILabel!
    
    override public func viewDidLoad() {
        bank ! HookupViewController(ctrl: self)
    }
}
