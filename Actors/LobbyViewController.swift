//
//  LobbyViewController.swift
//  Actors
//
//  Created by Dario on 10/7/15.
//  Copyright © 2015 dario. All rights reserved.
//

import UIKit
import Theater

public class LobbyViewController : UIViewController {

    @IBOutlet weak var remote: UIButton!
    @IBOutlet weak var camera: UIButton!
    
    lazy var remoteCamSession : ActorRef = AppActorSystem.shared.actorOf(RemoteCamSession.self, name: "RemoteCam Session")
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.remoteCamSession ! StartScanning()
    }
    
    deinit {
        
    }

}