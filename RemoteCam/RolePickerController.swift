//
//  LobbyViewController.swift
//  Actors
//
//  Created by Dario on 10/7/15.
//  Copyright © 2015 dario. All rights reserved.
//

import UIKit
import Theater

/**
     Role picker allows the user to select whether the current device want's to be the camera or the monitor.
    
    It is important to mention that the session is the actor that coordinates this modes internally.
 
    One neat feature is that if two devices are connected and both are in the RolePickerController, when device1 selects a role, say Camera, RemoteCamSession will inform device2 about the choice, so that it becomes the Monitor.
 
*/

public class RolePickerController : UIViewController {

    let showCameraSegue : String = "showCamera"
    
    let showRemoteSegue : String = "showRemote"
    
    let presentPhonePickerSegue : String = "presentPhonePicker"
    
    public struct States {
        let connect = "Connect"
        let disconnect = "Disconnect"
    }
    
    public let states =  States()
    
    @IBOutlet weak var remote: UIButton!
    @IBOutlet weak var camera: UIButton!
    
    lazy var remoteCamSession : ActorRef = AppActorSystem.shared.actorOf(RemoteCamSession.self, name: "RemoteCam Session")
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: states.connect, style: .Done, target: self, action: "toggleConnect:")
        self.remoteCamSession ! SetViewCtrl(ctrl: self)
        self.remoteCamSession ! UICmd.StartScanning(sender : nil)
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBarHidden = false
        self.verifyCameraAndCameraRollAccess()
    }
    
    override public func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if(self.isBeingDismissed() || self.isMovingFromParentViewController()){
            remoteCamSession ! Disconnect(sender:Optional.None)
            remoteCamSession ! Actor.Harakiri(sender: Optional.None)
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
    
    @IBAction public func becomeMonitor(button : UIButton) {
        self.remoteCamSession ! UICmd.BecomeMonitor(sender: nil)
    }
    
    @IBAction public func becomeCamera(button : UIButton) {
        self.remoteCamSession ! UICmd.BecomeCamera(sender: nil)
    }
        
    @objc public func toggleConnect(button : UIButton) {
        self.remoteCamSession ! UICmd.ToggleConnect(sender : nil)
    }
    
}