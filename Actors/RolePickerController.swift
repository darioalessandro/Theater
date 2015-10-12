//
//  LobbyViewController.swift
//  Actors
//
//  Created by Dario on 10/7/15.
//  Copyright © 2015 dario. All rights reserved.
//

import UIKit
import Theater

public class RolePickerController : UIViewController {

    let showCameraSegue : String = "showCamera"
    
    let showRemoteSegue : String = "showRemote"
    
    let presentPhonePickerSegue : String = "presentPhonePicker"
    
    @IBOutlet weak var remote: UIButton!
    @IBOutlet weak var camera: UIButton!
    
    lazy var remoteCamSession : ActorRef = AppActorSystem.shared.actorOf(RemoteCamSession.self, name: "RemoteCam Session")
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.remoteCamSession ! UICmd.StartScanningWithLobbyViewController(sender : Optional.None, lobby : self)
    }
    
    override public func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if(self.isBeingDismissed() || self.isMovingFromParentViewController()){
            remoteCamSession ! Disconnect(sender:Optional.None)
            remoteCamSession ! Harakiri(sender: Optional.None)
        }
    }
    
    public func showPhonePickerViewController() {
        self.performSegueWithIdentifier(presentPhonePickerSegue, sender: self)
    }
    
    public func showCamera() {
        self.performSegueWithIdentifier(showCameraSegue, sender: self)
    }
    
    public func showRemote() {
        self.performSegueWithIdentifier(showRemoteSegue, sender: self)
    }
    
    @IBAction public func becomeMonitor(button : UIButton) -> Void {
        self.remoteCamSession ! UICmd.BecomeMonitor(sender: Optional.None)
    }
    
    @IBAction public func becomeCamera(button : UIButton) -> Void {
        self.remoteCamSession ! UICmd.BecomeCamera(sender: Optional.None)
    }
    
    
    deinit {
        
    }

}