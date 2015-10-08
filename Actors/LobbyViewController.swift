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

    let showCamera : String = "showCamera"
    
    let showRemote : String = "showRemote"
    
    let presentPhonePicker : String = "presentPhonePicker"
    
    @IBOutlet weak var remote: UIButton!
    @IBOutlet weak var camera: UIButton!
    
    lazy var remoteCamSession : ActorRef = AppActorSystem.shared.actorOf(RemoteCamSession.self, name: "RemoteCam Session")
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.remoteCamSession ! StartScanningWithLobbyViewController(sender : Optional.None, lobby : self)
    }
    
    public func showPhonePickerViewController() {
        self.performSegueWithIdentifier(presentPhonePicker, sender: self)
    }
    
    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch(segue.identifier!) {
            case presentPhonePicker:
                let picker = segue.destinationViewController as! PhonePickerViewController
                
            break
            
            default:
                print("do nothing")
        }
    }
    
    
    deinit {
        self.remoteCamSession ! Harakiri(sender: Optional.None)
    }

}