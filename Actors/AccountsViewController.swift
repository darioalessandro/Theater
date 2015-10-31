//
//  AccountsViewController.swift
//  Actors
//
//  Created by Dario on 10/5/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import Theater

public class AccountsViewController : UIViewController {
    
    @IBOutlet weak var bToA: UIButton!
    @IBOutlet weak var accountABalance: UILabel!
    @IBOutlet weak var aToB: UIButton!
    @IBOutlet weak var accountBBalance: UILabel!
    
    
    override public func viewDidLoad() {
        AppActorSystem.shared.actorOf(Bank.self, name: "Bank") ! SetViewCtrl(ctrl: self)
    }
}
